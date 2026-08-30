// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TopBuy Deals';

  @override
  String get todaysPromotion => 'OFFRE DU JOUR 🔥';

  @override
  String get findBestPrices =>
      'Trouvez les meilleures offres\nà prix incroyables !';

  @override
  String get popularProducts => 'Produits Populaires';

  @override
  String addedToCart(String productName) {
    return '$productName ajouté au panier';
  }

  @override
  String get homePage => 'Accueil';

  @override
  String get categories => 'Catégories';

  @override
  String get favorites => 'Favoris';

  @override
  String get profile => 'Profil';

  @override
  String get electronics => 'Électronique';

  @override
  String get clothing => 'Vêtements';

  @override
  String get accessories => 'Accessoires';

  @override
  String get homeGoods => 'Maison & Décoration';

  @override
  String get sports => 'Sports & Plein Air';

  @override
  String get cosmetics => 'Beauté & Soins';

  @override
  String get noFavoriteProducts => 'Aucun produit favori pour le moment ❤️';

  @override
  String get profileSection => 'Mon Profil';

  @override
  String get noCategoryProducts =>
      'Aucun produit disponible dans cette catégorie';

  @override
  String get addToCart => 'Ajouter au panier';

  @override
  String get product => 'Détails du Produit';

  @override
  String get currency => '\$';

  @override
  String get discount => 'Économisez';

  @override
  String get addToCartFull => 'Ajouter au panier';

  @override
  String get cart => 'Panier';

  @override
  String get emptyCart => 'Votre panier est vide';

  @override
  String priceWithCurrency(String price) {
    return '$price';
  }

  @override
  String discountPercent(int percent) {
    return '-$percent%';
  }

  @override
  String discountValue(int percent) {
    return 'Économisez $percent%';
  }

  @override
  String get language => 'Langue';

  @override
  String get searchProducts => 'Rechercher des produits...';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get recentSearches => 'Recherches Récentes';

  @override
  String get popularSearches => 'Recherches Populaires';

  @override
  String get filter => 'Filtrer';

  @override
  String get sortBy => 'Trier par';

  @override
  String get priceRange => 'Plage de Prix';

  @override
  String get rating => 'Note';

  @override
  String get availability => 'Disponibilité';

  @override
  String get brand => 'Marque';

  @override
  String get apply => 'Appliquer';

  @override
  String get clear => 'Effacer';

  @override
  String get relevance => 'Pertinence';

  @override
  String get priceLowToHigh => 'Prix : Croissant';

  @override
  String get priceHighToLow => 'Prix : Décroissant';

  @override
  String get newest => 'Plus Récent';

  @override
  String get popularity => 'Popularité';

  @override
  String get todaysDeals => 'Offres du Jour';

  @override
  String get flashDeals => 'Ventes Flash';

  @override
  String get priceDrops => 'Baisses de Prix';

  @override
  String get limitedTime => 'Temps Limité';

  @override
  String get dealEndsIn => 'L\'offre se termine dans';

  @override
  String get reviews => 'Avis';

  @override
  String get inStock => 'En Stock';

  @override
  String get lowStock => 'Stock Faible';

  @override
  String get outOfStock => 'Rupture de Stock';

  @override
  String get freeShipping => 'Livraison Gratuite';

  @override
  String get specifications => 'Spécifications';

  @override
  String get features => 'Caractéristiques';

  @override
  String get recentlyViewed => 'Récemment Consultés';

  @override
  String get continueShopping => 'Continuer vos Achats';

  @override
  String get bestSeller => 'Meilleure Vente';

  @override
  String get trending => 'Tendance';

  @override
  String get newArrival => 'Nouveauté';

  @override
  String get flashSale => 'Vente Flash';

  @override
  String get priceDrop => 'Baisse de Prix';

  @override
  String reviewsCount(int count) {
    return '$count avis';
  }

  @override
  String get productDetails => 'Détails du Produit';

  @override
  String get description => 'Description';

  @override
  String get keyFeatures => 'Caractéristiques Principales';

  @override
  String get shippingInfo => 'Informations de Livraison';

  @override
  String get estimatedDelivery => 'Livraison Estimée';

  @override
  String get soldBy => 'Vendu par';

  @override
  String get addedToWishlist => 'Ajouté aux favoris';

  @override
  String get removedFromWishlist => 'Retiré des favoris';

  @override
  String get buyNow => 'Acheter Maintenant';

  @override
  String get share => 'Partager';

  @override
  String get relatedProducts => 'Produits Connexes';

  @override
  String get similarDeals => 'Offres Similaires';

  @override
  String get youMayAlsoLike => 'Vous Aimerez Aussi';

  @override
  String get customerReviews => 'Avis des Clients';

  @override
  String get ratingDistribution => 'Répartition des Notes';

  @override
  String get writeReview => 'Écrire un Avis';

  @override
  String get productInfo => 'Informations sur le Produit';

  @override
  String get sku => 'SKU';

  @override
  String deliveryIn(String days) {
    return 'Livraison en $days jours';
  }

  @override
  String unitsInStock(int count) {
    return '$count unités en stock';
  }

  @override
  String onlyLeft(int count) {
    return 'Plus que $count !';
  }

  @override
  String selectVariant(String variant) {
    return 'Sélectionner $variant';
  }

  @override
  String get color => 'Couleur';

  @override
  String get size => 'Taille';

  @override
  String get quantity => 'Quantité';

  @override
  String get search => 'Rechercher';

  @override
  String get searchHint => 'Rechercher des produits, marques, offres...';

  @override
  String get searchResults => 'Résultats de Recherche';

  @override
  String resultsFor(String query) {
    return 'Résultats pour \"$query\"';
  }

  @override
  String get noResults => 'Aucun produit trouvé';

  @override
  String noResultsFor(String query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get tryDifferentSearch =>
      'Essayez de rechercher avec d\'autres mots-clés';

  @override
  String get filters => 'Filtres';

  @override
  String get applyFilters => 'Appliquer les Filtres';

  @override
  String get clearFilters => 'Tout Effacer';

  @override
  String get filterBy => 'Filtrer par';

  @override
  String get category => 'Catégorie';

  @override
  String get allCategories => 'Toutes les Catégories';

  @override
  String get priceMin => 'Prix Minimum';

  @override
  String get priceMax => 'Prix Maximum';

  @override
  String get minRating => 'Note Minimale';

  @override
  String starsAndUp(int stars) {
    return '$stars étoiles et plus';
  }

  @override
  String get minDiscount => 'Réduction Minimale';

  @override
  String discountAndUp(int discount) {
    return '$discount% et plus';
  }

  @override
  String get inStockOnly => 'En Stock Seulement';

  @override
  String get dealsOnly => 'Offres Seulement';

  @override
  String get sort => 'Trier';

  @override
  String get sortByLabel => 'Trier par :';

  @override
  String productCount(int count) {
    return '$count produits';
  }

  @override
  String activeFilters(int count) {
    return '$count actifs';
  }

  @override
  String get recentSearchesLabel => 'Recherches Récentes';

  @override
  String get clearSearchHistory => 'Effacer l\'Historique';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get todaysDealsTitle => 'Offres du Jour';

  @override
  String get biggestDiscountsTitle => 'Plus Grandes Réductions';

  @override
  String get flashDealsTitle => 'Ventes Flash';

  @override
  String get trendingDealsTitle => 'Offres Tendance';

  @override
  String get priceDropsTitle => 'Baisses de Prix';

  @override
  String get recentlyViewedTitle => 'Récemment Consultés';

  @override
  String get recommendedTitle => 'Recommandé Pour Vous';

  @override
  String get bestSellersTitle => 'Meilleures Ventes';

  @override
  String get viewAll => 'Voir Tout';

  @override
  String get seeMore => 'Voir Plus';

  @override
  String get save => 'Économisez';

  @override
  String savingsAmount(String amount) {
    return 'Économisez $amount';
  }

  @override
  String get upTo => 'Jusqu\'à';

  @override
  String get off => 'RÉDUC';

  @override
  String get dealOfTheDay => 'Offre du Jour';

  @override
  String get limitedQuantity => 'Quantité Limitée';

  @override
  String get hurry => 'Dépêchez-vous !';

  @override
  String get almostGone => 'Presque Épuisé !';

  @override
  String get login => 'Connexion';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get logout => 'Déconnexion';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de Passe';

  @override
  String get fullName => 'Nom Complet';

  @override
  String get confirmPassword => 'Confirmer le Mot de Passe';

  @override
  String get emailHint => 'Entrez votre email';

  @override
  String get passwordHint => 'Entrez votre mot de passe';

  @override
  String get fullNameHint => 'Entrez votre nom complet';

  @override
  String get confirmPasswordHint => 'Ré-entrez votre mot de passe';

  @override
  String get emailRequired => 'L\'email est requis';

  @override
  String get emailInvalid => 'Entrez une adresse email valide';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get nameTooShort => 'Le nom doit contenir au moins 2 caractères';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get welcomeBack => 'Bon Retour !';

  @override
  String get loginSubtitle => 'Connectez-vous pour continuer vos achats';

  @override
  String get loginSuccess => 'Connexion réussie';

  @override
  String get loginError => 'Échec de connexion. Vérifiez vos identifiants.';

  @override
  String get createAccount => 'Créer un Compte';

  @override
  String get signUpSubtitle => 'Rejoignez TOPBUY DEALS aujourd\'hui';

  @override
  String get signUpSuccess => 'Compte créé avec succès !';

  @override
  String get signUpError => 'Échec de l\'inscription. Réessayez.';

  @override
  String get forgotPassword => 'Mot de Passe Oublié ?';

  @override
  String get resetPassword => 'Réinitialiser le Mot de Passe';

  @override
  String get sendResetLink => 'Envoyer le Lien';

  @override
  String get resetPasswordDescription =>
      'Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe';

  @override
  String get resetPasswordEmailSent => 'Email de réinitialisation envoyé !';

  @override
  String get resetPasswordEmailSentDescription =>
      'Nous avons envoyé un lien de réinitialisation à votre email. Vérifiez votre boîte de réception et suivez les instructions.';

  @override
  String get resetPasswordError => 'Échec de l\'envoi de l\'email. Réessayez.';

  @override
  String get resetPasswordHelpText =>
      'Vous n\'avez pas reçu l\'email ? Vérifiez votre dossier spam ou réessayez d\'envoyer.';

  @override
  String get checkYourEmail => 'Vérifiez Votre Email';

  @override
  String get resendEmail => 'Renvoyer l\'Email';

  @override
  String resendIn(int seconds) {
    return 'Renvoyer dans ${seconds}s';
  }

  @override
  String get backToLogin => 'Retour à la Connexion';

  @override
  String get or => 'OU';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ?';

  @override
  String get passwordWeak => 'Faible';

  @override
  String get passwordMedium => 'Moyen';

  @override
  String get passwordStrong => 'Fort';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get myAccount => 'Mon Compte';

  @override
  String get accountSettings => 'Paramètres du Compte';

  @override
  String get editProfile => 'Modifier le Profil';

  @override
  String get signedInAs => 'Connecté en tant que';

  @override
  String get guest => 'Invité';

  @override
  String get signInToSeeMore =>
      'Connectez-vous pour accéder à plus de fonctionnalités';

  @override
  String get phoneNumber => 'Numéro de Téléphone';

  @override
  String get phoneNumberHint => 'Entrez votre numéro de téléphone';

  @override
  String get phoneNumberInvalid => 'Entrez un numéro de téléphone valide';

  @override
  String get saveChanges => 'Enregistrer les Modifications';

  @override
  String get cancel => 'Annuler';

  @override
  String get profileUpdated => 'Profil mis à jour avec succès';

  @override
  String get profileUpdateFailed => 'Échec de la mise à jour du profil';

  @override
  String get personalInformation => 'Informations Personnelles';

  @override
  String get preferences => 'Préférences';

  @override
  String get currencyPreference => 'Devise';

  @override
  String get languagePreference => 'Langue';

  @override
  String get optional => 'Facultatif';

  @override
  String get continueWhereLeftOff => 'Continuez où vous vous êtes arrêté';

  @override
  String get savingsUpTo => 'Économisez jusqu\'à 50% DE RÉDUCTION';

  @override
  String get limitedTimeOffers => 'Offres à durée limitée';

  @override
  String get bestDealsNow => 'Meilleures offres disponibles maintenant';

  @override
  String get mostLovedItems => 'Achetez nos articles les plus aimés';

  @override
  String get updatePersonalInfo =>
      'Mettez à jour vos informations personnelles';

  @override
  String get confirmSignOut => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get signedOutSuccess => 'Déconnexion réussie';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimer définitivement votre compte et vos données';

  @override
  String get deleteAccountConfirmTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountConfirmMessage =>
      'Cette action supprimera définitivement votre compte, votre profil et toutes les données associées. Cette action est irréversible.';

  @override
  String get deleteAccountConfirmButton => 'Supprimer définitivement';

  @override
  String get deleteAccountSuccess =>
      'Votre compte a été définitivement supprimé';

  @override
  String get deleteAccountFailed => 'Échec de la suppression du compte';
}
