// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'TopBuy Deals';

  @override
  String get todaysPromotion => 'BUGUNGI AKSIYA 🔥';

  @override
  String get findBestPrices => 'Eng yaxshi narxlarni\nTopBuy Deals\'da toping!';

  @override
  String get popularProducts => 'Mashhur mahsulotlar';

  @override
  String addedToCart(String productName) {
    return '$productName savatchaga qo\'shildi';
  }

  @override
  String get homePage => 'Bosh sahifa';

  @override
  String get categories => 'Kategoriyalar';

  @override
  String get favorites => 'Saralangan';

  @override
  String get profile => 'Profil';

  @override
  String get electronics => 'Elektronika';

  @override
  String get clothing => 'Kiyim';

  @override
  String get accessories => 'Aksessuar';

  @override
  String get homeGoods => 'Uy uchun';

  @override
  String get sports => 'Sport';

  @override
  String get cosmetics => 'Kosmetika';

  @override
  String get noFavoriteProducts => 'Saralangan mahsulotlar yo\'q ❤️';

  @override
  String get profileSection => 'Profil bo\'limi';

  @override
  String get noCategoryProducts => 'Bu kategoriyada mahsulot yo\'q';

  @override
  String get addToCart => 'Savatchaga';

  @override
  String get product => 'Mahsulot';

  @override
  String get currency => 'so\'m';

  @override
  String get discount => 'Chegirma';

  @override
  String get addToCartFull => 'Savatchaga qo\'shish';

  @override
  String get cart => 'Savatcha';

  @override
  String get emptyCart => 'Savatcha bo\'sh';

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
    return 'Chegirma: $percent%';
  }

  @override
  String get language => 'Til';

  @override
  String get searchProducts => 'Mahsulotlarni qidirish...';

  @override
  String get noResultsFound => 'Natija topilmadi';

  @override
  String get recentSearches => 'Oxirgi qidiruvlar';

  @override
  String get popularSearches => 'Mashhur qidiruvlar';

  @override
  String get filter => 'Filtr';

  @override
  String get sortBy => 'Saralash';

  @override
  String get priceRange => 'Narx oralig\'i';

  @override
  String get rating => 'Baho';

  @override
  String get availability => 'Mavjudligi';

  @override
  String get brand => 'Brend';

  @override
  String get apply => 'Qo\'llash';

  @override
  String get clear => 'Tozalash';

  @override
  String get relevance => 'Mos keladigan';

  @override
  String get priceLowToHigh => 'Narx: arzondan qimmmatga';

  @override
  String get priceHighToLow => 'Narx: qimmatdan arzonga';

  @override
  String get newest => 'Yangilari';

  @override
  String get popularity => 'Ommabopligi';

  @override
  String get todaysDeals => 'Bugungi takliflar';

  @override
  String get flashDeals => 'Tezkor takliflar';

  @override
  String get priceDrops => 'Narx tushirildi';

  @override
  String get limitedTime => 'Cheklangan vaqt';

  @override
  String get dealEndsIn => 'Taklif tugashi';

  @override
  String get reviews => 'Sharhlar';

  @override
  String get inStock => 'Mavjud';

  @override
  String get lowStock => 'Kam qoldi';

  @override
  String get outOfStock => 'Tugadi';

  @override
  String get freeShipping => 'Bepul yetkazib berish';

  @override
  String get specifications => 'Xususiyatlari';

  @override
  String get features => 'Imkoniyatlari';

  @override
  String get recentlyViewed => 'Ko\'rilganlar';

  @override
  String get continueShopping => 'Xaridni davom ettirish';

  @override
  String get bestSeller => 'Eng ko\'p sotiladigan';

  @override
  String get trending => 'Trend';

  @override
  String get newArrival => 'Yangi kelgan';

  @override
  String get flashSale => 'Tezkor sotuv';

  @override
  String get priceDrop => 'Narx tushirildi';

  @override
  String reviewsCount(int count) {
    return '$count ta sharh';
  }

  @override
  String get productDetails => 'Mahsulot ma\'lumotlari';

  @override
  String get description => 'Tavsif';

  @override
  String get keyFeatures => 'Asosiy xususiyatlar';

  @override
  String get shippingInfo => 'Yetkazib berish haqida';

  @override
  String get estimatedDelivery => 'Taxminiy yetkazilish';

  @override
  String get soldBy => 'Sotuvchi';

  @override
  String get addedToWishlist => 'Saralanganlar ro\'yxatiga qo\'shildi';

  @override
  String get removedFromWishlist => 'Saralanganlar ro\'yxatidan o\'chirildi';

  @override
  String get buyNow => 'Hozir xarid qilish';

  @override
  String get share => 'Ulashish';

  @override
  String get relatedProducts => 'Bog\'liq mahsulotlar';

  @override
  String get similarDeals => 'O\'xshash takliflar';

  @override
  String get youMayAlsoLike => 'Sizga yoqishi mumkin';

  @override
  String get customerReviews => 'Mijozlar sharhlari';

  @override
  String get ratingDistribution => 'Baholash taqsimoti';

  @override
  String get writeReview => 'Sharh yozish';

  @override
  String get productInfo => 'Mahsulot ma\'lumoti';

  @override
  String get sku => 'SKU';

  @override
  String deliveryIn(String days) {
    return '$days kunda yetkaziladi';
  }

  @override
  String unitsInStock(int count) {
    return '$count dona mavjud';
  }

  @override
  String onlyLeft(int count) {
    return 'Faqat $count ta qoldi!';
  }

  @override
  String selectVariant(String variant) {
    return '$variant tanlang';
  }

  @override
  String get color => 'Rang';

  @override
  String get size => 'O\'lcham';

  @override
  String get quantity => 'Miqdor';

  @override
  String get cartSubtotal => 'Oraliq summa';

  @override
  String get search => 'Qidirish';

  @override
  String get searchHint => 'Mahsulot, brend, takliflarni qidirish...';

  @override
  String get searchResults => 'Qidiruv natijalari';

  @override
  String resultsFor(String query) {
    return '\"$query\" uchun natijalar';
  }

  @override
  String get noResults => 'Mahsulot topilmadi';

  @override
  String noResultsFor(String query) {
    return '\"$query\" uchun natija yo\'q';
  }

  @override
  String get tryDifferentSearch => 'Boshqa kalit so\'zlar bilan qidiring';

  @override
  String get filters => 'Filtrlar';

  @override
  String get applyFilters => 'Filtrlarni qo\'llash';

  @override
  String get clearFilters => 'Hammasini tozalash';

  @override
  String get filterBy => 'Filtr';

  @override
  String get category => 'Kategoriya';

  @override
  String get allCategories => 'Barcha kategoriyalar';

  @override
  String get priceMin => 'Minimal narx';

  @override
  String get priceMax => 'Maksimal narx';

  @override
  String get minRating => 'Minimal baho';

  @override
  String starsAndUp(int stars) {
    return '$stars yulduz va yuqori';
  }

  @override
  String get minDiscount => 'Minimal chegirma';

  @override
  String discountAndUp(int discount) {
    return '$discount% va yuqori';
  }

  @override
  String get inStockOnly => 'Faqat mavjud';

  @override
  String get dealsOnly => 'Faqat takliflar';

  @override
  String get sort => 'Saralash';

  @override
  String get sortByLabel => 'Saralash:';

  @override
  String productCount(int count) {
    return '$count ta mahsulot';
  }

  @override
  String activeFilters(int count) {
    return '$count ta faol';
  }

  @override
  String get recentSearchesLabel => 'Oxirgi qidiruvlar';

  @override
  String get clearSearchHistory => 'Tarixni tozalash';

  @override
  String get suggestions => 'Takliflar';

  @override
  String get todaysDealsTitle => 'Bugungi takliflar';

  @override
  String get biggestDiscountsTitle => 'Eng katta chegirmalar';

  @override
  String get flashDealsTitle => 'Tezkor takliflar';

  @override
  String get trendingDealsTitle => 'Mashhur takliflar';

  @override
  String get priceDropsTitle => 'Narx tushirildi';

  @override
  String get recentlyViewedTitle => 'Ko\'rilganlar';

  @override
  String get recommendedTitle => 'Siz uchun tavsiya';

  @override
  String get bestSellersTitle => 'Eng ko\'p sotilgan';

  @override
  String get viewAll => 'Hammasini ko\'rish';

  @override
  String get seeMore => 'Ko\'proq';

  @override
  String get save => 'Tejash';

  @override
  String savingsAmount(String amount) {
    return '$amount tejang';
  }

  @override
  String get upTo => 'Gacha';

  @override
  String get off => 'CHEG';

  @override
  String get dealOfTheDay => 'Kun taklifi';

  @override
  String get limitedQuantity => 'Cheklangan miqdor';

  @override
  String get hurry => 'Shoshiling!';

  @override
  String get almostGone => 'Deyarli tugadi!';

  @override
  String get login => 'Kirish';

  @override
  String get signUp => 'Ro\'yxatdan o\'tish';

  @override
  String get logout => 'Chiqish';

  @override
  String get email => 'Email';

  @override
  String get password => 'Parol';

  @override
  String get fullName => 'To\'liq Ism';

  @override
  String get confirmPassword => 'Parolni Tasdiqlang';

  @override
  String get emailHint => 'Emailingizni kiriting';

  @override
  String get passwordHint => 'Parolingizni kiriting';

  @override
  String get fullNameHint => 'To\'liq ismingizni kiriting';

  @override
  String get confirmPasswordHint => 'Parolni qayta kiriting';

  @override
  String get emailRequired => 'Email talab qilinadi';

  @override
  String get emailInvalid => 'To\'g\'ri email manzilini kiriting';

  @override
  String get passwordRequired => 'Parol talab qilinadi';

  @override
  String get passwordTooShort =>
      'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';

  @override
  String get nameRequired => 'Ism talab qilinadi';

  @override
  String get nameTooShort => 'Ism kamida 2 ta belgidan iborat bo\'lishi kerak';

  @override
  String get confirmPasswordRequired => 'Iltimos parolni tasdiqlang';

  @override
  String get passwordsDoNotMatch => 'Parollar mos kelmaydi';

  @override
  String get welcomeBack => 'Qaytib kelganingizdan xursandmiz!';

  @override
  String get loginSubtitle => 'Xarid qilishni davom ettirish uchun kiring';

  @override
  String get loginSuccess => 'Muvaffaqiyatli kirildi';

  @override
  String get loginError => 'Kirish xatosi. Hisobingizni tekshiring.';

  @override
  String get createAccount => 'Hisob Yaratish';

  @override
  String get signUpSubtitle => 'Bugun TOPBUY DEALS ga qo\'shiling';

  @override
  String get signUpSuccess => 'Hisob muvaffaqiyatli yaratildi!';

  @override
  String get signUpConfirmEmail =>
      'Hisob yaratildi! Elektron pochtangizni tekshiring, tasdiqlash havolasini bosing va keyin tizimga kiring.';

  @override
  String get resetPasswordTitle => 'Yangi parol o\'rnating';

  @override
  String get newPassword => 'Yangi parol';

  @override
  String get resetPasswordSubmit => 'Parolni yangilash';

  @override
  String get resetPasswordSuccess => 'Parol muvaffaqiyatli yangilandi!';

  @override
  String get resetPasswordFailed =>
      'Parolni yangilab bo\'lmadi. Havola muddati tugagan bo\'lishi mumkin - yangisini so\'rang.';

  @override
  String get signUpError =>
      'Ro\'yxatdan o\'tish xatosi. Qayta urinib ko\'ring.';

  @override
  String get forgotPassword => 'Parolni Unutdingizmi?';

  @override
  String get resetPassword => 'Parolni Tiklash';

  @override
  String get sendResetLink => 'Havola Yuborish';

  @override
  String get resetPasswordDescription =>
      'Emailingizni kiriting va biz sizga parolni tiklash havolasini yuboramiz';

  @override
  String get resetPasswordEmailSent => 'Parolni tiklash emaili yuborildi!';

  @override
  String get resetPasswordEmailSentDescription =>
      'Emailingizga parolni tiklash havolasini yubordik. Xabar qutisini tekshiring va ko\'rsatmalarga amal qiling.';

  @override
  String get resetPasswordError =>
      'Email yuborishda xatolik. Qayta urinib ko\'ring.';

  @override
  String get resetPasswordHelpText =>
      'Emailni olmadingizmi? Spam papkasini tekshiring yoki qayta yuborishga harakat qiling.';

  @override
  String get checkYourEmail => 'Emailingizni Tekshiring';

  @override
  String get resendEmail => 'Emailni Qayta Yuborish';

  @override
  String resendIn(int seconds) {
    return '${seconds}s ichida qayta yuborish';
  }

  @override
  String get backToLogin => 'Kirishga Qaytish';

  @override
  String get or => 'YOKI';

  @override
  String get dontHaveAccount => 'Hisobingiz yo\'qmi?';

  @override
  String get alreadyHaveAccount => 'Hisobingiz bormi?';

  @override
  String get passwordWeak => 'Zaif';

  @override
  String get passwordMedium => 'O\'rtacha';

  @override
  String get passwordStrong => 'Kuchli';

  @override
  String get signOut => 'Chiqish';

  @override
  String get myAccount => 'Mening Hisobim';

  @override
  String get accountSettings => 'Hisob Sozlamalari';

  @override
  String get editProfile => 'Profilni Tahrirlash';

  @override
  String get signedInAs => 'Sifatida kirilgan';

  @override
  String get guest => 'Mehmon';

  @override
  String get signInToSeeMore =>
      'Ko\'proq xususiyatlardan foydalanish uchun kiring';

  @override
  String get phoneNumber => 'Telefon Raqami';

  @override
  String get phoneNumberHint => 'Telefon raqamingizni kiriting';

  @override
  String get phoneNumberInvalid => 'To\'g\'ri telefon raqamini kiriting';

  @override
  String get saveChanges => 'O\'zgarishlarni Saqlash';

  @override
  String get cancel => 'Bekor Qilish';

  @override
  String get profileUpdated => 'Profil muvaffaqiyatli yangilandi';

  @override
  String get profileUpdateFailed => 'Profilni yangilashda xatolik';

  @override
  String get personalInformation => 'Shaxsiy Ma\'lumotlar';

  @override
  String get preferences => 'Afzalliklar';

  @override
  String get currencyPreference => 'Valyuta';

  @override
  String get languagePreference => 'Til';

  @override
  String get optional => 'Ixtiyoriy';

  @override
  String get continueWhereLeftOff => 'Qayerda to\'xtaganingizdan davom eting';

  @override
  String get savingsUpTo => '50% gacha CHEGIRMADA';

  @override
  String get limitedTimeOffers => 'Cheklangan vaqt takliflari';

  @override
  String get bestDealsNow => 'Hozir mavjud eng yaxshi takliflar';

  @override
  String get mostLovedItems =>
      'Eng yaxshi ko\'rilgan mahsulotlarni xarid qiling';

  @override
  String get updatePersonalInfo => 'Shaxsiy ma\'lumotlaringizni yangilang';

  @override
  String get confirmSignOut => 'Chiqishni xohlaysizmi?';

  @override
  String get signedOutSuccess => 'Muvaffaqiyatli chiqildi';

  @override
  String get deleteAccount => 'Hisobni o\'chirish';

  @override
  String get deleteAccountSubtitle =>
      'Hisobingiz va ma\'lumotlaringizni butunlay o\'chirib tashlang';

  @override
  String get deleteAccountConfirmTitle => 'Hisobni o\'chirasizmi?';

  @override
  String get deleteAccountConfirmMessage =>
      'Bu hisobingizni, profilingizni va unga tegishli barcha ma\'lumotlarni butunlay o\'chirib tashlaydi. Bu amalni qaytarib bo\'lmaydi.';

  @override
  String get deleteAccountConfirmButton => 'Butunlay o\'chirish';

  @override
  String get deleteAccountSuccess => 'Hisobingiz butunlay o\'chirildi';

  @override
  String get deleteAccountFailed => 'Hisobni o\'chirib bo\'lmadi';

  @override
  String get deleteAccountHasOrders =>
      'Hisobingizni o\'chirib bo\'lmaydi, chunki unda mavjud buyurtmalar bor.';

  @override
  String get checkout => 'Buyurtmani rasmiylashtirish';

  @override
  String get proceedToCheckout => 'Buyurtma berish';

  @override
  String get shippingDetails => 'Yetkazib berish ma\'lumotlari';

  @override
  String get fullNameRequired => 'To\'liq ismni kiritish majburiy';

  @override
  String get phone => 'Telefon raqami';

  @override
  String get phoneRequired => 'Telefon raqamini kiritish majburiy';

  @override
  String get streetAddress => 'Ko\'cha manzili';

  @override
  String get streetAddressHint => 'Ko\'cha manzilingizni kiriting';

  @override
  String get streetAddressRequired => 'Ko\'cha manzilini kiritish majburiy';

  @override
  String get city => 'Shahar';

  @override
  String get cityHint => 'Shahringizni kiriting';

  @override
  String get cityRequired => 'Shaharni kiritish majburiy';

  @override
  String get country => 'Mamlakat';

  @override
  String get countryHint => 'Mamlakatingizni kiriting';

  @override
  String get countryRequired => 'Mamlakatni kiritish majburiy';

  @override
  String get orderSummary => 'Buyurtma xulosasi';

  @override
  String get placeOrder => 'Buyurtma berish';

  @override
  String get orderConfirmation => 'Buyurtma tasdiqlandi';

  @override
  String get orderPlacedSuccess => 'Buyurtma muvaffaqiyatli qabul qilindi!';

  @override
  String get orderSuccessMessage =>
      'Xaridingiz uchun rahmat! Buyurtmangiz muvaffaqiyatli rasmiylashtirildi.';

  @override
  String get orderId => 'Buyurtma raqami';

  @override
  String get subtotalUsd => 'Jami (USD)';

  @override
  String get checkoutResetButton => 'Qayta urinish';

  @override
  String get checkoutErrorNotAuthenticated =>
      'Buyurtma berish uchun tizimga kirishingiz kerak.';

  @override
  String get checkoutErrorEmptyCart => 'Savatchangiz bo\'sh.';

  @override
  String get checkoutErrorInvalidQuantity =>
      'Bir yoki bir nechta mahsulot miqdori noto\'g\'ri.';

  @override
  String get checkoutErrorDuplicateItem =>
      'Buyurtmada takroriy mahsulotlar topildi.';

  @override
  String get checkoutErrorInvalidShipping =>
      'Iltimos, to\'g\'ri yetkazib berish ma\'lumotlarini kiriting.';

  @override
  String get checkoutErrorInvalidCurrency =>
      'Tanlangan valyuta qo\'llab-quvvatlanmaydi.';

  @override
  String get checkoutErrorProductUnavailable =>
      'Savatchangizdagi bir yoki bir nechta mahsulot endi mavjud emas.';

  @override
  String get checkoutErrorInsufficientStock =>
      'Bir yoki bir nechta mahsulot omborda yetarli emas.';

  @override
  String get checkoutErrorInvalidResponse =>
      'Serverdan noto\'g\'ri javob olindi. Iltimos, buyurtmalar tarixini tekshiring.';

  @override
  String get checkoutErrorOutcomeUnknown =>
      'Buyurtmangiz bajarilganligini tekshirib bo\'lmadi. Qayta urinishdan oldin buyurtmalar tarixi yoki internetni tekshiring.';

  @override
  String get checkoutErrorUnknown =>
      'Buyurtma berishda kutilmagan xatolik yuz berdi. Iltimos, qaytadan urinib ko\'ring.';
}
