// Product image backfill tooling (Phase 32 — TopBuy Deals).
//
// Local-only, read-only-against-the-database tooling to prepare a reviewable
// backfill of `public.product_images` for the 39 active products that
// currently have none. This script NEVER uploads to Supabase Storage and
// NEVER writes to the database — it only reads (via a read-only SQL SELECT
// and plain HTTP GETs) and writes local files under tool/output/.
//
// Usage:
//   dart run tool/product_image_backfill.dart fetch-catalog
//   dart run tool/product_image_backfill.dart validate
//   dart run tool/product_image_backfill.dart plan-upload
//   dart run tool/product_image_backfill.dart verify-urls
//   dart run tool/product_image_backfill.dart generate-sql
//   dart run tool/product_image_backfill.dart generate-images
//   dart run tool/product_image_backfill.dart generate-images --slug <product-slug>
//
// Workflow:
//   1. fetch-catalog  — snapshots active products + existing image data to
//                        tool/catalog_snapshot.json (read-only SELECT via the
//                        Supabase CLI against the linked project).
//   2. Drop locally-sourced, properly licensed images into tool/images/,
//      named exactly "<product-slug>.jpg" (e.g. elec-002.jpg) — or run
//      generate-images (below) to auto-generate them instead.
//   2b. generate-images — for every active product with no image, calls the
//                        OpenAI Images API (model in _imageGenModel) with a
//                        product-specific prompt built from the catalog plus
//                        lib/data/data_sources/local/mock_products.dart
//                        (read only — never imported/executed/modified), and
//                        writes tool/images/<slug>.jpg. Every generated file
//                        is immediately re-validated with the same
//                        primitives `validate` uses (real JPEG bytes, EOI
//                        marker, size floor, duplicate-content, DB-URL
//                        collision, protected-object-key guard) before being
//                        kept; a file that fails is deleted, not kept.
//                        Resumable: a slug whose local file already passes
//                        validation is skipped, never regenerated, never
//                        touched. One request at a time, isolated per
//                        product, up to 3 attempts with backoff on 429/5xx.
//                        Reads the API key only from OPENAI_API_KEY at run
//                        time — never hardcoded, written to a file, logged,
//                        or included in tool/output/generation_report.json.
//                        This command never uploads or writes to Supabase.
//                        Pass --slug <product-slug> to generate a single
//                        product's image instead of the full batch. If that
//                        slug does not exist, is not active, or already has
//                        a valid image (in the database or as a valid local
//                        file), the command exits safely with a clear
//                        message and makes zero API calls.
//   3. validate       — scans tool/images/ against the snapshot; reports
//                        missing/unexpected/duplicate/unsupported/corrupt
//                        files, duplicate database URLs, and hard-blocks any
//                        attempt to touch the existing Smart Watch Ultra
//                        object or row. This command is the single source of
//                        truth: every later command consumes its report and
//                        refuses to run if it is missing, stale, or failing.
//   4. plan-upload    — writes an upload manifest plus a NON-EXECUTED shell
//                        plan (tool/output/upload_plan.sh) for a privileged
//                        operator to run by hand with a service-role key.
//                        Uploads use `x-upsert: false`, so no existing object
//                        can ever be replaced. This script never runs it.
//   5. Run that plan yourself with a service-role credential — this script
//      deliberately does not do this step, and RLS is never weakened to let
//      anon/authenticated clients upload.
//   6. verify-urls    — HTTP-checks that uploaded public URLs return 200 with
//                        an image/* content type (existing URLs are
//                        re-checked too; body is always discarded, nothing
//                        is downloaded).
//   7. generate-sql   — emits a draft, NOT EXISTS-guarded INSERT script to
//                        tool/output/product_images_backfill_draft.sql for
//                        every candidate verify-urls confirmed reachable.
//                        This is a draft file for human review, not a
//                        migration — it is never applied automatically, and
//                        it deliberately lives outside supabase/migrations/.
//   8. upload-images  — the one command that can perform a REAL Storage
//                        upload and a REAL public.product_images INSERT.
//                        Defaults to a dry run (read-only checks only); pass
//                        --execute to actually write. Always starts with a
//                        FRESH read-only catalog query (never trusts the
//                        cached tool/catalog_snapshot.json), reads
//                        SUPABASE_SERVICE_ROLE_KEY from the environment only
//                        (accepts both the legacy service_role JWT and the
//                        new sb_secret_* format verbatim; the key is never
//                        printed, logged, or written to any report), uploads
//                        with x-upsert:false so no existing object can ever
//                        be replaced, and skips any product that already has
//                        a product_images row. One product's failure never
//                        stops the rest of the batch. Writes
//                        tool/output/upload_report.json.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _bucketName = 'product-images';
const _imagesDir = 'tool/images';
const _outputDir = 'tool/output';
const _catalogSnapshotPath = 'tool/catalog_snapshot.json';
const _projectRefPath = 'supabase/.temp/project-ref';

const _validationReportPath = '$_outputDir/validation_report.json';
const _urlVerificationReportPath = '$_outputDir/url_verification_report.json';
const _uploadManifestPath = '$_outputDir/upload_manifest.json';
const _uploadPlanPath = '$_outputDir/upload_plan.sh';
const _sqlDraftPath = '$_outputDir/product_images_backfill_draft.sql';
const _uploadReportPath = '$_outputDir/upload_report.json';

/// Report shape version. Bumped when the JSON contract changes so that stale
/// reports from an older tool build are rejected rather than misread.
const _reportSchemaVersion = 2;

/// The existing Smart Watch Ultra Storage object. Must never be replaced.
const _protectedObjectKey = 'product-001.png.png';

/// The only accepted filename extension for new images.
const _requiredExtension = '.jpg';

/// Smallest plausible real JPEG. Anything under this is treated as corrupt.
const _minImageBytes = 1024;

// ---------------------------------------------------------------------------
// generate-images config
// ---------------------------------------------------------------------------

/// Single, easily-changeable model identifier. Swap this constant to change
/// model without touching call sites.
const _imageGenModel = 'gpt-image-2';

const _openAiImagesEndpoint = 'https://api.openai.com/v1/images/generations';
const _imageGenSize = '1024x1024';
const _imageGenQuality = 'high';
const _imageGenBackground = 'opaque';
const _imageGenOutputFormat = 'jpeg';
const _imageGenModeration = 'auto';
const _maxGenerationAttempts = 3;
const _retryBackoffSeconds = [2, 4, 8];

const _generationReportPath = '$_outputDir/generation_report.json';
const _mockProductsPath = 'lib/data/data_sources/local/mock_products.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(64);
  }

  switch (args.first) {
    case 'fetch-catalog':
      await _fetchCatalog();
      break;
    case 'validate':
      await _validate();
      break;
    case 'plan-upload':
      await _planUpload();
      break;
    case 'verify-urls':
      await _verifyUrls();
      break;
    case 'generate-sql':
      await _generateSql();
      break;
    case 'generate-images':
      await _generateImages(slug: _extractSlugArg(args));
      break;
    case 'upload-images':
      await _uploadImages(execute: _extractExecuteFlag(args));
      break;
    default:
      _printUsage();
      exit(64);
  }
}

void _printUsage() {
  stdout.writeln("""
Product image backfill tooling (read-only / local-only; never uploads or
writes to the database).

Usage:
  dart run tool/product_image_backfill.dart fetch-catalog
  dart run tool/product_image_backfill.dart validate
  dart run tool/product_image_backfill.dart plan-upload
  dart run tool/product_image_backfill.dart verify-urls
  dart run tool/product_image_backfill.dart generate-sql
  dart run tool/product_image_backfill.dart generate-images
  dart run tool/product_image_backfill.dart generate-images --slug <product-slug>
  dart run tool/product_image_backfill.dart upload-images
  dart run tool/product_image_backfill.dart upload-images --execute

Options for generate-images:
  --slug <product-slug>  Generate an image for only this one active product,
                          instead of every active product missing an image.
                          If the slug does not exist, is not an active
                          product, or already has a valid image (in the
                          database or as a valid file in tool/images/), the
                          command prints a clear message and exits without
                          making any API calls.

Options for upload-images:
  --execute               Actually upload to Storage and insert
                          product_images rows. Without this flag,
                          upload-images performs read-only checks only
                          (including a fresh catalog query) and reports what
                          WOULD be uploaded/linked — it makes no Storage or
                          database write.
""");
}

/// Parses an optional `--slug <value>` (or `--slug=<value>`) argument for
/// generate-images. Returns null when not provided. Exits with a usage
/// error (never making any API call) if `--slug` is given without a value.
String? _extractSlugArg(List<String> args) {
  for (var i = 1; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--slug') {
      if (i + 1 >= args.length || args[i + 1].trim().isEmpty) {
        stderr.writeln(
          '--slug requires a value, e.g. --slug elec-002',
        );
        exit(64);
      }
      return args[i + 1].trim();
    }
    if (arg.startsWith('--slug=')) {
      final value = arg.substring('--slug='.length).trim();
      if (value.isEmpty) {
        stderr.writeln(
          '--slug requires a value, e.g. --slug=elec-002',
        );
        exit(64);
      }
      return value;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Catalog snapshot
// ---------------------------------------------------------------------------

class ProductRow {
  ProductRow.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      slug = json['slug'] as String,
      name = json['name'] as String,
      category = json['category'] as String,
      imageCount = (json['image_count'] as num).toInt(),
      existingUrls = (json['existing_urls'] as List).cast<String>();

  final String id;
  final String slug;
  final String name;
  final String category;
  final int imageCount;
  final List<String> existingUrls;
}

Future<List<ProductRow>> _loadCatalog() async {
  final file = File(_catalogSnapshotPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'No catalog snapshot found. Run:\n'
      '  dart run tool/product_image_backfill.dart fetch-catalog',
    );
    exit(1);
  }
  final decoded = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return (decoded['products'] as List)
      .map((e) => ProductRow.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<String> _catalogFetchedAt() async {
  final decoded = jsonDecode(
    await File(_catalogSnapshotPath).readAsString(),
  ) as Map<String, dynamic>;
  return decoded['fetched_at'] as String? ?? 'unknown';
}

Future<String> _projectHost() async {
  final refFile = File(_projectRefPath);
  if (!refFile.existsSync()) {
    stderr.writeln(
      'Cannot find $_projectRefPath — is this project linked via `supabase link`?',
    );
    exit(1);
  }
  final ref = (await refFile.readAsString()).trim();
  return '$ref.supabase.co';
}

String _publicUrl(String host, String objectKey) =>
    'https://$host/storage/v1/object/public/$_bucketName/$objectKey';

String _sqlEscape(String s) => s.replaceAll("'", "''");

/// Read-only SELECT only. Never INSERT/UPDATE/DELETE.
const _fetchCatalogSql = """
SELECT p.id, p.slug, p.name, c.key AS category, p.is_active,
       COALESCE(pi.cnt, 0) AS image_count,
       COALESCE(to_jsonb(pi.urls), '[]'::jsonb) AS existing_urls
FROM public.products p
JOIN public.categories c ON c.id = p.category_id
LEFT JOIN (
  SELECT product_id, count(*) AS cnt, array_agg(url ORDER BY sort_order) AS urls
  FROM public.product_images
  GROUP BY product_id
) pi ON pi.product_id = p.id
WHERE p.is_active = true
ORDER BY p.slug;
""";

Future<void> _fetchCatalog() async {
  await Directory(_outputDir).create(recursive: true);
  final tmp = File('$_outputDir/.tmp_fetch_catalog.sql');
  await tmp.writeAsString(_fetchCatalogSql);

  stdout.writeln(
    'Running a read-only SELECT against the linked Supabase project...',
  );
  final result = await Process.run('npx', [
    'supabase',
    'db',
    'query',
    '--linked',
    '--file',
    tmp.path,
  ], runInShell: true);

  if (await tmp.exists()) await tmp.delete();

  if (result.exitCode != 0) {
    stderr.writeln('fetch-catalog failed:\n${result.stderr}');
    exit(1);
  }

  final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
  final rows = decoded['rows'] as List<dynamic>;

  final snapshot = {
    'fetched_at': DateTime.now().toUtc().toIso8601String(),
    'source': 'supabase db query --linked (read-only SELECT, no writes)',
    'products': rows,
  };

  await File(_catalogSnapshotPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot));

  stdout.writeln(
    'Wrote $_catalogSnapshotPath (${rows.length} active products).',
  );
}

// ---------------------------------------------------------------------------
// Image format sniffing
// ---------------------------------------------------------------------------

/// Identifies a byte payload by magic number, independent of its filename.
/// Returns a short format label; 'unknown' when nothing matches.
String _sniffFormat(Uint8List bytes) {
  bool startsWith(List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  const pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (startsWith([0xFF, 0xD8, 0xFF])) return 'jpeg';
  if (startsWith(pngMagic)) return 'png';
  if (startsWith([0x47, 0x49, 0x46, 0x38])) return 'gif';
  if (startsWith([0x42, 0x4D])) return 'bmp';
  if (bytes.length >= 12 &&
      startsWith([0x52, 0x49, 0x46, 0x46]) &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'webp';
  }
  if (startsWith([0x3C])) return 'text-or-markup';
  return 'unknown';
}

/// A JPEG must end with the End Of Image marker (FF D9). A truncated download
/// is the most common way a "valid-looking" file is actually broken.
bool _hasJpegEoi(Uint8List bytes) =>
    bytes.length >= 2 &&
    bytes[bytes.length - 2] == 0xFF &&
    bytes[bytes.length - 1] == 0xD9;

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// validate
// ---------------------------------------------------------------------------

class _Candidate {
  _Candidate({
    required this.slug,
    required this.productId,
    required this.productName,
    required this.filePath,
    required this.objectKey,
    required this.publicUrl,
    required this.bytes,
  });

  final String slug;
  final String productId;
  final String productName;
  final String filePath;
  final String objectKey;
  final String publicUrl;
  final int bytes;

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'product_id': productId,
    'product_name': productName,
    'local_file': filePath,
    'object_key': objectKey,
    'public_url': publicUrl,
    'bytes': bytes,
  };
}

Future<void> _validate() async {
  final products = await _loadCatalog();
  final bySlug = {for (final p in products) p.slug: p};
  final host = await _projectHost();

  final dir = Directory(_imagesDir);
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
    stdout.writeln(
      'Created empty $_imagesDir/ — drop <product-slug>.jpg files there '
      '(e.g. elec-002.jpg), then re-run validate.',
    );
  }

  final files = dir.existsSync()
      ? (dir.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  final candidates = <String, _Candidate>{};
  final blocked = <String>[];
  final unexpectedFilenames = <String>[];
  final unsupportedExtension = <String>[];
  final contentMismatch = <String>[];
  final alreadyHasImage = <String>[];
  final duplicateContent = <String>[];
  final urlCollisionWithExisting = <String>[];
  final caseInsensitiveSeen = <String, String>{};
  final contentByName = <String, Uint8List>{};

  // Every URL already present in the database, mapped to the slugs using it.
  final dbUrlOwners = <String, List<String>>{};
  for (final p in products) {
    for (final url in p.existingUrls) {
      dbUrlOwners.putIfAbsent(url, () => <String>[]).add(p.slug);
    }
  }
  final duplicateDbUrls = <String>[];
  for (final entry in dbUrlOwners.entries) {
    if (entry.value.length < 2) continue;
    final owners = entry.value.toList()..sort();
    duplicateDbUrls.add(
      '${entry.key} — referenced by ${owners.length} products: '
      '${owners.join(", ")}',
    );
  }
  duplicateDbUrls.sort();

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (name == '.gitkeep') continue;
    final lower = name.toLowerCase();

    final priorName = caseInsensitiveSeen[lower];
    if (priorName != null && priorName != name) {
      blocked.add(
        '$name — duplicate of $priorName (case-insensitive filename collision)',
      );
      continue;
    }
    caseInsensitiveSeen[lower] = name;

    if (name == _protectedObjectKey) {
      blocked.add(
        '$name — this is the existing Smart Watch Ultra Storage object; '
        'it must never be replaced.',
      );
      continue;
    }

    if (!name.endsWith(_requiredExtension)) {
      unsupportedExtension.add(
        '$name — only "$_requiredExtension" is accepted '
        '(convention: <product-slug>$_requiredExtension)',
      );
      continue;
    }

    final slug = name.substring(0, name.length - _requiredExtension.length);
    final product = bySlug[slug];
    if (product == null) {
      unexpectedFilenames.add(
        '$name — "$slug" does not match any active product slug',
      );
      continue;
    }

    if (product.imageCount > 0) {
      alreadyHasImage.add(
        '$name (${product.name}, slug=$slug already has '
        '${product.imageCount} image(s)) — will not be included',
      );
      continue;
    }

    // Content checks: the extension is a claim, the bytes are the evidence.
    final bytes = await file.readAsBytes();
    if (bytes.length < _minImageBytes) {
      contentMismatch.add(
        '$name — only ${bytes.length} byte(s); below the '
        '$_minImageBytes-byte floor for a real image (empty or truncated?)',
      );
      continue;
    }
    final format = _sniffFormat(bytes);
    if (format != 'jpeg') {
      contentMismatch.add(
        '$name — extension claims JPEG but the bytes are "$format"; '
        'convert it to a real JPEG rather than renaming it',
      );
      continue;
    }
    if (!_hasJpegEoi(bytes)) {
      contentMismatch.add(
        '$name — JPEG header is valid but the End Of Image marker (FF D9) '
        'is missing; the file looks truncated',
      );
      continue;
    }

    // Exact duplicate image content across two different slugs is almost
    // always a copy/paste mistake, so surface it rather than uploading twice.
    String? duplicateOf;
    for (final entry in contentByName.entries) {
      if (_bytesEqual(entry.value, bytes)) {
        duplicateOf = entry.key;
        break;
      }
    }
    if (duplicateOf != null) {
      duplicateContent.add(
        '$name — byte-for-byte identical to $duplicateOf; '
        'each product needs its own image',
      );
      continue;
    }
    contentByName[name] = bytes;

    final publicUrl = _publicUrl(host, name);
    final owners = dbUrlOwners[publicUrl];
    if (owners != null) {
      urlCollisionWithExisting.add(
        '$name — target URL is already stored in the database for: '
        '${owners.join(", ")}',
      );
      continue;
    }

    candidates[slug] = _Candidate(
      slug: slug,
      productId: product.id,
      productName: product.name,
      filePath: file.path.split(Platform.pathSeparator).join('/'),
      objectKey: name,
      publicUrl: publicUrl,
      bytes: bytes.length,
    );
  }

  final stillMissing =
      products
          .where((p) => p.imageCount == 0 && !candidates.containsKey(p.slug))
          .map((p) => p.slug)
          .toList()
        ..sort();

  final problemCount =
      blocked.length +
      unexpectedFilenames.length +
      unsupportedExtension.length +
      contentMismatch.length +
      duplicateContent.length +
      urlCollisionWithExisting.length +
      duplicateDbUrls.length;

  final sortedSlugs = candidates.keys.toList()..sort();

  final report = {
    'schema_version': _reportSchemaVersion,
    'validated_at': DateTime.now().toUtc().toIso8601String(),
    'catalog_fetched_at': await _catalogFetchedAt(),
    'bucket': _bucketName,
    'protected_object_key': _protectedObjectKey,
    'catalog_products': products.length,
    'candidates': [for (final s in sortedSlugs) candidates[s]!.toJson()],
    'still_missing_no_file': stillMissing,
    'blocked': blocked,
    'unexpected_filenames': unexpectedFilenames,
    'unsupported_extension': unsupportedExtension,
    'content_mismatch': contentMismatch,
    'duplicate_content': duplicateContent,
    'already_has_image_skip': alreadyHasImage,
    'duplicate_db_urls': duplicateDbUrls,
    'url_collision_with_existing': urlCollisionWithExisting,
    'problem_count': problemCount,
    // `already_has_image_skip` and `still_missing_no_file` are informational:
    // they describe an incomplete backfill, not a broken one.
    'ok_to_proceed': problemCount == 0,
  };

  await Directory(_outputDir).create(recursive: true);
  await File(_validationReportPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(report));

  void line(String label, int count) =>
      stdout.writeln('  ${count.toString().padLeft(3)}  $label');

  stdout
    ..writeln('--- Validation report ---')
    ..writeln('Catalog products: ${products.length}');
  line('candidates ready for upload+insert', candidates.length);
  line('still missing (no local file yet)', stillMissing.length);
  line('BLOCKED (protected object / filename collision)', blocked.length);
  line('unexpected filenames (no matching slug)', unexpectedFilenames.length);
  line('unsupported extension', unsupportedExtension.length);
  line('content mismatch (not a valid JPEG)', contentMismatch.length);
  line('duplicate image content', duplicateContent.length);
  line('skipped (product already has an image)', alreadyHasImage.length);
  line('duplicate URLs already in the database', duplicateDbUrls.length);
  line(
    'target URL collides with an existing row',
    urlCollisionWithExisting.length,
  );
  stdout
    ..writeln('')
    ..writeln(
      report['ok_to_proceed'] == true
          ? 'ok_to_proceed: true — no problems detected.'
          : 'ok_to_proceed: FALSE — $problemCount problem(s) must be resolved '
                'before plan-upload or generate-sql will run.',
    )
    ..writeln('Full detail written to $_validationReportPath');
}

// ---------------------------------------------------------------------------
// Shared: consuming the validation report
// ---------------------------------------------------------------------------

/// Loads the validation report, refusing stale or failing ones. `validate` is
/// the single source of truth — no later command re-derives candidates from
/// the filesystem, so nothing it rejected can slip through.
Future<Map<String, dynamic>> _requireValidationReport({
  required bool requireOk,
}) async {
  final file = File(_validationReportPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'No validation report found. Run:\n'
      '  dart run tool/product_image_backfill.dart validate',
    );
    exit(1);
  }
  final report = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

  if (report['schema_version'] != _reportSchemaVersion) {
    stderr.writeln(
      'Validation report was written by a different tool version '
      '(schema_version=${report['schema_version']}, expected '
      '$_reportSchemaVersion). Re-run validate.',
    );
    exit(1);
  }

  final snapshotFetchedAt = await _catalogFetchedAt();
  if (report['catalog_fetched_at'] != snapshotFetchedAt) {
    stderr.writeln(
      'Validation report is stale: it was built against a catalog snapshot '
      'from ${report['catalog_fetched_at']}, but the current snapshot is from '
      '$snapshotFetchedAt. Re-run validate.',
    );
    exit(1);
  }

  if (requireOk && report['ok_to_proceed'] != true) {
    stderr.writeln(
      'Validation reported ${report['problem_count']} unresolved problem(s). '
      'Fix them and re-run validate before continuing.\n'
      'See $_validationReportPath',
    );
    exit(1);
  }

  return report;
}

List<Map<String, dynamic>> _candidatesOf(Map<String, dynamic> report) =>
    (report['candidates'] as List).cast<Map<String, dynamic>>();

// ---------------------------------------------------------------------------
// plan-upload
// ---------------------------------------------------------------------------

Future<void> _planUpload() async {
  final report = await _requireValidationReport(requireOk: true);
  final candidates = _candidatesOf(report);

  final manifest = {
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'bucket': _bucketName,
    'protected_object_key': _protectedObjectKey,
    'upsert': false,
    'note':
        'Prepared for privileged (service-role) execution by a human. '
        'This tool never uploads. Uploads are sent with x-upsert:false, so an '
        'existing object — including $_protectedObjectKey — can never be '
        'overwritten by this plan.',
    'operations': [
      for (final c in candidates)
        {
          'slug': c['slug'],
          'local_file': c['local_file'],
          'object_key': c['object_key'],
          'content_type': 'image/jpeg',
          'public_url': c['public_url'],
          'bytes': c['bytes'],
        },
    ],
  };

  await Directory(_outputDir).create(recursive: true);
  await File(_uploadManifestPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));

  final sh = StringBuffer()
    ..writeln('#!/usr/bin/env bash')
    ..writeln('# GENERATED PLAN — NOT RUN BY THE TOOLING THAT WROTE IT.')
    ..writeln('# Generated: ${manifest['generated_at']}')
    ..writeln('#')
    ..writeln('# Review every line before executing. Requires a privileged')
    ..writeln('# service-role key; RLS is never weakened to allow anon or')
    ..writeln('# authenticated uploads.')
    ..writeln('#')
    ..writeln('#   export SUPABASE_SERVICE_ROLE_KEY=...')
    ..writeln('#   bash $_uploadPlanPath')
    ..writeln('#')
    ..writeln('# x-upsert:false means an existing object is never replaced —')
    ..writeln('# $_protectedObjectKey is structurally safe here.')
    ..writeln('set -euo pipefail')
    ..writeln('')
    ..writeln('if [ -z "\${SUPABASE_SERVICE_ROLE_KEY:-}" ]; then')
    ..writeln('  echo "SUPABASE_SERVICE_ROLE_KEY is not set; refusing." >&2')
    ..writeln('  exit 1')
    ..writeln('fi')
    ..writeln('')
    ..writeln('PROTECTED="$_protectedObjectKey"')
    ..writeln('');

  if (candidates.isEmpty) {
    sh.writeln('echo "No validated candidates. Nothing to upload."');
  }

  // A trailing backslash continues a shell line; kept in a raw string so the
  // generated plan stays readable rather than one enormous curl invocation.
  const cont = r' \';

  for (final c in candidates) {
    final objectKey = c['object_key'] as String;
    final localFile = c['local_file'] as String;
    final uploadUrl = (c['public_url'] as String).replaceFirst(
      '/object/public/',
      '/object/',
    );
    sh
      ..writeln('# ${c['slug']} - ${c['product_name']} (${c['bytes']} bytes)')
      ..writeln('if [ "$objectKey" = "\$PROTECTED" ]; then')
      ..writeln('  echo "Refusing to touch protected object \$PROTECTED" >&2')
      ..writeln('  exit 1')
      ..writeln('fi')
      ..writeln('curl --fail --silent --show-error$cont')
      ..writeln('  -X POST "$uploadUrl"$cont')
      ..writeln(
        '  -H "Authorization: Bearer \${SUPABASE_SERVICE_ROLE_KEY}"$cont',
      )
      ..writeln('  -H "Content-Type: image/jpeg"$cont')
      ..writeln('  -H "x-upsert: false"$cont')
      ..writeln('  --data-binary "@$localFile"')
      ..writeln('echo "  uploaded $objectKey"')
      ..writeln('');
  }

  await File(_uploadPlanPath).writeAsString(sh.toString());

  stdout
    ..writeln('--- Upload plan ---')
    ..writeln('Operations prepared: ${candidates.length}')
    ..writeln('Manifest: $_uploadManifestPath')
    ..writeln('Plan:     $_uploadPlanPath')
    ..writeln(
      'NOT executed. Run it yourself with a service-role key when approved.',
    );
}

// ---------------------------------------------------------------------------
// verify-urls
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> _checkUrl(
  HttpClient client,
  String label,
  String url,
) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    await response.drain<void>(); // Body is always discarded; nothing is saved.
    final contentType = response.headers.contentType?.mimeType ?? 'unknown';
    return {
      'label': label,
      'url': url,
      'http_status': response.statusCode,
      'content_type': contentType,
      'ok': response.statusCode == 200 && contentType.startsWith('image/'),
    };
  } catch (e) {
    return {'label': label, 'url': url, 'error': e.toString(), 'ok': false};
  }
}

Future<void> _verifyUrls() async {
  // Candidates come from the report, but existing URLs are re-checked from the
  // snapshot even when validation is failing — confirming the Smart Watch Ultra
  // URL is still healthy must never be blocked by an unrelated bad file.
  final report = await _requireValidationReport(requireOk: false);
  final products = await _loadCatalog();
  final client = HttpClient();
  final results = <Map<String, dynamic>>[];

  for (final p in products) {
    for (final url in p.existingUrls) {
      results.add(await _checkUrl(client, '${p.slug} (existing)', url));
    }
  }

  if (report['ok_to_proceed'] == true) {
    for (final c in _candidatesOf(report)) {
      results.add(
        await _checkUrl(
          client,
          '${c['slug']} (candidate, pending upload)',
          c['public_url'] as String,
        ),
      );
    }
  } else {
    stdout.writeln(
      'Validation is failing (${report['problem_count']} problem(s)); '
      'candidate URLs were not checked. Existing URLs were still verified.',
    );
  }

  client.close(force: true);

  await Directory(_outputDir).create(recursive: true);
  await File(_urlVerificationReportPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(results));

  final ok = results.where((r) => r['ok'] == true).length;
  stdout
    ..writeln('--- URL verification ---')
    ..writeln(
      'Checked ${results.length} URL(s); $ok reachable with an image type.',
    )
    ..writeln('Full detail written to $_urlVerificationReportPath');
}

// ---------------------------------------------------------------------------
// generate-sql
// ---------------------------------------------------------------------------

Future<void> _generateSql() async {
  final report = await _requireValidationReport(requireOk: true);
  final candidates = _candidatesOf(report);

  final verificationFile = File(_urlVerificationReportPath);
  final verifiedOk = <String, bool>{};
  if (verificationFile.existsSync()) {
    final list =
        jsonDecode(await verificationFile.readAsString()) as List<dynamic>;
    for (final entry in list) {
      final map = entry as Map<String, dynamic>;
      final url = map['url'] as String?;
      if (url != null) verifiedOk[url] = map['ok'] == true;
    }
  }

  final buffer = StringBuffer()
    ..writeln('-- DRAFT ONLY — generated by tool/product_image_backfill.dart')
    ..writeln('-- This is NOT a migration. Do not apply directly.')
    ..writeln('-- Review, then hand-copy approved statements into a reviewed')
    ..writeln('-- supabase/migrations/004_*.sql file before ever running it.')
    ..writeln('-- Generated: ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln('--')
    ..writeln('-- Every statement is NOT EXISTS-guarded, so re-running is a')
    ..writeln('-- no-op. public.product_images has no unique constraint on')
    ..writeln('-- (product_id, url), so that guard is the only thing keeping')
    ..writeln('-- a second run from duplicating rows — do not remove it.')
    ..writeln();

  var emitted = 0;
  var skippedUnverified = 0;

  for (final c in candidates) {
    final slug = c['slug'] as String;
    final url = c['public_url'] as String;

    if (verifiedOk[url] != true) {
      buffer.writeln(
        '-- SKIPPED (not yet verified reachable as an image): $slug -> $url',
      );
      skippedUnverified++;
      continue;
    }

    final safeSlug = _sqlEscape(slug);
    final safeUrl = _sqlEscape(url);
    buffer
      ..writeln('-- ${c['product_name']} ($slug)')
      ..writeln(
        'INSERT INTO public.product_images (product_id, url, sort_order)',
      )
      ..writeln("SELECT p.id, '$safeUrl', 0")
      ..writeln('FROM public.products p')
      ..writeln("WHERE p.slug = '$safeSlug'")
      ..writeln('  AND NOT EXISTS (')
      ..writeln('      SELECT 1 FROM public.product_images pi')
      ..writeln("      WHERE pi.product_id = p.id AND pi.url = '$safeUrl'")
      ..writeln('  );')
      ..writeln();
    emitted++;
  }

  if (emitted == 0) {
    buffer.writeln(
      '-- No verified candidates yet. Upload images, run verify-urls, '
      'then re-run generate-sql.',
    );
  }

  await Directory(_outputDir).create(recursive: true);
  await File(_sqlDraftPath).writeAsString(buffer.toString());

  stdout
    ..writeln('--- SQL draft generation ---')
    ..writeln('Statements emitted: $emitted')
    ..writeln('Skipped (unverified): $skippedUnverified')
    ..writeln(
      'Draft written to $_sqlDraftPath (NOT a migration; review required).',
    );
}

// ---------------------------------------------------------------------------
// generate-images
// ---------------------------------------------------------------------------
//
// Local-only. For every active product with no product_images row, generates
// one image via the OpenAI Images API and writes tool/images/<slug>.jpg. This
// command never touches Supabase Storage or the database — it only reads the
// local catalog snapshot (already fetched by fetch-catalog) and writes local
// files under tool/images/ and tool/output/generation_report.json.

/// A structural JPEG problem, or null if the bytes pass. Reuses the exact
/// same byte-level primitives `validate` uses (`_sniffFormat`, `_hasJpegEoi`,
/// `_minImageBytes`) so a generated file is held to the same bar as a
/// human-sourced one — never trusted on filename/extension alone.
String? _basicImageProblem(Uint8List bytes) {
  if (bytes.length < _minImageBytes) {
    return 'only ${bytes.length} byte(s); below the $_minImageBytes-byte '
        'floor for a real image (empty or truncated response?)';
  }
  final format = _sniffFormat(bytes);
  if (format != 'jpeg') {
    return 'response bytes are "$format", not a real JPEG '
        '(never trust the requested output_format on its own)';
  }
  if (!_hasJpegEoi(bytes)) {
    return 'JPEG header is valid but the End Of Image marker (FF D9) is '
        'missing; the response looks truncated';
  }
  return null;
}

/// Product characteristics pulled from mock_products.dart for prompt
/// enrichment. Every field is optional — a product missing from that file,
/// or a field missing from a product's block, just yields nulls/empty.
class _Enrichment {
  _Enrichment({this.description, this.brand, this.features = const []});

  final String? description;
  final String? brand;
  final List<String> features;
}

/// Reads lib/data/data_sources/local/mock_products.dart as plain text (never
/// imported or executed — this tool has no Flutter dependency and adds none)
/// and regex-extracts description/brand/features per product slug, purely to
/// enrich generation prompts. That file is never modified. Defensive by
/// design: any parse failure, or the file being absent, yields an empty map
/// so prompt-building always degrades gracefully to catalog-only data
/// (name + category) rather than failing the batch.
Future<Map<String, _Enrichment>> _loadMockEnrichment() async {
  try {
    final file = File(_mockProductsPath);
    if (!file.existsSync()) return {};
    final text = await file.readAsString();

    final result = <String, _Enrichment>{};
    final idPattern = RegExp(r"id:\s*'([a-zA-Z0-9_-]+)'");
    final idMatches = idPattern.allMatches(text).toList();

    for (var i = 0; i < idMatches.length; i++) {
      final slug = idMatches[i].group(1)!;
      final blockStart = idMatches[i].end;
      final blockEnd = i + 1 < idMatches.length
          ? idMatches[i + 1].start
          : text.length;
      final block = text.substring(blockStart, blockEnd);

      final descMatch = RegExp(
        r"description:\s*'((?:[^'\\]|\\.)*)'",
      ).firstMatch(block);
      final brandMatch = RegExp(
        r"brand:\s*'((?:[^'\\]|\\.)*)'",
      ).firstMatch(block);

      final features = <String>[];
      final featuresBlock = RegExp(
        r'features:\s*\[([\s\S]*?)\]',
      ).firstMatch(block);
      if (featuresBlock != null) {
        for (final m in RegExp(
          r"'((?:[^'\\]|\\.)*)'",
        ).allMatches(featuresBlock.group(1)!)) {
          features.add(m.group(1)!);
        }
      }

      result[slug] = _Enrichment(
        description: descMatch?.group(1),
        brand: brandMatch?.group(1),
        features: features,
      );
    }
    return result;
  } catch (_) {
    // Enrichment is a nice-to-have; never let a parse issue break the batch.
    return {};
  }
}

/// Composition override for products that must not be photographed as a
/// single centered item — e.g. a product naturally sold as a pair/set. Keyed
/// by slug; any slug not listed here keeps the default single-product
/// composition instruction unchanged.
const Map<String, String> _compositionOverrides = {
  'cloth-007':
      'Show exactly two complete sneakers forming one matching pair, both '
      'shoes fully visible from heel to toe, arranged side-by-side with one '
      'shoe slightly offset behind the other, clearly recognizable as a '
      'pair, neither shoe hidden, cropped, or merged with the other,',
  'elec-002':
      'Show exactly three separate, clearly distinguishable objects with '
      'visible empty space between them: on the left, one complete wireless '
      'earbud fully outside and separate from the case, in the center, the '
      'second matching complete wireless earbud fully outside and separate '
      'from the case and from the other earbud, and on the right, the '
      'complete charging case by itself; both earbuds must be entirely '
      'outside the case (never seated or nested inside it), each earbud '
      'showing its stem or touch surface and its speaker mesh/nozzle '
      'clearly, the case showing a believable hinge and lid, none of the '
      'three objects hidden, cropped, duplicated, merged, or touching,',
  'elec-003':
      'Show exactly one complete laptop, the entire laptop fully visible '
      'within the frame and not cropped, the laptop open with the screen '
      'and keyboard forming an angle of approximately 100 to 110 degrees, '
      'the screen facing directly toward the viewer and the keyboard fully '
      'visible and facing up, a realistic thin professional laptop design, '
      'the screen displaying no text, no logos, no icons, and no visible '
      'content (a blank or dark screen), no external monitor, no mouse, no '
      'charger or cables, and no other accessories present,',
  'elec-004':
      'Show exactly one complete smartphone, no duplicate phone, no second '
      'device, and no reflection creating the appearance of a second phone, '
      'the entire phone fully visible within the frame and not cropped, '
      'held upright in portrait orientation with a slight natural '
      'premium-product tilt, the front of the phone facing directly toward '
      'the viewer with the entire display clearly visible, the screen off '
      'showing a plain dark blank display with no app icons, no clock, no '
      'status bar, no notifications, no wallpaper, and no text or logos, a '
      'realistic thin premium modern smartphone design with a clearly '
      'visible modern camera cutout or notch appropriate for a flagship '
      'phone, no charging cable, no charger brick, no earbuds or '
      'earphones, no phone case, no stand, and no other accessories '
      'present,',
  'elec-005':
      'Show exactly one complete tablet, no duplicate tablet, no second '
      'device, and no reflection creating the appearance of a second '
      'tablet, the entire tablet fully visible within the frame and not '
      'cropped, held upright in portrait orientation with a slight natural '
      'premium-product tilt, the front of the tablet facing directly '
      'toward the viewer with the entire display clearly visible, the '
      'screen off showing a plain dark blank display with no app icons, no '
      'clock, no status bar, no notifications, no wallpaper, and no text '
      'or logos, a realistic thin premium modern tablet design with a '
      'visible front camera cutout appropriate for a modern tablet, no '
      'stylus or pen, no keyboard folio or case, no stand, no charging '
      'cable, no charger brick, and no other accessories present,',
  'elec-006':
      'Show exactly two separate objects together in one frame: one '
      'complete wireless keyboard and one complete wireless mouse, never '
      'only one of the two devices, exactly one keyboard and exactly one '
      'mouse, both devices fully visible within the frame and not cropped, '
      'both clearly distinguishable from each other, the devices must not '
      'overlap, touch, merge, or be duplicated, arranged in a natural '
      'premium product-bundle layout with the keyboard larger and '
      'positioned behind or to one side and the mouse smaller and '
      'positioned beside or in front of the keyboard, a realistic '
      'proportional size relationship between the keyboard and the mouse, '
      'the keyboard looking complete and functional with normal standard '
      'keycap legends (letters, numbers, and symbols are allowed as '
      'functional keyboard markings), no decorative text or branding and '
      'no brand logo on either device, no USB wireless receiver or '
      'dongle, no charging cable, no loose batteries, no battery package, '
      'no mouse pad, and no other accessories present,',
  'elec-007':
      'Show exactly one complete 4K action camera, no duplicate camera, no '
      'second device, and no reflection creating the appearance of a '
      'second camera, the entire camera fully visible within the frame '
      'and not cropped, the bare camera body only — do not place the '
      'camera inside an external waterproof housing or case, a realistic '
      'compact rugged action-camera design with a matte/rubberized '
      'textured body, shown from a premium professional 3/4 product '
      'angle with the lens clearly visible as the primary focal point '
      'and the rear touchscreen also partially visible, the touchscreen '
      'off showing a plain dark blank display with no UI, no icons, no '
      'notifications, no text, and no logos on the screen, no '
      'quick-release mount, no adhesive mount, no selfie stick or pole, '
      'no tripod, no memory or SD card, no carrying case or pouch, no '
      'cables, and no other accessories present,',
  'elec-008':
      'Show exactly one complete portable Bluetooth speaker, never a '
      'second speaker or a paired speaker, no duplicate device, the '
      'entire speaker fully visible within the frame with comfortable '
      'margins and not cropped, in an upright natural standing '
      'orientation, shown from a clean professional catalog-friendly 3/4 '
      'product angle, a realistic compact cylindrical portable-speaker '
      'form factor, the front or outer grille clearly visible with a '
      'realistic perforated mesh/fabric texture, top-mounted control '
      'buttons visible in their normal resting and unpressed state, all '
      'LED or status indicators off with no glowing or illuminated '
      'elements, the charging port may be partially visible only if '
      'naturally exposed and if visible it must look closed, sealed, and '
      'realistic, only parts structurally integrated into the speaker '
      'body may appear with no loose or detached strap or accessory, no '
      'charging cable, no charger brick, no AUX cable, no carrying '
      'pouch, no carabiner or loose strap, and no other accessories '
      'present, the speaker must have a completely blank, unbranded '
      'exterior: absolutely no "SoundWave" text anywhere on the speaker, '
      'no brand name, no logo, no wordmark, no emblem, no symbol that '
      'resembles a brand logo, no printed label, no embossed branding, '
      'no engraved branding, no decorative lettering, and no '
      'product-name text anywhere, the physical speaker body, grille, '
      'buttons, and all surfaces must contain zero readable or '
      'recognizable branding or text, control buttons may use only '
      'simple universal functional symbols if naturally required and '
      'must never include brand-like markings,',
  'elec-010':
      'Show exactly one complete gaming mouse, never a second mouse, a '
      'duplicate mouse, an alternate-view mouse, or a reflection creating '
      'the appearance of a second mouse, the entire mouse fully visible '
      'within the frame with comfortable margins and not cropped, shown '
      'from a clean professional 3/4 product angle with the top buttons '
      'and scroll wheel clearly visible and part of the side profile '
      'visible so the ergonomic gaming-mouse shape is obvious, a '
      'realistic compact lightweight ergonomic gaming-mouse design, the '
      'mouse must be wired to match its catalog specification: a single '
      '1.8m braided cable visibly attached to the front of the mouse, '
      'trailing naturally toward the edge of the frame (the USB '
      'connector does not need to be visible), subtle soft RGB lighting '
      'visibly on along the mouse\'s underside or side accent strip, the '
      'RGB glow realistic and restrained — suitable for professional '
      'e-commerce photography and small ProductCard thumbnails — and '
      'must never dominate the image, the physical mouse body must be '
      'completely unbranded: no "GamePro" text, no logo, no wordmark, no '
      'emblem, no brand symbol, no printed, embossed, or engraved '
      'branding, and the RGB lighting itself must never form letters, '
      'words, logos, or brand-like symbols, the primary buttons and '
      'scroll wheel must look natural and unpressed, side buttons may be '
      'partially visible but do not need to show all eight programmable '
      'buttons, no mouse pad, no keyboard, no monitor, no desk '
      'accessories, no mouse bungee, no charging dock, no wireless '
      'receiver or dongle, and no separate USB cable — only the single '
      'permanently attached braided mouse cable,',
  'elec-011':
      'Show exactly one complete 3-in-1 wireless charging stand, the '
      'charging stand shown completely alone, never a second charging '
      'stand, a duplicate stand, an alternate-view stand, or a reflection '
      'creating the appearance of a second stand, the camera pulled '
      'much farther back so the complete stand appears clearly small in '
      'the frame, occupying only about 42 to 45 percent of the image '
      'height (the whole stand from the top of the upright to the front '
      'edge of the base measuring roughly 430 to 460 pixels tall in a '
      '1024 by 1024 image) and roughly 45 percent of the image width, with '
      'at least 25 percent clear empty background margin above the top of '
      'the stand and at least 25 percent clear empty background margin '
      'below the front edge of the base, and very generous clear margins '
      'on the left and right, the stand centered exactly both vertically '
      'and horizontally in the middle of the composition, so that a '
      'centered 16:9 crop (the middle 56 percent of the image height) and '
      'a centered 4:3 crop both contain the entire stand with comfortable '
      'clearance, the top of the upright and the bottom of the base both '
      'staying far from the top and bottom edges of such a crop, nothing '
      'cropped, the stand unfolded in '
      'its normal upright use position and sitting naturally on a flat '
      'desk surface with its base flat on the surface, shot from a '
      'slightly higher professional 3/4 camera angle, elevated enough that '
      'the flat circular top surface of the smartwatch charging pad is '
      'clearly visible from above and from the front, yet not a top-down '
      'view, so that the upright phone charging surface, the smartwatch '
      'charging pad, and the earbuds charging pad are all visible at the '
      'same time, the phone-support section upright and naturally tilted '
      'backward at a realistic viewing angle, with one clearly defined '
      'phone charging area on the upright support that must clearly look '
      'like an integrated charging SURFACE and not like a phone or tablet: '
      'a flat matte charging pad set flush into the upright support, with '
      'a simple border in the same dark matte material as the stand body, '
      'no metallic rim, no shiny bezel, not a separate slab or separate '
      'device, visually reading as an integral part of the stand body, '
      'and the smartwatch charging area being unmistakable: one clearly '
      'visible circular recessed charging disc, a round matte pad with a '
      'clear circular bordered recess, located on the right side of the '
      'stand at the end of a short sturdy integrated arm that grows '
      'naturally out of the stand body, the arm and the round pad forming '
      'one believable solid connection to the stand, the round pad facing '
      'upward and toward the camera so its full circular surface is '
      'visible and never edge-on or a thin sliver, completely empty, '
      'fully unobstructed by the upright phone support and not '
      'overlapping it, clearly recognizable even at small ProductCard '
      'thumbnail size and visibly different in shape from the earbuds '
      'pad, and one flat dedicated earbuds charging area located on the '
      'front and right portion of the base, fully visible and '
      'unobstructed, marked by a subtle but clearly visible rounded '
      'rectangular recessed or bordered area, so that the three charging '
      'zones are clearly distinguishable from each other, all three '
      'charging surfaces completely empty with no phone, no smartwatch, '
      'and no earbuds placed on or near the stand, the charging surfaces '
      'smooth matte surfaces with no exposed charging coils, no exposed '
      'charging puck, no Qi symbol, and no charging logo, a realistic '
      'premium 3-in-1 charger-stand construction with a dark graphite or '
      'charcoal body for strong contrast against the light background, one '
      'single clean believable mechanical connection between the upright '
      'support and the base, with no overlapping cylinders, no floating '
      'parts, and no extra raised block in front of the base, the stand '
      'looking physically assembled and mechanically plausible, the base '
      'clearly in contact with the desk surface with a soft natural studio '
      'grounding shadow directly beneath and slightly around the entire '
      'base, clearly visible and strong enough to visibly anchor the '
      'stand to the desk, yet still soft, realistic, and never dark, '
      'harsh, or dramatic, the built-in '
      'cooling fan must not be visibly exposed and at most a few subtle '
      'integrated ventilation slots may be visible, only one or two tiny '
      'restrained status LEDs emitting a very soft cool-white or subtle '
      'cool-blue light, the LED glow minimal and never dominating the '
      'composition, and the LEDs must never form letters, words, logos, or '
      'symbols, no charging cable, no USB-C cable, no wall adapter, no '
      'charger brick, and no loose accessories, a USB-C input port may be '
      'visible only if it is naturally integrated into the stand body, no '
      'phone case, no other devices, no additional charger, the physical '
      'stand must be completely unbranded: no "ChargePlus" text, no brand '
      'name, no logo, no wordmark, no emblem, no brand symbol, no "15W" '
      'text, no "3-in-1" text, no "Qi" text or symbol, no printed labels, '
      'no embossed branding, no engraved branding, no decorative '
      'lettering, no product-name text anywhere, and no readable or '
      'recognizable text anywhere on the physical stand, shown as premium '
      'clean 3/4 catalog product photography so the entire stand is '
      'clearly recognizable as a wireless charging stand with strong '
      'contrast suitable for a small ProductCard thumbnail,',
  'elec-012':
      'Show exactly one complete portable external SSD drive, the SSD '
      'shown completely alone, never a second SSD, duplicate drive, '
      'alternate-view drive, or reflection that creates the appearance of '
      'a second drive, the entire SSD fully visible with generous margins '
      'and nothing cropped, centered in the composition, lying flat '
      'naturally on a clean desk surface with its largest face visible, '
      'the long axis oriented horizontally with a modest natural diagonal '
      'rotation, shown from an elevated professional 3/4 product angle '
      'approximately 25 to 35 degrees above the desk surface so the large '
      'top face and one short end edge are both clearly visible, a slim '
      'pocket-sized rectangular aluminum SSD with softly rounded corners '
      'and thin realistic proportions, approximately twice as long as it '
      'is wide and with thickness approximately one tenth of its length, '
      'matte or lightly satin dark space-gray or graphite anodized '
      'aluminum finish, realistic premium aluminum construction with clean '
      'edges and no rubber bumper or bulky protective shell, exactly one '
      'small realistic USB-C port centered on the single visible short end '
      'edge and no other ports anywhere, the USB-C opening modest in size '
      'and physically believable, no USB cable, no USB-C cable, no '
      'adapter, no charger, no sleeve, no case, no packaging, no laptop, '
      'no desktop computer, no phone, no tablet, no power bank, no flash '
      'drive, no other devices, no accessories, no loose objects, no '
      'battery indicator dot row, no LED indicator array and no '
      'illuminated lights, the physical SSD completely unbranded with no '
      '"DataSpeed" text, no brand name, no logo, no wordmark, no emblem, '
      'no brand symbol, no "1TB" text, no "SSD" text, no "1050MB/s" text, '
      'no "1000MB/s" text, no "USB 3.2" text, no "USB-C" text, no '
      'certification marks, no printed labels, no embossed branding, no '
      'engraved branding, no decorative lettering, and absolutely no '
      'readable text anywhere on the device, no mirror-like chrome '
      'reflections, no duplicated reflected SSD shape, realistic '
      'restrained surface reflections suitable for matte anodized '
      'aluminum, the SSD occupying approximately 50 to 60 percent of the '
      'image width but remaining comfortably away from the left and right '
      'edges, at least approximately 20 percent clear background margin on '
      'both left and right sides, ample vertical whitespace above and '
      'below the drive so the complete SSD remains safely visible in '
      'centered 16:9, 4:3, and square crops, the entire SSD including all '
      'four corners and the visible USB-C edge remaining inside the frame, '
      'clean white or very light studio background, soft professional '
      'studio lighting, a clearly visible but soft natural grounding '
      'shadow directly beneath the SSD so it looks firmly placed on the '
      'desk and never floating, premium realistic commercial e-commerce '
      'product photography, crisp realistic materials and edges, no '
      'people, no hands, no unrelated objects, no decorative props, no '
      'text or watermark.',
  'home-001':
      'Show exactly one complete countertop jug blender, alone, consisting '
      'of one motor base, one clear BPA-free plastic blender jug, and one '
      'properly fitted lid, with no second blender, no duplicate jug, no '
      'alternate-view duplicate, and no reflection that creates the '
      'appearance of another blender. The blender must be fully assembled, '
      'stable and naturally standing upright on a flat studio surface, '
      'with the entire appliance visible and nothing cropped, including '
      'the complete lid, complete jug, complete base, handle and bottom of '
      'the motor base. Use a professional elevated 3/4 product-photography '
      'view approximately 10 to 15 degrees above the countertop surface '
      'and approximately 30 degrees horizontal rotation, clearly showing '
      'the front controls, one side handle, the clear jug, fitted lid, '
      'pouring spout and the stainless-steel blade assembly visible '
      'naturally at the bottom of the jug. The blender must read '
      'unmistakably as a countertop jug blender, never as a food '
      'processor, stand mixer, juicer, kettle, travel blender or other '
      'appliance. Use a sturdy premium matte black or dark charcoal motor '
      'base with realistic proportions, clean edges and subtle restrained '
      'reflections. Use a tall clear BPA-free plastic jug with softly '
      'rounded realistic geometry, a comfortable integrated handle on one '
      'side, a subtle pouring spout and realistic transparent walls. The '
      'jug must be completely empty and clean, with no liquid, smoothie, '
      'soup, fruit, vegetables, ice, ingredients or spills. Use a properly '
      'seated dark lid that fits the jug naturally and has a small '
      'removable center cap. Show a realistic multi-blade stainless-steel '
      'blade assembly naturally mounted at the bottom inside the jug; do '
      'not force an exact visible blade count if that would make the '
      'geometry unrealistic. On the front of the dark motor base, show a '
      'simple realistic rotary speed control dial plus one separate pulse '
      'button, but absolutely no numerals, letters, words, icons, symbols, '
      'printed markings or readable labels on the controls. No illuminated '
      'display and no LED array; at most one tiny restrained indicator '
      'light. The blender must be completely unbranded: no "KitchenPro", '
      'no brand name, no logo, no wordmark, no emblem, no decorative '
      'symbol, no "1200W", no "2L", no "Pulse", no "BPA-free", no "10 '
      'speeds", no wattage, no capacity text, no speed numbers, no '
      'measuring graduations, no measurement numbers, no certification '
      'marks, no printed labels, no engraved branding, no embossed '
      'branding and absolutely no readable text anywhere on the blender. '
      'Do not add measurement markings or graduation lines to the '
      'transparent jug. Do not show a power cord, plug, adapter or cable '
      'anywhere. Do not show a tamper, spatula, travel cup, second '
      'container, packaging, manual or accessories. Do not show any '
      'countertop props, cutting board, glass, spoon, bowl, fruit, food or '
      'other kitchen objects. No people or hands. The blender should '
      'occupy approximately 42 to 45 percent of the 1024 by 1024 image '
      'height, approximately 430 to 460 pixels tall, with the complete '
      'appliance centered both horizontally and vertically and with '
      'generous clear background margins, preferably at least 30 percent '
      'on the left and right. Keep the entire blender comfortably inside '
      'the frame with substantial whitespace above and below so the '
      'complete appliance remains safely visible in centered 16:9, 4:3 and '
      'square crops and in the app\x27s product-card and product-details hero '
      'crops. Do not crop the lid, jug, handle, spout or motor base. Use a '
      'clean white or very light studio background that remains visually '
      'distinct enough from the transparent jug edges. Use soft '
      'professional commercial studio lighting with realistic restrained '
      'highlights on the transparent jug and dark base, never mirror-like '
      'reflections and never reflections that resemble duplicate objects. '
      'Include a clearly visible but soft natural grounding shadow '
      'directly beneath and around the motor base so the blender looks '
      'firmly placed on the surface and never floating. Premium realistic '
      'commercial e-commerce product photography, crisp realistic '
      'materials and edges, natural physical construction, no decorative '
      'props, no unrelated objects, no text or watermark.',
  'home-002':
      'Show exactly one complete single-basket countertop air fryer, '
      'alone, with no second appliance, duplicate unit, alternate-view '
      'duplicate, or reflection that creates the appearance of another air '
      'fryer. The appliance must be fully assembled, upright, stable and '
      'naturally standing on a flat countertop surface, with the entire '
      'body, top, front drawer, handle and bottom feet completely visible '
      'and nothing cropped. Use a common modern single-basket pull-out '
      'drawer air-fryer design, unmistakably an air fryer and never an '
      'oven-style toaster oven, microwave, rice cooker, pressure cooker, '
      'coffee machine, bread maker or other appliance. Use a compact '
      'rounded rectangular body in premium matte black or dark charcoal '
      'material with realistic proportions, clean softened edges and '
      'restrained satin highlights. The front must have one closed '
      'pull-out cooking drawer with one sturdy integrated horizontal '
      'handle; the drawer must remain completely closed and no basket '
      'interior must be visible. The cooking compartment must contain '
      'nothing visible: no food, fries, chicken, vegetables, oil, steam, '
      'parchment, liner, crisper plate, rack or ingredients. Place a '
      'realistic digital touchscreen control panel on the upper front or '
      'slightly angled top-front face of the air fryer. The touchscreen '
      'must be completely blank and dark, with no digits, numbers, icons, '
      'symbols, preset labels, temperature values, timer values, graphics '
      'or readable text displayed on it. Do not create an illuminated '
      'interface; at most one tiny restrained status indicator light is '
      'acceptable. Include only subtle realistic ventilation openings '
      'where physically appropriate, with restrained geometry and no '
      'exaggerated grille pattern. Do not expose internal heating elements '
      'or unrealistic mechanical parts. The appliance must be completely '
      'unbranded: no "CookMaster", no brand name, no logo, no wordmark, no '
      'emblem, no decorative symbol, no "5.5L", no "1700W", no "80% less '
      'fat", no "8 presets", no temperature markings, no timer markings, '
      'no preset names, no printed labels, no certification marks, no '
      'engraved branding, no embossed branding and absolutely no readable '
      'text anywhere on the appliance or touchscreen. Do not show a power '
      'cord, plug, adapter or cable anywhere. Do not show a second basket, '
      'removable basket, crisper plate, rack, tray or accessory '
      'separately. Do not show tongs, oven mitts, cookbook, plate, bowl, '
      'food container, kitchen utensils or other countertop props. No '
      'people or hands. Use a professional elevated 3/4 '
      'product-photography view approximately 15 to 20 degrees above the '
      'countertop surface and approximately 30 to 35 degrees horizontal '
      'rotation, clearly showing the closed front drawer and handle, the '
      'blank touchscreen, the top surface and one side panel. Avoid a '
      'steep top-down view. The complete appliance should occupy '
      'approximately 42 to 48 percent of the 1024 by 1024 image height, '
      'approximately 430 to 490 pixels tall, while remaining fully inside '
      'the frame with generous whitespace. Keep the appliance horizontally '
      'and vertically centered, with preferably at least 25 percent clear '
      'background margin on both left and right sides. Leave ample '
      'vertical whitespace so the entire appliance remains safely visible '
      'in centered 16:9, 4:3 and square crops and in the app\x27s '
      'product-card and product-details hero crops. Do not crop the top, '
      'touchscreen, drawer handle, side panels or bottom feet. Use a clean '
      'white or very light studio background that clearly separates the '
      'dark air fryer from the background. Use soft professional '
      'commercial studio lighting with realistic restrained highlights on '
      'the matte dark body and blank touchscreen, never mirror-like '
      'reflections and never reflections that resemble a duplicate '
      'appliance. Include a clearly visible but soft natural grounding '
      'shadow directly beneath and around the base so the air fryer looks '
      'firmly placed on the countertop and never floating. Premium '
      'realistic commercial e-commerce product photography, crisp '
      'realistic materials and edges, natural physical construction, no '
      'decorative props, no unrelated objects, no text or watermark.',
  'home-003':
      'Show exactly one complete round, disc-shaped robot vacuum cleaner, '
      'alone, with exactly one physical robot vacuum in the entire image '
      'and no second robot, no duplicate unit, no alternate-view duplicate, '
      'and no reflection that creates the appearance of another robot. Use '
      'a modern flat robotic vacuum design that reads unmistakably as a '
      'robot vacuum, never as an upright vacuum, handheld vacuum, canister '
      'vacuum, stick vacuum, speaker, plate, smoke detector, hockey puck or '
      'any other round object. The robot must be fully assembled, lying '
      'flat and level on a clean studio floor surface, with the entire '
      'round body completely visible and nothing cropped. Use a flat '
      'circular body approximately 32 to 35 centimeters in diameter and '
      'approximately 8 to 9 centimeters tall in realistic proportions, '
      'with a smooth matte black or dark charcoal body and restrained '
      'satin highlights. The top surface must be smooth and clean. One '
      'subtle, small, restrained circular lidar or sensor turret or low '
      'bump centered on the top is allowed but must remain small and '
      'low-profile, never a large lidar tower. At most one tiny '
      'indicator light is allowed. Include a subtle front bumper strip '
      'along the front edge, and a small recessed front sensor window is '
      'acceptable. Show only the top and side surfaces of the robot: do '
      'not show the underside, brushes, wheels, or dust-bin internals. The '
      'robot must have no display, no screen, no buttons with markings, '
      'and no exposed mechanical parts. Orient the robot naturally with '
      'the front bumper toward the camera. Use a professional elevated 3/4 '
      'product-photography view approximately 25 to 35 degrees above the '
      'floor plane and approximately 20 to 30 degrees horizontal '
      'rotation, clearly showing the circular form and the front bumper. '
      'The robot must be completely unbranded: no "CleanBot", no brand '
      'name, no logo, no wordmark, no emblem, no "2000Pa", no "120min", no '
      'numbers, no letters, no words, no labels, no button legends, no '
      'readable symbols, no certification marks, and absolutely no '
      'readable text anywhere on the robot. Do not show a charging dock, '
      'base station, power cord, plug or cable anywhere. Do not show a '
      'smartphone, app interface, remote control, dust, dirt, crumbs, '
      'pets, rugs, furniture, mop, water tank, accessories, loose brushes, '
      'packaging or manual. No exploded view and no underside view. No '
      'people or hands. The robot should be approximately 55 to 60 percent '
      'of the 1024 by 1024 image width, roughly 400 to 450 pixels wide, '
      'with the complete robot centered horizontally and approximately '
      'vertically, keeping the entire robot comfortably inside the frame '
      'with at least 20 percent clear background margin on the left and '
      'right and at least 25 percent clear background margin above and '
      'below, so the complete robot remains safely visible in centered '
      '16:9, 4:3 and square crops and in the app\x27s product-card and '
      'product-details hero crops. Use a clean white or very light neutral '
      'studio background that clearly separates the dark robot from the '
      'background. Use soft professional commercial studio lighting with '
      'realistic restrained highlights on the matte dark body, never '
      'mirror-like reflections and never reflections that resemble a '
      'duplicate robot. Include a clearly visible but soft natural contact '
      'shadow directly underneath and around the robot so it looks firmly '
      'placed on the floor and never floating, with no hard cast shadow. '
      'Premium realistic commercial e-commerce product photography, crisp '
      'realistic materials and edges, natural physical construction, no '
      'decorative props, no unrelated objects, no text or watermark.',
  'home-004':
      'Show exactly one complete modern LED desk lamp, alone, with exactly '
      'one physical lamp in the entire image and no second lamp, no '
      'duplicate unit, no alternate-view duplicate, and no reflection that '
      'creates the appearance of another lamp. The lamp must be a '
      'freestanding, fully assembled, modern minimalist desk lamp with a '
      'weighted, smooth, rounded base, a slim adjustable articulated arm '
      'with one or two visible joints, and a slim rectangular integrated '
      'LED panel head, never a bare bulb, never a fabric or glass '
      'lampshade, never a floor lamp, wall lamp, clip-on lamp, or '
      'neon/gooseneck-style lamp. Use a neutral matte white or light grey '
      'finish with restrained satin highlights. One subtle, small, '
      'unlabeled circular touch-control area may appear on the base or '
      'arm, and one small USB-A charging port may be visible on the side '
      'of the base, with nothing plugged into it. The lamp is switched off '
      'or shows only an extremely subtle warm-white emission on the LED '
      'panel itself, with no visible light beam, no light cone, no glow '
      'halo, and no lens flare. Use a professional elevated 3/4 '
      'product-photography view approximately 10 to 15 degrees above '
      'horizontal and approximately 20 to 30 degrees horizontal rotation, '
      'with the LED head slightly angled toward the camera, clearly '
      'showing the base, the articulated arm, and the panel head. The '
      'entire lamp must be completely visible from the top of the head to '
      'the bottom of the base, with nothing cropped. The complete lamp '
      'should occupy approximately 55 to 60 percent of the 1024 by 1024 '
      'image height, roughly 560 to 610 pixels tall, and approximately 45 '
      'to 55 percent of the image width, centered horizontally, with its '
      'visual center slightly below the frame center. Keep at least 20 '
      'percent clear background margin on all four sides, with generous '
      'clearance above the LED head so it can never be cropped, and '
      'generous clearance below the base, so the complete lamp remains '
      'safely visible when about 15 percent of the vertical content is '
      'trimmed in the app\x27s product-card crop, when about 30 percent is '
      'trimmed in the product-details hero crop, and in centered 4:3 and '
      '16:9 crops. Never place the lamp, the head, or the base near any '
      'frame edge. Use a clean white or very light neutral studio '
      'background that clearly separates the lamp from the background. Use '
      'soft professional commercial studio lighting with realistic '
      'restrained highlights, never mirror-like reflections and never '
      'reflections that resemble a duplicate lamp. Include a soft, clearly '
      'visible natural contact shadow directly beneath the base and a '
      'subtle ambient shadow around it so the lamp looks firmly placed and '
      'never floating, with no hard cast shadow. The lamp must be '
      'completely unbranded: no "LightPro", no brand name, no logo, no '
      'wordmark, no emblem, no text, no numbers, no letters, no labels, '
      'no product stickers, no certification marks, no visible '
      'specifications, no "15W", no "5V", no "3000K", no watermark, and '
      'absolutely no readable text anywhere. Do not show a desk, table, '
      'books, laptop, smartphone, pens, cables, cords, plugs, a charging '
      'phone, packaging, or a manual. No hands and no people. No exploded '
      'view. Premium realistic commercial e-commerce product photography, '
      'crisp realistic materials and edges, natural physical construction, '
      'no decorative props, no unrelated objects, no text or watermark.',
  'home-005':
      'Show exactly one complete four-piece Queen bed-sheet set, presented '
      'as one neatly folded retail product stack, alone, with exactly one '
      'stack in the entire image and no duplicate stack and no second '
      'bedding set. The stack contains exactly four distinguishable folded '
      'pieces and nothing else: a folded fitted sheet at the bottom, a '
      'folded flat sheet above it, and two folded pillowcases on top, each '
      'pillowcase with subtle envelope-style folded edges. Every piece is '
      'neatly folded with crisp, clean fold edges in a compact retail '
      'presentation, and the four pieces stay clearly distinguishable from '
      'one another as separate layers, never flattened into one '
      'indistinguishable rectangle and never merged into a single white '
      'blob. The finished stack is approximately 8 to 10 centimeters tall '
      'in realistic proportion, with no fifth item, no loose sheet, no '
      'unfolded sheet, no draped fabric, and no messy heap. The material is '
      '100 percent premium cotton with a percale appearance: soft, '
      'breathable natural fabric with a subtle realistic cotton weave and '
      'a natural matte finish, never a synthetic or plastic appearance. The '
      'product data does not specify a color, so use a solid, plain white '
      'to soft off-white neutral cotton with no pattern, no stripes, no '
      'embroidery, no lace, no decorative piping, and no added colors. Use '
      'a professional elevated 3/4 commercial product-photography view '
      'approximately 25 to 35 degrees above horizontal and approximately '
      '15 to 25 degrees horizontal rotation, showing the top surface and '
      'the folded front edges so that each folded layer is visible. The '
      'complete stack should occupy approximately 45 to 50 percent of the '
      '1024 by 1024 image width and approximately 30 to 35 percent of the '
      'image height, centered horizontally, with its visual center '
      'slightly below the frame center. Keep at least 25 percent clear '
      'background margin on the left and right and at least 30 percent '
      'clear background margin above and below, with generous clearance at '
      'the top and bottom, so the complete stack remains fully and safely '
      'inside the frame when about 15 percent of the vertical content is '
      'trimmed in the app\x27s product-card crop, when about 30 percent is '
      'trimmed in the product-details hero crop, and in centered 4:3 and '
      '16:9 crops. Never place the stack near any frame edge. Use a clean '
      'white or very light neutral studio background, slightly off-white at '
      'approximately RGB 250, with enough tonal separation between the '
      'white bedding and the background, and with no room, no bedroom, no '
      'furniture, no bed, no mattress, no headboard, no bedside table, and '
      'no pillow on a bed. Use premium commercial studio lighting: soft, '
      'even illumination with realistic restrained fabric highlights, a '
      'soft natural contact shadow directly beneath and around the stack, '
      'and subtle soft shadows between the folded layers, so the stack '
      'looks firmly placed and never floating, with no hard cast shadow, '
      'no dramatic lighting, and no reflections. The set must be '
      'completely unbranded and unlabeled: no "DreamBed", no brand name, '
      'no logo, no wordmark, no label, no tag, no care tag, no price '
      'sticker, no packaging band, no ribbon, no belly band, no text, no '
      'letters, no numbers, no "400", no "Queen", no thread-count text, '
      'and no watermark. Do not show a plastic bag, box, or any packaging. '
      'No people and no hands. No plants, flowers, towels, or decorative '
      'props. It must look like a clean premium e-commerce catalog product '
      'photo, not a lifestyle bedroom scene. Premium realistic commercial '
      'e-commerce product photography, crisp realistic materials and '
      'edges, natural physical construction, no decorative props, no '
      'unrelated objects, no text or watermark.',
  'home-006':
      'Show exactly one complete freestanding drip coffee maker, alone, '
      'with exactly one coffee maker and exactly one glass carafe in the '
      'entire image, no second coffee maker, no duplicate carafe, and no '
      'reflection that creates the appearance of another product. The '
      'machine must be fully assembled, upright, stable and standing on a '
      'flat surface, and must be a classic drip coffee maker with an '
      'upright rectangular body, a tall rear water-reservoir column '
      'rising at the back of the body, a top lid on the reservoir, and a '
      'brew-basket head projecting forward above the carafe. A clear '
      'glass carafe with one clearly visible handle sits seated on the '
      'flat warming plate of the base, directly beneath the brew-basket '
      'head. The carafe handle must be clearly visible and clearly '
      'separated from the machine body, with visible empty space between '
      'the handle and the body, never merged into or hidden behind the '
      'body. A permanent gold-tone mesh filter may be subtly visible '
      'inside the brew basket, without any paper filter. The front or top '
      'of the machine has one simple, small, unlabeled programmable '
      'control panel with a few plain blank buttons and a blank, unlit '
      'panel, with no readable digits, no text, and no symbols that '
      'resemble letters or numbers. Use a neutral matte black or dark '
      'charcoal plastic body with clean softened edges and restrained '
      'satin highlights, and a clear glass carafe that is empty, clean '
      'and transparent. Use a professional elevated 3/4 commercial '
      'product-photography view approximately 10 to 15 degrees above '
      'horizontal and approximately 20 to 30 degrees horizontal rotation, '
      'showing the rear reservoir, the brew-basket head, the carafe with '
      'its handle, and the base together. The entire machine must be '
      'completely visible from the top of the lid to the bottom of the '
      'base, and from the rear reservoir to the carafe handle, with '
      'nothing cropped. The complete coffee maker should occupy '
      'approximately 55 to 60 percent of the 1024 by 1024 image height, '
      'roughly 560 to 610 pixels tall, and approximately 45 to 55 percent '
      'of the image width, centered horizontally, with its visual center '
      'slightly below the frame center. Keep at least 20 percent clear '
      'background margin on all four sides, with extra clearance above '
      'the lid and extra clearance below the base, and generous clearance '
      'around the carafe handle and the rear reservoir, so the complete '
      'machine, the entire carafe, the entire handle, the entire brew '
      'head and the entire rear reservoir remain fully and safely visible '
      'when about 15 percent of the vertical content is trimmed in the '
      'app\x27s product-card crop, when about 30 percent is trimmed in '
      'the product-details hero crop, and in centered 4:3 and 16:9 crops '
      'with BoxFit.cover. Never place any part of the machine near any '
      'frame edge. Use a clean white or very light neutral studio '
      'background that clearly separates the dark machine from the '
      'background. Use soft, restrained professional commercial studio '
      'lighting with subtle realistic glass highlights on the carafe, '
      'never mirror-like reflections and never reflections that resemble '
      'a second product. Include a soft, clearly visible natural contact '
      'shadow directly beneath the base and a subtle ambient shadow '
      'around it so the machine looks firmly placed and never floating, '
      'with no hard cast shadow. The coffee maker must be completely '
      'unbranded and unlabeled: no brand name, no "BrewMaster", no logo, '
      'no wordmark, no emblem, no text, no letters, no numbers, no '
      '"12-Cup", no "900W", no "24h", no labels, no product stickers, no '
      'certification marks, no volume markings with numbers, and no '
      'watermark, with absolutely no readable text or digits anywhere. '
      'The carafe is empty and no liquid is shown: no steam, no coffee, '
      'no coffee beans, no coffee grounds, no filter paper. Do not show a '
      'mug, a cup, a spoon, a countertop, a kitchen scene, packaging, a '
      'manual, or a power cord. No hands and no people. No exploded view. '
      'It must not be an espresso machine, a pod or capsule machine, a '
      'French press, a pour-over stand, a kettle, or a thermal carafe '
      'machine. No glowing display, no light cone, and no lens flare. '
      'Premium realistic commercial e-commerce product photography, '
      'crisp realistic materials and edges, natural physical '
      'construction, no decorative props, no unrelated objects, no text '
      'or watermark.',
  'home-007':
      'Show exactly one single modern minimalist wall clock, one complete '
      'circular clock only, with exactly one clock in the entire image, no '
      'second clock, no duplicate clock, no mirror, and no reflection that '
      'creates the appearance of another clock. The clock is a realistic '
      'silent quartz wall clock with a simple round plastic frame in a '
      'neutral matte white or light gray finish, a thin clean frame with '
      'no decorative ornaments, and a clean white or off-white clock face. '
      'The face has simple black hour and minute hands only, with no '
      'second hand and no extra hands, and large, easy-to-read black '
      'Arabic numerals showing exactly 12 hour positions, from 1 to 12, '
      'evenly spaced around the face, with no extra numbers and no '
      'duplicated or missing numerals. The clock face is sharp and clearly '
      'readable. Use a front-facing view or a very slight 3/4 view, with '
      'the complete circular clock fully visible, centered horizontally, '
      'and its visual center slightly below the frame center. The complete '
      'clock should occupy approximately 55 to 60 percent of the image '
      'width and approximately 55 to 60 percent of the image height, with '
      'at least 20 percent clear background margin on the left and right '
      'and at least 20 percent clear background margin on the top and '
      'bottom, leaving enough clearance so the whole clock remains fully '
      'visible in square, product-card and product-details hero crops. '
      'Never let the circular clock touch or come close to any image '
      'edge. Use a clean white or light-neutral studio background with no '
      'wall texture, no room environment, no horizon line, and no props, '
      'and include a subtle, natural, soft shadow behind and below the '
      'clock so it looks firmly presented and never floating, with no '
      'hard cast shadow. The clock must be completely unbranded and '
      'unlabeled: no readable branding, no logo, no wordmark, no '
      'watermark, and no text of any kind except the clock numerals. Do '
      'not show a digital display. Do not show a person, a hand, a wall '
      'hook, furniture, a room scene, a table, a shelf, packaging, a '
      'battery, tools, or any other extra object. Use soft, even studio '
      'lighting with realistic materials and proportions and clean edges. '
      'Premium realistic commercial e-commerce product photography, crisp '
      'realistic materials and edges, natural physical construction, no '
      'decorative props, no unrelated objects, no text or watermark other '
      'than the clock numerals.',
  'sport-001':
      'Show exactly one premium rolled yoga mat, one complete cylindrical '
      'roll only, with exactly one mat in the entire image, tightly and '
      'neatly rolled, no second mat, no unrolled mat, no partially '
      'unrolled mat, no duplicate roll, and no reflection that creates the '
      'appearance of another mat. The mat is a thick, 6mm-looking '
      'cushioned mat made of realistic TPE material in a premium dark teal '
      'or deep green color, with a subtle, realistic non-slip surface '
      'texture and clean, neatly wound layers visible at the ends of the '
      'roll. Exactly one simple carrying strap is wrapped around the roll, '
      'clearly visible and physically attached to the roll, with no '
      'duplicate strap. It is a freestanding product only, with the roll '
      'positioned horizontally or in a slight diagonal, in an elevated 3/4 '
      'commercial product-photography view. The complete roll and the '
      'complete strap must be fully visible with nothing cropped. The roll '
      'should occupy approximately 45 to 55 percent of the image width and '
      'approximately 30 to 40 percent of the image height, centered '
      'horizontally, with its visual center slightly below the frame '
      'center. Keep at least 25 percent clear background margin on the '
      'left and right and at least 30 percent clear background margin on '
      'the top and bottom, leaving enough clearance so the whole roll and '
      'strap remain fully visible in square, product-card and '
      'product-details hero crops. Never let any part of the roll or strap '
      'touch or come near any image edge. Use a clean white or '
      'light-neutral studio background with no floor line, no wall '
      'texture, no room environment, and no props, and include a subtle, '
      'natural contact shadow directly beneath the roll so it looks firmly '
      'placed and never floating, with no hard cast shadow. Use soft, even '
      'commercial studio lighting with realistic cylindrical geometry, a '
      'realistic TPE surface, clean edges, natural proportions, and sharp '
      'product detail. The mat must be completely unbranded and '
      'unlabeled: no text, no logo, no watermark, and no readable '
      'branding. Do not show a person, hands, feet, a yoga pose, or anyone '
      'exercising. Do not show a gym, a studio interior, furniture, a '
      'water bottle, yoga blocks, towels, shoes, weights, dumbbells, '
      'resistance bands, a phone, packaging, a box, or any other extra '
      'fitness equipment or object. Premium realistic commercial '
      'e-commerce product photography, crisp realistic materials and '
      'edges, natural physical construction, no decorative props, no '
      'unrelated objects, no text or watermark.',
  'sport-002':
      'Show exactly one product image containing exactly two matching '
      'adjustable dumbbells forming one complete pair, both dumbbells '
      'fully complete and clearly visible with nothing cropped, no third '
      'dumbbell, no duplicate dumbbell, and no reflection that creates '
      'the appearance of a third dumbbell, each dumbbell built with a '
      'realistic central metal handle and compact black or '
      'dark-charcoal weight plates on both ends, a realistic '
      'plate-locking or adjustment mechanism visibly integrated into '
      'the plates, and a subtle rubberized or matte surface finish, '
      'giving both dumbbells a professional, premium fitness-equipment '
      'appearance, the two dumbbells arranged parallel to each other or '
      'in a clean slight diagonal, both dumbbells fully inside the '
      'frame, shown from an elevated 3/4 commercial product-photography '
      'angle approximately 15 to 25 degrees above horizontal with a '
      'slight 15 to 25 degree horizontal rotation, the combined pair '
      'occupying approximately 50 to 55 percent of the image width and '
      'approximately 30 to 40 percent of the image height, centered '
      'horizontally, with its visual center slightly below the frame '
      'center, keeping at least 22 to 25 percent clear background '
      'margin on the left and right and at least 28 to 30 percent clear '
      'background margin on the top and bottom, leaving generous '
      'clearance around both dumbbells so the complete pair remains '
      'fully visible in square, product-card and product-details hero '
      'crops, and never letting any part of either dumbbell touch or '
      'come near any image edge, set on a clean near-white or '
      'light-neutral studio background at approximately RGB 250 to 254 '
      'with no floor line and no room or interior visible, with a soft, '
      'natural contact shadow beneath the dumbbells so they look firmly '
      'placed and never floating, under soft commercial e-commerce '
      'studio lighting with clean edges, physically plausible realistic '
      'geometry, realistic weight plates, and realistic handles, with '
      'no melted geometry, no fused dumbbells, no impossible '
      'connections between the two dumbbells, no generation artifacts, '
      'no excessive reflections, and no dramatic perspective '
      'distortion, both dumbbells completely unbranded and unlabeled '
      'with no readable text, no numbers, no logo, no watermark, no '
      'brand name, no "FitGear" text anywhere, no "5-25kg" text '
      'anywhere, no "25kg" text anywhere, and no readable labels of any '
      'kind, and the image must not show any people, hands, feet, or '
      'other body parts, a gym, a gym floor, a bench, a rack, any '
      'exercise equipment other than the two dumbbells, separate loose '
      'weight plates, a kettlebell, a barbell, resistance bands, a yoga '
      'mat, a bottle, a towel, shoes, a phone, packaging, a box, a '
      'manual, a stand, or any other accessories,',
  'sport-003':
      'Show exactly one complete resistance-band fitness set as the only '
      'product in the image, containing exactly five separate resistance '
      'bands as the main components, each band a realistic closed-loop or '
      'tube-style resistance band with natural-latex material appearance, '
      'the five bands clearly distinguishable from each other by their '
      'thickness or width, arranged in a neat, slightly overlapping fan or '
      'parallel arrangement so each one remains individually visible, all '
      'five bands in dark neutral or black tones with subtle tonal '
      'differences between them and no other colors, together with the '
      'following accessories shown as one organized part of the same set: '
      'exactly two comfortable handles, exactly two ankle straps, exactly '
      'one door anchor, and exactly one carrying bag, the handles, ankle '
      'straps, door anchor and carrying bag arranged neatly beside the '
      'bands and clearly part of the same set, with no duplicated '
      'accessories, no duplicate bands, no duplicate handles, no duplicate '
      'straps, no tangled or impossible band geometry, and no reflection '
      'that creates the appearance of a second set, every component built '
      'with realistic materials and physically plausible construction, '
      'shown from an elevated 3/4 commercial product-photography angle '
      'approximately 15 to 25 degrees above horizontal with a slight 15 '
      'to 25 degree horizontal rotation, the combined set occupying '
      'approximately 55 to 60 percent of the image width and '
      'approximately 35 to 45 percent of the image height, centered '
      'horizontally, with its visual center slightly below the frame '
      'center, keeping at least 20 to 25 percent clear background margin '
      'on the left and right and at least 25 to 30 percent clear '
      'background margin on the top and bottom, leaving generous '
      'clearance around the entire set so every component remains fully '
      'inside the frame and the composition stays safe for square, '
      'product-card and product-details hero crops, set on a clean '
      'near-white or light-neutral studio background at approximately '
      'RGB 250 to 254 with no floor line and no room or interior visible, '
      'with a soft, natural contact shadow beneath the set so it looks '
      'firmly placed and never floating, under commercial e-commerce '
      'studio lighting with clean edges, physically plausible realistic '
      'geometry, realistic natural-latex bands, realistic handles and '
      'ankle straps, a realistic door anchor, and a realistic carrying '
      'bag, with no melted geometry, no fused accessories, no impossible '
      'connections, no generation artifacts, no excessive reflections, '
      'and no dramatic perspective distortion, the entire set completely '
      'unbranded and unlabeled with no readable text, no numbers, no '
      'logo, no watermark, no brand name, no "FlexFit" text anywhere, no '
      '"5 Levels" text anywhere, no "10-50 lbs" text anywhere, no '
      '"120cm" text anywhere, and no readable labels of any kind, and '
      'the image must not show any people, hands, feet, or other body '
      'parts, a person exercising, a gym, a gym floor, a bench, a rack, '
      'dumbbells, a kettlebell, a barbell, other weights, a yoga mat, a '
      'bottle, a towel, shoes, a phone, packaging, a retail box, a '
      'manual, or any other unrelated fitness equipment,',
  'sport-004':
      'Show exactly one premium insulated stainless-steel water bottle as '
      'the only product in the image, a single 1L reusable double-wall '
      'insulated bottle with a tall cylindrical body, a premium modern '
      'commercial-product appearance, a matte dark navy or deep-blue body, '
      'and a subtle stainless-steel or matching dark screw cap implying a '
      'wide-mouth, leak-proof opening, a clean minimal silhouette with no '
      'visible branding, no logo, no measurement markings, and no '
      'decorative graphics, the bottle standing upright and fully '
      'assembled with its cap attached, shown from an elevated 3/4 '
      'product view approximately 10 to 15 degrees above horizontal with '
      'approximately 15 to 25 degrees of horizontal rotation and the '
      'camera positioned slightly above the bottle center, the bottle '
      'vertically centered with its visual center slightly below the '
      'exact canvas center, occupying approximately 60 to 65 percent of '
      'the image height and approximately 25 to 32 percent of the image '
      'width, keeping at least 20 percent clear background margin on the '
      'left and right and at least 17 to 20 percent clear background '
      'margin on the top and bottom, with additional clearance around '
      'the cap and base so the complete bottle remains safe for square, '
      '4:3, approximately 1.43:1 hero, and 16:9 crops, set on a clean '
      'white or very light neutral studio background at approximately '
      'RGB 250 to 255 with a subtle natural contact shadow beneath the '
      'bottle, under soft commercial studio lighting with realistic but '
      'restrained reflections, no harsh glare, and no dramatic colored '
      'lighting, physically plausible bottle geometry with a straight '
      'cylindrical body and the cap aligned with the bottle axis, no '
      'warped bottle, no duplicated parts, no malformed cap, no melted '
      'geometry, and clean edges, and the image must not show a second '
      'bottle, a cup, a glass, a tumbler, a thermos beside it, a straw, '
      'ice, a water splash, pouring liquid, fruit, a lemon, gym '
      'equipment, a person or hand, a backpack, a table setting, a '
      'kitchen scene, an outdoor scene, packaging, a box, other '
      'accessories, a duplicate reflection that looks like another '
      'bottle, a floating cap, a detached lid, a visible cord, readable '
      'text, a logo, a watermark, a product label, dimensions, numbers, '
      'or brand names,',
};

/// Builds the deterministic, professional e-commerce prompt for one product,
/// filling {name}/{category}/characteristics from real catalog + (optional)
/// mock_products.dart data — never from a template placeholder left as-is.
String _buildPrompt(ProductRow product, _Enrichment? enrichment) {
  final sentences = <String>[];

  final description = enrichment?.description;
  if (description != null && description.isNotEmpty) {
    sentences.add(
      description.length > 220
          ? '${description.substring(0, 220)}.'
          : description,
    );
  }

  final brand = enrichment?.brand;
  if (brand != null && brand.isNotEmpty) {
    sentences.add('Brand: $brand.');
  }

  final features = enrichment?.features ?? const <String>[];
  if (features.isNotEmpty) {
    sentences.add('Key characteristics: ${features.take(3).join(", ")}.');
  }

  final characteristics = sentences.isEmpty
      ? 'Depict the exact type of product accurately based on its name.'
      : sentences.join(' ');

  final composition = _compositionOverrides[product.slug] ??
      'Single product centered and clearly visible,';

  return 'Professional e-commerce product photography of ${product.name}, '
      'a ${product.category} product. $characteristics '
      '$composition isolated on a clean '
      'white or very light studio background, soft realistic studio '
      'lighting, natural grounding shadow, premium commercial catalog '
      'photography, realistic materials and textures, sharp details, no '
      'people, no hands, no text, no watermark, no decorative props, no '
      'unrelated objects.';
}

/// Thrown for HTTP 429 / 5xx / transport-level failures — retryable up to
/// `_maxGenerationAttempts`. Carries the server's `Retry-After` value when
/// present so the caller can honor it instead of the default backoff.
class _RetryableApiException implements Exception {
  _RetryableApiException(this.message, {this.retryAfter});

  final String message;
  final Duration? retryAfter;
}

/// Thrown for any other non-2xx response (e.g. 400 content rejection). Never
/// retried — retrying a rejected prompt cannot succeed.
class _NonRetryableApiException implements Exception {
  _NonRetryableApiException(this.message);

  final String message;
}

String _truncateForLog(String s, [int max = 300]) =>
    s.length <= max ? s : '${s.substring(0, max)}...';

/// Single call to the OpenAI Images API for one product. The API key is read
/// from the caller-supplied value only — never logged, never included in any
/// exception message, never written anywhere by this function.
Future<Uint8List> _callOpenAiImageGeneration({
  required String apiKey,
  required String prompt,
}) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);
  try {
    final request = await client.postUrl(Uri.parse(_openAiImagesEndpoint));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'model': _imageGenModel,
        'prompt': prompt,
        'n': 1,
        'size': _imageGenSize,
        'quality': _imageGenQuality,
        'background': _imageGenBackground,
        'output_format': _imageGenOutputFormat,
        'moderation': _imageGenModeration,
      }),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 429 || response.statusCode >= 500) {
      Duration? retryAfter;
      final header = response.headers.value('retry-after');
      final headerSeconds = header == null ? null : int.tryParse(header);
      if (headerSeconds != null) retryAfter = Duration(seconds: headerSeconds);
      throw _RetryableApiException(
        'HTTP ${response.statusCode}: ${_truncateForLog(responseBody)}',
        retryAfter: retryAfter,
      );
    }
    if (response.statusCode != 200) {
      throw _NonRetryableApiException(
        'HTTP ${response.statusCode}: ${_truncateForLog(responseBody)}',
      );
    }

    final decoded = jsonDecode(responseBody);
    final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
    if (data is! List || data.isEmpty) {
      throw _NonRetryableApiException(
        'response had no image data: ${_truncateForLog(responseBody)}',
      );
    }
    final first = data.first;
    final b64 = first is Map<String, dynamic> ? first['b64_json'] : null;
    if (b64 is! String || b64.isEmpty) {
      throw _NonRetryableApiException(
        'response did not include b64_json image data',
      );
    }
    return base64Decode(b64);
  } finally {
    client.close(force: true);
  }
}

Future<void> _generateImages({String? slug}) async {
  // The --slug guard runs before OPENAI_API_KEY is even read, and before the
  // catalog snapshot's mutable-per-run data is touched for generation
  // purposes, so a bad/ineligible slug can never reach the point where an
  // API call would be made.

  // Reuses the existing catalog-snapshot mechanism and its existing
  // freshness rule: the snapshot must exist (via fetch-catalog) — the same
  // guard every other command in this tool relies on. The snapshot only
  // ever contains active products (see `_fetchCatalogSql`'s
  // `WHERE p.is_active = true`), so a slug missing from it is either
  // nonexistent or inactive — indistinguishable from local data alone, and
  // both are equally ineligible for --slug generation.
  final products = await _loadCatalog();

  List<ProductRow> missing;
  if (slug != null) {
    ProductRow? target;
    for (final p in products) {
      if (p.slug == slug) {
        target = p;
        break;
      }
    }

    if (target == null) {
      stdout.writeln(
        'No active product found with slug "$slug" (it does not exist, or '
        'is not active). Made zero API calls.',
      );
      return;
    }

    if (target.imageCount > 0) {
      stdout.writeln(
        '[SKIP] $slug — ${target.name} already has ${target.imageCount} '
        'image(s) in the database. Made zero API calls.',
      );
      return;
    }

    // A local file already passing validation is handled below by the same
    // resumability check the full batch uses (never regenerated, zero API
    // calls) — no separate check is needed here.
    missing = [target];
  } else {
    missing = products.where((p) => p.imageCount == 0).toList()
      ..sort((a, b) => a.slug.compareTo(b.slug));
  }

  final apiKey = Platform.environment['OPENAI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln(
      'OPENAI_API_KEY is not set; refusing to make any generation '
      'attempts.\n'
      'Set it in your shell environment before re-running — never in a '
      'file, never printed, never committed:\n'
      '  export OPENAI_API_KEY=...\n'
      '  dart run tool/product_image_backfill.dart generate-images',
    );
    exit(1);
  }

  final host = await _projectHost();

  // Every URL already present in the database, for the DB-URL-collision
  // check — built the same way `validate` builds it.
  final dbUrlOwners = <String, List<String>>{};
  for (final p in products) {
    for (final url in p.existingUrls) {
      dbUrlOwners.putIfAbsent(url, () => <String>[]).add(p.slug);
    }
  }

  final enrichment = await _loadMockEnrichment();

  await Directory(_imagesDir).create(recursive: true);
  await Directory(_outputDir).create(recursive: true);

  // Preload bytes of every existing local image (the completed products'
  // files included) for duplicate-content comparisons, exactly as `validate`
  // compares candidates against each other.
  final contentByKey = <String, Uint8List>{};
  final existingFiles = Directory(_imagesDir).existsSync()
      ? Directory(_imagesDir).listSync().whereType<File>()
      : const <File>[];
  for (final f in existingFiles) {
    final name = f.uri.pathSegments.last;
    if (name == '.gitkeep' || !name.endsWith(_requiredExtension)) continue;
    try {
      contentByKey[name] = await f.readAsBytes();
    } catch (_) {
      // Unreadable file — ignore for dedup purposes; per-product handling
      // below re-reads and re-validates its own file independently.
    }
  }

  final results = <Map<String, dynamic>>[];
  var skipped = 0;
  var generatedOk = 0;
  var failed = 0;

  stdout
    ..writeln('--- generate-images ---')
    ..writeln('Model: $_imageGenModel')
    ..writeln('Products missing an image: ${missing.length}')
    ..writeln('');

  for (final product in missing) {
    final objectKey = '${product.slug}$_requiredExtension';
    final localPath = '$_imagesDir/$objectKey';
    final file = File(localPath);
    final attemptedAt = DateTime.now().toUtc();

    // Resumability: a file that already exists and passes the same
    // primitives `validate` uses is left completely untouched and never
    // regenerated. Only an existing-but-invalid or missing file proceeds to
    // generation below.
    if (file.existsSync()) {
      Uint8List? existingBytes;
      try {
        existingBytes = await file.readAsBytes();
      } catch (_) {
        existingBytes = null;
      }
      if (existingBytes != null && _basicImageProblem(existingBytes) == null) {
        stdout.writeln(
          '[SKIP] ${product.slug} — already has a valid local image',
        );
        results.add({
          'slug': product.slug,
          'product_name': product.name,
          'product_id': product.id,
          'status': 'skipped_already_valid',
          'reason': null,
          'prompt': null,
          'bytes_written': existingBytes.length,
          'timestamp': attemptedAt.toIso8601String(),
          'attempts': 0,
        });
        skipped++;
        contentByKey[objectKey] = existingBytes;
        continue;
      }
    }

    final prompt = _buildPrompt(product, enrichment[product.slug]);
    var attempts = 0;
    String? failureReason;
    var succeeded = false;

    while (attempts < _maxGenerationAttempts &&
        !succeeded &&
        failureReason == null) {
      attempts++;
      try {
        final bytes = await _callOpenAiImageGeneration(
          apiKey: apiKey,
          prompt: prompt,
        );

        // Write first, then verify the real bytes — never simply trust the
        // requested output_format and rename a response onto disk.
        await file.writeAsBytes(bytes, flush: true);

        final basicProblem = _basicImageProblem(bytes);
        if (basicProblem != null) {
          await file.delete();
          failureReason = basicProblem;
          break;
        }

        if (objectKey == _protectedObjectKey) {
          await file.delete();
          failureReason =
              'refusing to write to protected object key $_protectedObjectKey';
          break;
        }

        String? duplicateOf;
        for (final entry in contentByKey.entries) {
          if (entry.key == objectKey) continue;
          if (_bytesEqual(entry.value, bytes)) {
            duplicateOf = entry.key;
            break;
          }
        }
        if (duplicateOf != null) {
          await file.delete();
          failureReason =
              'generated image is byte-for-byte identical to $duplicateOf';
          break;
        }

        final publicUrl = _publicUrl(host, objectKey);
        final owners = dbUrlOwners[publicUrl];
        if (owners != null) {
          await file.delete();
          failureReason =
              'target URL already stored in the database for: '
              '${owners.join(", ")}';
          break;
        }

        contentByKey[objectKey] = bytes;
        succeeded = true;
      } on _RetryableApiException catch (e) {
        if (attempts >= _maxGenerationAttempts) {
          failureReason = e.message;
          break;
        }
        final delay =
            e.retryAfter ?? Duration(seconds: _retryBackoffSeconds[attempts - 1]);
        stdout.writeln(
          '  ${product.slug}: attempt $attempts failed (${e.message}); '
          'retrying in ${delay.inSeconds}s',
        );
        await Future.delayed(delay);
      } on _NonRetryableApiException catch (e) {
        failureReason = e.message;
        break;
      } catch (e) {
        if (attempts >= _maxGenerationAttempts) {
          failureReason = 'request error: $e';
          break;
        }
        final delay = Duration(seconds: _retryBackoffSeconds[attempts - 1]);
        stdout.writeln(
          '  ${product.slug}: attempt $attempts error ($e); retrying in '
          '${delay.inSeconds}s',
        );
        await Future.delayed(delay);
      }
    }

    if (succeeded) {
      final bytesLen = contentByKey[objectKey]!.length;
      stdout.writeln(
        '[GENERATED] ${product.slug} — ${product.name} '
        '($bytesLen bytes, $attempts attempt(s))',
      );
      results.add({
        'slug': product.slug,
        'product_name': product.name,
        'product_id': product.id,
        'status': 'generated_ok',
        'reason': null,
        'prompt': prompt,
        'bytes_written': bytesLen,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'attempts': attempts,
      });
      generatedOk++;
    } else {
      stdout.writeln(
        '[FAILED] ${product.slug} — ${failureReason ?? "unknown error"}',
      );
      results.add({
        'slug': product.slug,
        'product_name': product.name,
        'product_id': product.id,
        'status': 'failed',
        'reason': failureReason ?? 'unknown error',
        'prompt': prompt,
        'bytes_written': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'attempts': attempts,
      });
      failed++;
    }
  }

  final report = {
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'model': _imageGenModel,
    'total_considered': missing.length,
    'skipped_already_valid_count': skipped,
    'generated_ok_count': generatedOk,
    'failed_count': failed,
    'products': results,
  };

  await File(
    _generationReportPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));

  stdout
    ..writeln('')
    ..writeln('--- generate-images summary ---')
    ..writeln('Total considered: ${missing.length}')
    ..writeln('Skipped (already valid): $skipped')
    ..writeln('Generated: $generatedOk')
    ..writeln('Failed: $failed')
    ..writeln('Images directory: $_imagesDir')
    ..writeln('Report: $_generationReportPath');
}

// ---------------------------------------------------------------------------
// upload-images
// ---------------------------------------------------------------------------
//
// The only command in this tool that can perform a real Storage upload and a
// real public.product_images INSERT — and only when --execute is passed.
// Without --execute (the default) it runs every read-only step (including a
// fresh catalog query) and reports exactly what WOULD happen, making zero
// network calls to Storage or PostgREST.

/// Parses `--execute`. Its absence (the default) means dry-run.
bool _extractExecuteFlag(List<String> args) => args.skip(1).contains('--execute');

/// True when [e] has the shape of one `_fetchCatalogSql` result row (as
/// opposed to some other, unrelated array the CLI might ever emit). Used to
/// decide whether a bare top-level JSON array may be treated as the catalog
/// rows themselves — never assumed from array-ness alone.
bool _looksLikeProductRow(dynamic e) =>
    e is Map<String, dynamic> &&
    e.containsKey('id') &&
    e.containsKey('slug') &&
    e.containsKey('name') &&
    e.containsKey('category') &&
    e.containsKey('image_count') &&
    e.containsKey('existing_urls');

/// Runs a fresh, read-only SELECT against the linked Supabase project,
/// deliberately independent of tool/catalog_snapshot.json — that snapshot is
/// only ever as fresh as the last fetch-catalog run, and upload-images must
/// never act on stale product_images counts.
Future<List<ProductRow>> _fetchFreshCatalogForUpload() async {
  await Directory(_outputDir).create(recursive: true);
  final tmp = File('$_outputDir/.tmp_upload_images_catalog.sql');
  await tmp.writeAsString(_fetchCatalogSql);

  stdout.writeln(
    'Running a fresh read-only SELECT against the linked Supabase project '
    '(tool/catalog_snapshot.json is not used by this command)...',
  );
  // Pinned to a known CLI version: `npx supabase` (unpinned) can silently
  // resolve a different CLI release across machines/time, and different
  // releases have used different --output-format json envelopes.
  final result = await Process.run('npx', [
    'supabase@2.117.0',
    'db',
    'query',
    '--linked',
    '--output-format',
    'json',
    '--file',
    tmp.path,
  ], runInShell: true);

  if (await tmp.exists()) await tmp.delete();

  if (result.exitCode != 0) {
    stderr.writeln('Fresh catalog query failed:\n${result.stderr}');
    exit(1);
  }

  final decoded = jsonDecode(result.stdout as String);
  // `supabase db query --output-format json` normally emits a
  // {"rows": [...]} envelope (the current pinned CLI also wraps it with
  // `boundary`/`warning` keys, which are simply ignored here), but some CLI
  // versions instead emit the rows as a bare top-level JSON array with no
  // envelope at all. Accept either shape — but only treat a bare array as
  // the catalog when its elements actually look like product rows — and
  // fail loudly on anything else instead of silently treating it as an
  // empty catalog. An unrecognized shape is a CLI/parsing problem, not
  // evidence that the catalog is actually empty.
  List<dynamic>? rows;
  if (decoded is Map<String, dynamic>) {
    final rawRows = decoded['rows'];
    if (rawRows is List<dynamic>) rows = rawRows;
  } else if (decoded is List<dynamic> &&
      decoded.isNotEmpty &&
      decoded.every(_looksLikeProductRow)) {
    rows = decoded;
  }

  if (rows == null) {
    stderr.writeln(
      'Fresh catalog query returned an unexpected JSON response shape — '
      'refusing to proceed. Expected {"rows": [...]} or a bare array of '
      'product rows, got a ${decoded.runtimeType}'
      '${decoded is Map ? " with keys ${decoded.keys.toList()}" : ""}'
      '${decoded is List ? " of length ${decoded.length}" : ""}.',
    );
    exit(1);
  }

  // A genuinely empty catalog is not a real possibility for this project —
  // `_fetchCatalogSql` always matches at least the seeded active products.
  // Zero rows here almost certainly means the CLI/JSON response was
  // malformed, truncated, or in an unrecognized shape, not that the catalog
  // is actually empty. Treating that silently as "no active products" would
  // make every local file in tool/images/ look like it has no matching
  // product, so fail loudly instead of returning an empty list.
  if (rows.isEmpty) {
    stderr.writeln(
      'Fresh catalog query returned 0 rows — refusing to proceed; this may '
      'be a CLI/parsing/query problem.',
    );
    exit(1);
  }

  return rows
      .map((e) => ProductRow.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// One outcome row for the upload-images JSON report. `reason` is always
/// built from HTTP status codes / response bodies — never from request
/// headers — so it can never carry the API key.
class _UploadOutcome {
  _UploadOutcome({
    required this.slug,
    required this.status,
    this.productId,
    this.objectKey,
    this.publicUrl,
    this.bytes,
    this.reason,
  });

  final String slug;
  final String status;
  final String? productId;
  final String? objectKey;
  final String? publicUrl;
  final int? bytes;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'status': status,
    if (productId != null) 'product_id': productId,
    if (objectKey != null) 'object_key': objectKey,
    if (publicUrl != null) 'public_url': publicUrl,
    if (bytes != null) 'bytes': bytes,
    if (reason != null) 'reason': reason,
  };
}

class _HttpOutcome {
  _HttpOutcome({required this.ok, this.error});

  final bool ok;
  final String? error;
}

/// Uploads raw JPEG bytes to Storage with x-upsert:false, so an existing
/// object — including $_protectedObjectKey — can never be replaced. Header
/// shape mirrors the human-run plan-upload script exactly: a single
/// Authorization: Bearer credential. Accepts either the legacy service_role
/// JWT or the new sb_secret_* key verbatim — both are opaque bearer values
/// to this call, so no format-specific handling is needed.
Future<_HttpOutcome> _uploadObjectToStorage({
  required String host,
  required String apiKey,
  required String objectKey,
  required Uint8List bytes,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final uri = Uri.parse(
      'https://$host/storage/v1/object/$_bucketName/$objectKey',
    );
    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set('apikey', apiKey);
    request.headers.contentType = ContentType('image', 'jpeg');
    request.headers.set('x-upsert', 'false');
    request.add(bytes);

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _HttpOutcome(ok: true);
    }
    return _HttpOutcome(
      ok: false,
      error: 'HTTP ${response.statusCode}: ${_truncateForLog(body)}',
    );
  } catch (e) {
    return _HttpOutcome(ok: false, error: 'request error: $e');
  } finally {
    client.close(force: true);
  }
}

/// Inserts one public.product_images row via the project's PostgREST API.
/// Both `apikey` and `Authorization: Bearer` are set to the same credential,
/// which is how Supabase's REST layer accepts either the legacy service_role
/// JWT or the new sb_secret_* format.
Future<_HttpOutcome> _insertProductImageRow({
  required String host,
  required String apiKey,
  required String productId,
  required String url,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final uri = Uri.parse('https://$host/rest/v1/product_images');
    final request = await client.postUrl(uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
    request.headers.set('apikey', apiKey);
    request.headers.contentType = ContentType.json;
    request.headers.set('Prefer', 'return=minimal');
    request.write(
      jsonEncode({'product_id': productId, 'url': url, 'sort_order': 0}),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return _HttpOutcome(ok: true);
    }
    return _HttpOutcome(
      ok: false,
      error: 'HTTP ${response.statusCode}: ${_truncateForLog(body)}',
    );
  } catch (e) {
    return _HttpOutcome(ok: false, error: 'request error: $e');
  } finally {
    client.close(force: true);
  }
}

Future<void> _uploadImages({required bool execute}) async {
  final products = await _fetchFreshCatalogForUpload();
  final bySlug = {for (final p in products) p.slug: p};
  final host = await _projectHost();

  String? apiKey;
  if (execute) {
    apiKey = Platform.environment['SUPABASE_SERVICE_ROLE_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      stderr.writeln(
        'SUPABASE_SERVICE_ROLE_KEY is not set; refusing to upload or write '
        'to the database.\n'
        'Set it in your shell environment before re-running with --execute — '
        'never in a file, never printed, never committed. Both the legacy '
        'service_role JWT and the new sb_secret_* key format are accepted:\n'
        '  export SUPABASE_SERVICE_ROLE_KEY=sb_secret_...\n'
        '  dart run tool/product_image_backfill.dart upload-images --execute',
      );
      exit(1);
    }
  }

  final dir = Directory(_imagesDir);
  final files = dir.existsSync()
      ? (dir.listSync().whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];

  final uploaded = <_UploadOutcome>[];
  final alreadyPresent = <_UploadOutcome>[];
  final linked = <_UploadOutcome>[];
  final skipped = <_UploadOutcome>[];
  final failed = <_UploadOutcome>[];
  final errors = <String>[];

  stdout
    ..writeln('--- upload-images (${execute ? "EXECUTE" : "DRY RUN"}) ---')
    ..writeln('Local files scanned in $_imagesDir: ${files.length}')
    ..writeln('');

  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (name == '.gitkeep') continue;

    if (!name.endsWith(_requiredExtension)) {
      skipped.add(
        _UploadOutcome(
          slug: name,
          status: 'skipped_unsupported_extension',
          reason:
              'only "$_requiredExtension" files are handled by '
              'upload-images',
        ),
      );
      continue;
    }

    if (name == _protectedObjectKey) {
      skipped.add(
        _UploadOutcome(
          slug: name,
          status: 'skipped_protected_object',
          reason:
              'this is the existing Smart Watch Ultra Storage object; it '
              'must never be touched',
        ),
      );
      continue;
    }

    final slug = name.substring(0, name.length - _requiredExtension.length);
    final product = bySlug[slug];
    if (product == null) {
      failed.add(
        _UploadOutcome(
          slug: slug,
          status: 'failed_no_matching_product',
          reason:
              'no active product in public.products has slug "$slug" '
              '(fresh query just run)',
        ),
      );
      continue;
    }

    final publicUrl = _publicUrl(host, name);

    if (product.imageCount > 0 || product.existingUrls.contains(publicUrl)) {
      alreadyPresent.add(
        _UploadOutcome(
          slug: slug,
          status: 'already_present',
          productId: product.id,
          reason:
              '${product.name} already has ${product.imageCount} image(s) '
              'in product_images — left untouched',
        ),
      );
      continue;
    }

    Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      failed.add(
        _UploadOutcome(
          slug: slug,
          status: 'failed_read_error',
          productId: product.id,
          reason: 'could not read local file: $e',
        ),
      );
      continue;
    }

    final problem = _basicImageProblem(bytes);
    if (problem != null) {
      failed.add(
        _UploadOutcome(
          slug: slug,
          status: 'failed_invalid_image',
          productId: product.id,
          reason: problem,
        ),
      );
      continue;
    }

    if (!execute) {
      uploaded.add(
        _UploadOutcome(
          slug: slug,
          status: 'would_upload',
          productId: product.id,
          objectKey: name,
          publicUrl: publicUrl,
          bytes: bytes.length,
        ),
      );
      linked.add(
        _UploadOutcome(
          slug: slug,
          status: 'would_link',
          productId: product.id,
          publicUrl: publicUrl,
        ),
      );
      stdout.writeln(
        '[DRY RUN] $slug — would upload $name (${bytes.length} bytes) and '
        'link to ${product.name}',
      );
      continue;
    }

    try {
      final uploadResult = await _uploadObjectToStorage(
        host: host,
        apiKey: apiKey!,
        objectKey: name,
        bytes: bytes,
      );
      if (!uploadResult.ok) {
        failed.add(
          _UploadOutcome(
            slug: slug,
            status: 'failed_upload',
            productId: product.id,
            objectKey: name,
            reason: uploadResult.error,
          ),
        );
        continue;
      }
      uploaded.add(
        _UploadOutcome(
          slug: slug,
          status: 'uploaded',
          productId: product.id,
          objectKey: name,
          publicUrl: publicUrl,
          bytes: bytes.length,
        ),
      );
      stdout.writeln('[UPLOADED] $slug -> $name');
    } catch (e) {
      failed.add(
        _UploadOutcome(
          slug: slug,
          status: 'failed_upload',
          productId: product.id,
          objectKey: name,
          reason: 'upload request error: $e',
        ),
      );
      continue;
    }

    try {
      final linkResult = await _insertProductImageRow(
        host: host,
        apiKey: apiKey,
        productId: product.id,
        url: publicUrl,
      );
      if (!linkResult.ok) {
        failed.add(
          _UploadOutcome(
            slug: slug,
            status: 'failed_link_after_upload',
            productId: product.id,
            objectKey: name,
            publicUrl: publicUrl,
            reason:
                'Storage upload succeeded but the product_images insert '
                'failed: ${linkResult.error}. The uploaded object was left '
                'in place (nothing is ever deleted); re-running upload-images '
                'will treat it as already_present only once a product_images '
                'row exists for it.',
          ),
        );
        continue;
      }
      linked.add(
        _UploadOutcome(
          slug: slug,
          status: 'linked',
          productId: product.id,
          publicUrl: publicUrl,
        ),
      );
      stdout.writeln('[LINKED] $slug -> product_images row created');
    } catch (e) {
      failed.add(
        _UploadOutcome(
          slug: slug,
          status: 'failed_link_after_upload',
          productId: product.id,
          objectKey: name,
          publicUrl: publicUrl,
          reason:
              'Storage upload succeeded but the product_images insert threw: '
              '$e',
        ),
      );
    }
  }

  final report = {
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'dry_run': !execute,
    'bucket': _bucketName,
    'images_dir': _imagesDir,
    'protected_object_key': _protectedObjectKey,
    'catalog_source':
        'fresh read-only SELECT via `supabase db query --linked` — '
        'tool/catalog_snapshot.json was not used',
    'total_local_files_scanned': files.length,
    'uploaded': [for (final o in uploaded) o.toJson()],
    'already_present': [for (final o in alreadyPresent) o.toJson()],
    'linked': [for (final o in linked) o.toJson()],
    'skipped': [for (final o in skipped) o.toJson()],
    'failed': [for (final o in failed) o.toJson()],
    'errors': errors,
    'summary': {
      'uploaded_count': uploaded.length,
      'already_present_count': alreadyPresent.length,
      'linked_count': linked.length,
      'skipped_count': skipped.length,
      'failed_count': failed.length,
    },
  };

  await Directory(_outputDir).create(recursive: true);
  await File(
    _uploadReportPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));

  stdout
    ..writeln('')
    ..writeln(
      '--- upload-images summary '
      '(${execute ? "EXECUTED" : "DRY RUN — nothing written"}) ---',
    )
    ..writeln('${execute ? "Uploaded" : "Would upload"}: ${uploaded.length}')
    ..writeln('Already present (skipped): ${alreadyPresent.length}')
    ..writeln('${execute ? "Linked" : "Would link"}: ${linked.length}')
    ..writeln('Skipped (other): ${skipped.length}')
    ..writeln('Failed: ${failed.length}')
    ..writeln('Report: $_uploadReportPath');

  if (!execute) {
    stdout.writeln(
      '\nThis was a DRY RUN. No Storage uploads or database writes were '
      'made. Re-run with --execute to perform them for real.',
    );
  }
}
