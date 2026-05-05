// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Dijital Cüzdan';

  @override
  String get hello => 'Merhaba';

  @override
  String helloName(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get account => 'Hesap';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get myAccounts => 'Hesaplarım';

  @override
  String get archivedAccounts => 'Arşivlenmiş Hesaplar';

  @override
  String get preferences => 'Tercihler';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get biometricLogin => 'Biyometrik Giriş';

  @override
  String get currency => 'Para Birimi';

  @override
  String get language => 'Dil';

  @override
  String get tools => 'Araçlar';

  @override
  String get receiptHistory => 'Fiş Geçmişi';

  @override
  String get security => 'Güvenlik';

  @override
  String get changePassword => 'Şifre Değiştir';

  @override
  String get session => 'Oturum';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get logoutConfirmTitle => 'Çıkış Yap';

  @override
  String get logoutConfirmContent =>
      'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';

  @override
  String get selectCurrency => 'Para Birimi Seç';

  @override
  String get selectLanguage => 'Dil Seç';

  @override
  String get currencyTRY => 'Türk Lirası';

  @override
  String get currencyUSD => 'Amerikan Doları';

  @override
  String get currencyEUR => 'Euro';

  @override
  String get currencyGBP => 'İngiliz Sterlini';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get close => 'Kapat';

  @override
  String get add => 'Ekle';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get confirm => 'Onayla';

  @override
  String get dashboard => 'Ana Sayfa';

  @override
  String get transactions => 'İşlemler';

  @override
  String get budgets => 'Bütçeler';

  @override
  String get debts => 'Borçlar';

  @override
  String get subscriptions => 'Abonelikler';

  @override
  String get income => 'Gelir';

  @override
  String get expense => 'Gider';

  @override
  String get transfer => 'Transfer';

  @override
  String get noDataFound => 'Veri bulunamadı';

  @override
  String get errorOccurred => 'Bir hata oluştu';

  @override
  String get networkError => 'İnternet bağlantınızı kontrol edin.';

  @override
  String get tryAgain => 'Tekrar Dene';
}
