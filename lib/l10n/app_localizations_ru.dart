// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'TopBuy Deals';

  @override
  String get todaysPromotion => 'ПРЕДЛОЖЕНИЕ ДНЯ 🔥';

  @override
  String get findBestPrices =>
      'Находите лучшие предложения\nпо потрясающим ценам!';

  @override
  String get popularProducts => 'Популярные товары';

  @override
  String addedToCart(String productName) {
    return 'Добавлено в корзину: $productName';
  }

  @override
  String get homePage => 'Главная';

  @override
  String get categories => 'Категории';

  @override
  String get favorites => 'Избранное';

  @override
  String get profile => 'Профиль';

  @override
  String get electronics => 'Электроника';

  @override
  String get clothing => 'Одежда';

  @override
  String get accessories => 'Аксессуары';

  @override
  String get homeGoods => 'Дом и быт';

  @override
  String get sports => 'Спорт и отдых';

  @override
  String get cosmetics => 'Красота и уход';

  @override
  String get noFavoriteProducts => 'В избранном пока нет товаров ❤️';

  @override
  String get profileSection => 'Мой профиль';

  @override
  String get noCategoryProducts => 'В этой категории пока нет товаров';

  @override
  String get addToCart => 'В корзину';

  @override
  String get product => 'О товаре';

  @override
  String get currency => '\$';

  @override
  String get discount => 'Скидка';

  @override
  String get addToCartFull => 'Добавить в корзину';

  @override
  String get cart => 'Корзина';

  @override
  String get emptyCart => 'Ваша корзина пуста';

  @override
  String priceWithCurrency(String price) {
    return '\$$price';
  }

  @override
  String discountPercent(int percent) {
    return '-$percent%';
  }

  @override
  String discountValue(int percent) {
    return 'Скидка $percent%';
  }

  @override
  String get language => 'Язык';

  @override
  String get searchProducts => 'Поиск товаров...';

  @override
  String get noResultsFound => 'Ничего не найдено';

  @override
  String get recentSearches => 'Недавние запросы';

  @override
  String get popularSearches => 'Популярные запросы';

  @override
  String get filter => 'Фильтр';

  @override
  String get sortBy => 'Сортировка';

  @override
  String get priceRange => 'Диапазон цен';

  @override
  String get rating => 'Рейтинг';

  @override
  String get availability => 'Наличие';

  @override
  String get brand => 'Бренд';

  @override
  String get apply => 'Применить';

  @override
  String get clear => 'Сбросить';

  @override
  String get relevance => 'По релевантности';

  @override
  String get priceLowToHigh => 'Цена: по возрастанию';

  @override
  String get priceHighToLow => 'Цена: по убыванию';

  @override
  String get newest => 'Новинки';

  @override
  String get popularity => 'По популярности';

  @override
  String get todaysDeals => 'Предложения дня';

  @override
  String get flashDeals => 'Молниеносные скидки';

  @override
  String get priceDrops => 'Снижение цен';

  @override
  String get limitedTime => 'Ограниченное время';

  @override
  String get dealEndsIn => 'Акция закончится через';

  @override
  String get reviews => 'Отзывы';

  @override
  String get inStock => 'В наличии';

  @override
  String get lowStock => 'Заканчивается';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get freeShipping => 'Бесплатная доставка';

  @override
  String get specifications => 'Характеристики';

  @override
  String get features => 'Особенности';

  @override
  String get recentlyViewed => 'Недавно просмотренные';

  @override
  String get continueShopping => 'Продолжить покупки';

  @override
  String get bestSeller => 'Бестселлер';

  @override
  String get trending => 'В тренде';

  @override
  String get newArrival => 'Новинка';

  @override
  String get flashSale => 'Молниеносная распродажа';

  @override
  String get priceDrop => 'Цена снижена';

  @override
  String reviewsCount(int count) {
    return 'Отзывов: $count';
  }

  @override
  String get productDetails => 'Информация о товаре';

  @override
  String get description => 'Описание';

  @override
  String get keyFeatures => 'Ключевые особенности';

  @override
  String get shippingInfo => 'Информация о доставке';

  @override
  String get estimatedDelivery => 'Ориентировочная доставка';

  @override
  String get soldBy => 'Продавец';

  @override
  String get addedToWishlist => 'Добавлено в избранное';

  @override
  String get removedFromWishlist => 'Удалено из избранного';

  @override
  String get buyNow => 'Купить сейчас';

  @override
  String get share => 'Поделиться';

  @override
  String get relatedProducts => 'Похожие товары';

  @override
  String get similarDeals => 'Похожие предложения';

  @override
  String get youMayAlsoLike => 'Вам также может понравиться';

  @override
  String get customerReviews => 'Отзывы покупателей';

  @override
  String get ratingDistribution => 'Распределение оценок';

  @override
  String get writeReview => 'Написать отзыв';

  @override
  String get productInfo => 'Сведения о товаре';

  @override
  String get sku => 'Артикул';

  @override
  String deliveryIn(String days) {
    return 'Доставка через $days дн.';
  }

  @override
  String unitsInStock(int count) {
    return 'В наличии: $count шт.';
  }

  @override
  String onlyLeft(int count) {
    return 'Осталось всего $count!';
  }

  @override
  String selectVariant(String variant) {
    return 'Выберите: $variant';
  }

  @override
  String get color => 'Цвет';

  @override
  String get size => 'Размер';

  @override
  String get quantity => 'Количество';

  @override
  String get cartSubtotal => 'Подытог';

  @override
  String get search => 'Поиск';

  @override
  String get searchHint => 'Поиск товаров, брендов, предложений...';

  @override
  String get searchResults => 'Результаты поиска';

  @override
  String resultsFor(String query) {
    return 'Результаты по запросу «$query»';
  }

  @override
  String get noResults => 'Товары не найдены';

  @override
  String noResultsFor(String query) {
    return 'Нет результатов по запросу «$query»';
  }

  @override
  String get tryDifferentSearch => 'Попробуйте изменить поисковый запрос';

  @override
  String get filters => 'Фильтры';

  @override
  String get applyFilters => 'Применить фильтры';

  @override
  String get clearFilters => 'Сбросить все';

  @override
  String get filterBy => 'Фильтровать по';

  @override
  String get category => 'Категория';

  @override
  String get allCategories => 'Все категории';

  @override
  String get priceMin => 'Мин. цена';

  @override
  String get priceMax => 'Макс. цена';

  @override
  String get minRating => 'Минимальный рейтинг';

  @override
  String starsAndUp(int stars) {
    return 'Оценка $stars и выше';
  }

  @override
  String get minDiscount => 'Минимальная скидка';

  @override
  String discountAndUp(int discount) {
    return '$discount% и выше';
  }

  @override
  String get inStockOnly => 'Только в наличии';

  @override
  String get dealsOnly => 'Только со скидкой';

  @override
  String get sort => 'Сортировка';

  @override
  String get sortByLabel => 'Сортировать:';

  @override
  String productCount(int count) {
    return 'Товаров: $count';
  }

  @override
  String activeFilters(int count) {
    return 'Активно: $count';
  }

  @override
  String get recentSearchesLabel => 'Недавние запросы';

  @override
  String get clearSearchHistory => 'Очистить историю';

  @override
  String get suggestions => 'Подсказки';

  @override
  String get todaysDealsTitle => 'Предложения дня';

  @override
  String get biggestDiscountsTitle => 'Максимальные скидки';

  @override
  String get flashDealsTitle => 'Молниеносные скидки';

  @override
  String get trendingDealsTitle => 'Популярные предложения';

  @override
  String get priceDropsTitle => 'Снижение цен';

  @override
  String get recentlyViewedTitle => 'Недавно просмотренные';

  @override
  String get recommendedTitle => 'Рекомендуем вам';

  @override
  String get bestSellersTitle => 'Бестселлеры';

  @override
  String get viewAll => 'Смотреть все';

  @override
  String get seeMore => 'Показать ещё';

  @override
  String get save => 'Экономия';

  @override
  String savingsAmount(String amount) {
    return 'Экономия $amount';
  }

  @override
  String get upTo => 'До';

  @override
  String get off => 'СКИДКА';

  @override
  String get dealOfTheDay => 'Предложение дня';

  @override
  String get limitedQuantity => 'Ограниченное количество';

  @override
  String get hurry => 'Спешите!';

  @override
  String get almostGone => 'Почти разобрали!';

  @override
  String get login => 'Войти';

  @override
  String get signUp => 'Регистрация';

  @override
  String get logout => 'Выйти';

  @override
  String get email => 'Электронная почта';

  @override
  String get password => 'Пароль';

  @override
  String get fullName => 'Полное имя';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get emailHint => 'Введите адрес электронной почты';

  @override
  String get passwordHint => 'Введите пароль';

  @override
  String get fullNameHint => 'Введите ваше полное имя';

  @override
  String get confirmPasswordHint => 'Повторите пароль';

  @override
  String get emailRequired => 'Укажите адрес электронной почты';

  @override
  String get emailInvalid => 'Введите корректный адрес электронной почты';

  @override
  String get passwordRequired => 'Введите пароль';

  @override
  String get passwordTooShort => 'Пароль должен содержать не менее 6 символов';

  @override
  String get nameRequired => 'Введите имя';

  @override
  String get nameTooShort => 'Имя должно содержать не менее 2 символов';

  @override
  String get confirmPasswordRequired => 'Подтвердите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get loginSubtitle => 'Войдите, чтобы продолжить покупки';

  @override
  String get loginSuccess => 'Вы успешно вошли в систему';

  @override
  String get loginError => 'Не удалось войти. Проверьте введённые данные.';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get signUpSubtitle => 'Присоединяйтесь к TOPBUY DEALS уже сегодня';

  @override
  String get signUpSuccess => 'Аккаунт успешно создан!';

  @override
  String get signUpConfirmEmail =>
      'Аккаунт создан! Проверьте почту, перейдите по ссылке подтверждения и затем войдите.';

  @override
  String get resetPasswordTitle => 'Установите новый пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get resetPasswordSubmit => 'Обновить пароль';

  @override
  String get resetPasswordSuccess => 'Пароль успешно обновлён!';

  @override
  String get resetPasswordFailed =>
      'Не удалось обновить пароль. Возможно, срок действия ссылки истёк — запросите новую.';

  @override
  String get signUpError =>
      'Не удалось зарегистрироваться. Попробуйте ещё раз.';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get resetPassword => 'Сброс пароля';

  @override
  String get sendResetLink => 'Отправить ссылку для сброса';

  @override
  String get resetPasswordDescription =>
      'Введите адрес электронной почты, и мы отправим вам ссылку для сброса пароля';

  @override
  String get resetPasswordEmailSent => 'Письмо для сброса пароля отправлено!';

  @override
  String get resetPasswordEmailSentDescription =>
      'Мы отправили ссылку для сброса пароля на вашу почту. Проверьте входящие и следуйте инструкциям.';

  @override
  String get resetPasswordError =>
      'Не удалось отправить письмо для сброса. Попробуйте ещё раз.';

  @override
  String get resetPasswordHelpText =>
      'Не получили письмо? Проверьте папку «Спам» или отправьте его повторно.';

  @override
  String get checkYourEmail => 'Проверьте почту';

  @override
  String get resendEmail => 'Отправить письмо ещё раз';

  @override
  String resendIn(int seconds) {
    return 'Повторить через $seconds с';
  }

  @override
  String get backToLogin => 'Назад ко входу';

  @override
  String get or => 'ИЛИ';

  @override
  String get dontHaveAccount => 'Нет аккаунта?';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';

  @override
  String get passwordWeak => 'Слабый';

  @override
  String get passwordMedium => 'Средний';

  @override
  String get passwordStrong => 'Надёжный';

  @override
  String get signOut => 'Выйти из аккаунта';

  @override
  String get myAccount => 'Мой аккаунт';

  @override
  String get accountSettings => 'Настройки аккаунта';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get signedInAs => 'Вы вошли как';

  @override
  String get guest => 'Гость';

  @override
  String get signInToSeeMore =>
      'Войдите, чтобы получить доступ к дополнительным функциям';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get phoneNumberHint => 'Введите номер телефона';

  @override
  String get phoneNumberInvalid => 'Введите корректный номер телефона';

  @override
  String get saveChanges => 'Сохранить изменения';

  @override
  String get cancel => 'Отмена';

  @override
  String get profileUpdated => 'Профиль успешно обновлён';

  @override
  String get profileUpdateFailed => 'Не удалось обновить профиль';

  @override
  String get personalInformation => 'Личные данные';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get currencyPreference => 'Валюта';

  @override
  String get languagePreference => 'Язык';

  @override
  String get optional => 'Необязательно';

  @override
  String get continueWhereLeftOff =>
      'Продолжите с того места, где остановились';

  @override
  String get savingsUpTo => 'Скидки до 50%';

  @override
  String get limitedTimeOffers => 'Предложения на ограниченное время';

  @override
  String get bestDealsNow => 'Лучшие предложения прямо сейчас';

  @override
  String get mostLovedItems => 'Самые любимые товары наших покупателей';

  @override
  String get updatePersonalInfo => 'Обновите свои личные данные';

  @override
  String get confirmSignOut => 'Вы действительно хотите выйти из аккаунта?';

  @override
  String get signedOutSuccess => 'Вы успешно вышли из аккаунта';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountSubtitle =>
      'Безвозвратно удалить ваш аккаунт и данные';

  @override
  String get deleteAccountConfirmTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountConfirmMessage =>
      'Ваш аккаунт, профиль и все связанные данные будут удалены безвозвратно. Это действие нельзя отменить.';

  @override
  String get deleteAccountConfirmButton => 'Удалить безвозвратно';

  @override
  String get deleteAccountSuccess => 'Ваш аккаунт был безвозвратно удалён';

  @override
  String get deleteAccountFailed => 'Не удалось удалить аккаунт';

  @override
  String get deleteAccountHasOrders =>
      'Ваш аккаунт нельзя удалить, так как у вас есть оформленные заказы.';

  @override
  String get checkout => 'Оформление заказа';

  @override
  String get proceedToCheckout => 'Перейти к оформлению';

  @override
  String get shippingDetails => 'Детали доставки';

  @override
  String get fullNameRequired => 'Пожалуйста, введите полное имя';

  @override
  String get phone => 'Номер телефона';

  @override
  String get phoneRequired => 'Пожалуйста, введите номер телефона';

  @override
  String get streetAddress => 'Адрес улицы';

  @override
  String get streetAddressHint => 'Введите адрес улицы';

  @override
  String get streetAddressRequired => 'Пожалуйста, введите адрес';

  @override
  String get city => 'Город';

  @override
  String get cityHint => 'Введите город';

  @override
  String get cityRequired => 'Пожалуйста, введите город';

  @override
  String get country => 'Страна';

  @override
  String get countryHint => 'Введите страну';

  @override
  String get countryRequired => 'Пожалуйста, введите страну';

  @override
  String get orderSummary => 'Сводка заказа';

  @override
  String get placeOrder => 'Оформить заказ';

  @override
  String get orderConfirmation => 'Подтверждение заказа';

  @override
  String get orderPlacedSuccess => 'Заказ успешно оформлен!';

  @override
  String get orderSuccessMessage =>
      'Спасибо за покупку! Ваш заказ успешно принят в обработку.';

  @override
  String get orderId => 'Номер заказа';

  @override
  String get subtotalUsd => 'Итого (USD)';

  @override
  String get checkoutResetButton => 'Попробовать снова';

  @override
  String get checkoutErrorNotAuthenticated =>
      'Вам необходимо войти в систему для оформления заказа.';

  @override
  String get checkoutErrorEmptyCart => 'Ваша корзина пуста.';

  @override
  String get checkoutErrorInvalidQuantity =>
      'Недопустимое количество одного или нескольких товаров.';

  @override
  String get checkoutErrorDuplicateItem =>
      'В заказе обнаружены дублирующиеся товары.';

  @override
  String get checkoutErrorInvalidShipping =>
      'Пожалуйста, укажите корректные данные для доставки.';

  @override
  String get checkoutErrorInvalidCurrency =>
      'Выбранная валюта не поддерживается.';

  @override
  String get checkoutErrorProductUnavailable =>
      'Один или несколько товаров в корзине недоступны.';

  @override
  String get checkoutErrorInsufficientStock =>
      'Недостаточно товара на складе для одного или нескольких товаров.';

  @override
  String get checkoutErrorInvalidResponse =>
      'Получен некорректный ответ от сервера. Пожалуйста, проверьте историю заказов.';

  @override
  String get checkoutErrorOutcomeUnknown =>
      'Не удалось подтвердить оформление заказа. Проверьте историю заказов перед повторной попыткой.';

  @override
  String get checkoutErrorUnknown =>
      'Произошла непредвиденная ошибка при оформлении заказа. Пожалуйста, попробуйте снова.';
}
