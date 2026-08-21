// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TopBuy Deals';

  @override
  String get todaysPromotion => 'OFERTA DEL DÍA 🔥';

  @override
  String get findBestPrices =>
      'Encuentra las mejores ofertas\n¡a precios increíbles!';

  @override
  String get popularProducts => 'Productos Populares';

  @override
  String addedToCart(String productName) {
    return '$productName añadido al carrito';
  }

  @override
  String get homePage => 'Inicio';

  @override
  String get categories => 'Categorías';

  @override
  String get favorites => 'Favoritos';

  @override
  String get profile => 'Perfil';

  @override
  String get electronics => 'Electrónica';

  @override
  String get clothing => 'Ropa';

  @override
  String get accessories => 'Accesorios';

  @override
  String get homeGoods => 'Hogar y Decoración';

  @override
  String get sports => 'Deportes y Aire Libre';

  @override
  String get cosmetics => 'Belleza y Cuidado Personal';

  @override
  String get noFavoriteProducts => 'Aún no tienes productos favoritos ❤️';

  @override
  String get profileSection => 'Mi Perfil';

  @override
  String get noCategoryProducts =>
      'No hay productos disponibles en esta categoría';

  @override
  String get addToCart => 'Añadir al carrito';

  @override
  String get product => 'Detalles del Producto';

  @override
  String get currency => '\$';

  @override
  String get discount => 'Ahorra';

  @override
  String get addToCartFull => 'Añadir al carrito';

  @override
  String get cart => 'Carrito de Compras';

  @override
  String get emptyCart => 'Tu carrito está vacío';

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
    return 'Ahorra $percent%';
  }

  @override
  String get language => 'Idioma';

  @override
  String get searchProducts => 'Buscar productos...';

  @override
  String get noResultsFound => 'No se encontraron resultados';

  @override
  String get recentSearches => 'Búsquedas Recientes';

  @override
  String get popularSearches => 'Búsquedas Populares';

  @override
  String get filter => 'Filtrar';

  @override
  String get sortBy => 'Ordenar por';

  @override
  String get priceRange => 'Rango de Precio';

  @override
  String get rating => 'Valoración';

  @override
  String get availability => 'Disponibilidad';

  @override
  String get brand => 'Marca';

  @override
  String get apply => 'Aplicar';

  @override
  String get clear => 'Limpiar';

  @override
  String get relevance => 'Relevancia';

  @override
  String get priceLowToHigh => 'Precio: Menor a Mayor';

  @override
  String get priceHighToLow => 'Precio: Mayor a Menor';

  @override
  String get newest => 'Más Nuevo';

  @override
  String get popularity => 'Popularidad';

  @override
  String get todaysDeals => 'Ofertas de Hoy';

  @override
  String get flashDeals => 'Ofertas Relámpago';

  @override
  String get priceDrops => 'Bajadas de Precio';

  @override
  String get limitedTime => 'Tiempo Limitado';

  @override
  String get dealEndsIn => 'La oferta termina en';

  @override
  String get reviews => 'Reseñas';

  @override
  String get inStock => 'En Stock';

  @override
  String get lowStock => 'Stock Bajo';

  @override
  String get outOfStock => 'Agotado';

  @override
  String get freeShipping => 'Envío Gratis';

  @override
  String get specifications => 'Especificaciones';

  @override
  String get features => 'Características';

  @override
  String get recentlyViewed => 'Vistos Recientemente';

  @override
  String get continueShopping => 'Continuar Comprando';

  @override
  String get bestSeller => 'Más Vendido';

  @override
  String get trending => 'Tendencia';

  @override
  String get newArrival => 'Recién Llegado';

  @override
  String get flashSale => 'Venta Relámpago';

  @override
  String get priceDrop => 'Bajada de Precio';

  @override
  String reviewsCount(int count) {
    return '$count reseñas';
  }

  @override
  String get productDetails => 'Detalles del Producto';

  @override
  String get description => 'Descripción';

  @override
  String get keyFeatures => 'Características Clave';

  @override
  String get shippingInfo => 'Información de Envío';

  @override
  String get estimatedDelivery => 'Entrega Estimada';

  @override
  String get soldBy => 'Vendido por';

  @override
  String get addedToWishlist => 'Añadido a favoritos';

  @override
  String get removedFromWishlist => 'Eliminado de favoritos';

  @override
  String get buyNow => 'Comprar Ahora';

  @override
  String get share => 'Compartir';

  @override
  String get relatedProducts => 'Productos Relacionados';

  @override
  String get similarDeals => 'Ofertas Similares';

  @override
  String get youMayAlsoLike => 'También te Puede Gustar';

  @override
  String get customerReviews => 'Opiniones de Clientes';

  @override
  String get ratingDistribution => 'Distribución de Valoraciones';

  @override
  String get writeReview => 'Escribir una Reseña';

  @override
  String get productInfo => 'Información del Producto';

  @override
  String get sku => 'SKU';

  @override
  String deliveryIn(String days) {
    return 'Entrega en $days días';
  }

  @override
  String unitsInStock(int count) {
    return '$count unidades en stock';
  }

  @override
  String onlyLeft(int count) {
    return '¡Solo quedan $count!';
  }

  @override
  String selectVariant(String variant) {
    return 'Seleccionar $variant';
  }

  @override
  String get color => 'Color';

  @override
  String get size => 'Talla';

  @override
  String get quantity => 'Cantidad';

  @override
  String get search => 'Buscar';

  @override
  String get searchHint => 'Buscar productos, marcas, ofertas...';

  @override
  String get searchResults => 'Resultados de Búsqueda';

  @override
  String resultsFor(String query) {
    return 'Resultados para \"$query\"';
  }

  @override
  String get noResults => 'No se encontraron productos';

  @override
  String noResultsFor(String query) {
    return 'No hay resultados para \"$query\"';
  }

  @override
  String get tryDifferentSearch =>
      'Intenta buscar con diferentes palabras clave';

  @override
  String get filters => 'Filtros';

  @override
  String get applyFilters => 'Aplicar Filtros';

  @override
  String get clearFilters => 'Limpiar Todo';

  @override
  String get filterBy => 'Filtrar por';

  @override
  String get category => 'Categoría';

  @override
  String get allCategories => 'Todas las Categorías';

  @override
  String get priceMin => 'Precio Mínimo';

  @override
  String get priceMax => 'Precio Máximo';

  @override
  String get minRating => 'Valoración Mínima';

  @override
  String starsAndUp(int stars) {
    return '$stars estrellas y más';
  }

  @override
  String get minDiscount => 'Descuento Mínimo';

  @override
  String discountAndUp(int discount) {
    return '$discount% y más';
  }

  @override
  String get inStockOnly => 'Solo en Stock';

  @override
  String get dealsOnly => 'Solo Ofertas';

  @override
  String get sort => 'Ordenar';

  @override
  String get sortByLabel => 'Ordenar por:';

  @override
  String productCount(int count) {
    return '$count productos';
  }

  @override
  String activeFilters(int count) {
    return '$count activos';
  }

  @override
  String get recentSearchesLabel => 'Búsquedas Recientes';

  @override
  String get clearSearchHistory => 'Borrar Historial';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get todaysDealsTitle => 'Ofertas de Hoy';

  @override
  String get biggestDiscountsTitle => 'Mayores Descuentos';

  @override
  String get flashDealsTitle => 'Ofertas Relámpago';

  @override
  String get trendingDealsTitle => 'Ofertas Populares';

  @override
  String get priceDropsTitle => 'Bajadas de Precio';

  @override
  String get recentlyViewedTitle => 'Vistos Recientemente';

  @override
  String get recommendedTitle => 'Recomendado Para Ti';

  @override
  String get bestSellersTitle => 'Más Vendidos';

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get seeMore => 'Ver Más';

  @override
  String get save => 'Ahorra';

  @override
  String savingsAmount(String amount) {
    return 'Ahorra $amount';
  }

  @override
  String get upTo => 'Hasta';

  @override
  String get off => 'DESC';

  @override
  String get dealOfTheDay => 'Oferta del Día';

  @override
  String get limitedQuantity => 'Cantidad Limitada';

  @override
  String get hurry => '¡Date Prisa!';

  @override
  String get almostGone => '¡Casi Agotado!';

  @override
  String get login => 'Iniciar Sesión';

  @override
  String get signUp => 'Registrarse';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get password => 'Contraseña';

  @override
  String get fullName => 'Nombre Completo';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get emailHint => 'Ingrese su correo electrónico';

  @override
  String get passwordHint => 'Ingrese su contraseña';

  @override
  String get fullNameHint => 'Ingrese su nombre completo';

  @override
  String get confirmPasswordHint => 'Vuelva a ingresar su contraseña';

  @override
  String get emailRequired => 'El correo electrónico es obligatorio';

  @override
  String get emailInvalid => 'Ingrese un correo electrónico válido';

  @override
  String get passwordRequired => 'La contraseña es obligatoria';

  @override
  String get passwordTooShort =>
      'La contraseña debe tener al menos 6 caracteres';

  @override
  String get nameRequired => 'El nombre es obligatorio';

  @override
  String get nameTooShort => 'El nombre debe tener al menos 2 caracteres';

  @override
  String get confirmPasswordRequired => 'Por favor confirme su contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get welcomeBack => '¡Bienvenido de Nuevo!';

  @override
  String get loginSubtitle => 'Inicie sesión para continuar comprando';

  @override
  String get loginSuccess => 'Sesión iniciada correctamente';

  @override
  String get loginError =>
      'Error al iniciar sesión. Verifique sus credenciales.';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get signUpSubtitle => 'Únase a TOPBUY DEALS hoy';

  @override
  String get signUpSuccess => '¡Cuenta creada exitosamente!';

  @override
  String get signUpError => 'Error al registrarse. Inténtelo de nuevo.';

  @override
  String get forgotPassword => '¿Olvidó su Contraseña?';

  @override
  String get resetPassword => 'Restablecer Contraseña';

  @override
  String get sendResetLink => 'Enviar Enlace';

  @override
  String get resetPasswordDescription =>
      'Ingrese su correo electrónico y le enviaremos un enlace para restablecer su contraseña';

  @override
  String get resetPasswordEmailSent => '¡Correo de restablecimiento enviado!';

  @override
  String get resetPasswordEmailSentDescription =>
      'Hemos enviado un enlace de restablecimiento a su correo. Revise su bandeja de entrada y siga las instrucciones.';

  @override
  String get resetPasswordError =>
      'Error al enviar correo. Inténtelo de nuevo.';

  @override
  String get resetPasswordHelpText =>
      '¿No recibió el correo? Revise su carpeta de spam o intente reenviar.';

  @override
  String get checkYourEmail => 'Revise su Correo';

  @override
  String get resendEmail => 'Reenviar Correo';

  @override
  String resendIn(int seconds) {
    return 'Reenviar en ${seconds}s';
  }

  @override
  String get backToLogin => 'Volver a Iniciar Sesión';

  @override
  String get or => 'O';

  @override
  String get dontHaveAccount => '¿No tiene una cuenta?';

  @override
  String get alreadyHaveAccount => '¿Ya tiene una cuenta?';

  @override
  String get passwordWeak => 'Débil';

  @override
  String get passwordMedium => 'Media';

  @override
  String get passwordStrong => 'Fuerte';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get myAccount => 'Mi Cuenta';

  @override
  String get accountSettings => 'Configuración de Cuenta';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get signedInAs => 'Sesión iniciada como';

  @override
  String get guest => 'Invitado';

  @override
  String get signInToSeeMore => 'Inicie sesión para acceder a más funciones';

  @override
  String get phoneNumber => 'Número de Teléfono';

  @override
  String get phoneNumberHint => 'Ingrese su número de teléfono';

  @override
  String get phoneNumberInvalid => 'Ingrese un número de teléfono válido';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get cancel => 'Cancelar';

  @override
  String get profileUpdated => 'Perfil actualizado exitosamente';

  @override
  String get profileUpdateFailed => 'Error al actualizar el perfil';

  @override
  String get personalInformation => 'Información Personal';

  @override
  String get preferences => 'Preferencias';

  @override
  String get currencyPreference => 'Moneda';

  @override
  String get languagePreference => 'Idioma';

  @override
  String get optional => 'Opcional';

  @override
  String get continueWhereLeftOff => 'Continúa donde lo dejaste';

  @override
  String get savingsUpTo => 'Ahorra hasta 50% de DESCUENTO';

  @override
  String get limitedTimeOffers => 'Ofertas por tiempo limitado';

  @override
  String get bestDealsNow => 'Mejores ofertas disponibles ahora';

  @override
  String get mostLovedItems => 'Compra nuestros artículos más queridos';

  @override
  String get updatePersonalInfo => 'Actualiza tu información personal';

  @override
  String get confirmSignOut => '¿Estás seguro de que quieres cerrar sesión?';

  @override
  String get signedOutSuccess => 'Sesión cerrada exitosamente';
}
