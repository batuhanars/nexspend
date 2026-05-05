import 'package:flutter/widgets.dart';

abstract class AppStrings {
  const AppStrings();

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'en' ? const _En() : const _Tr();
  }

  // Navigation
  String get navHome;
  String get navTransactions;
  String get navBudgets;
  String get navSubscriptions;

  // Add action sheet
  String get income;
  String get expense;
  String get transfer;
  String get scanReceipt;

  // Settings — sections
  String get settings;
  String get sectionAccount;
  String get sectionPreferences;
  String get sectionTools;
  String get sectionSecurity;
  String get sectionSession;

  // Settings — tiles
  String get editProfile;
  String get myAccounts;
  String get archivedAccounts;
  String get notifications;
  String get biometricLogin;
  String get currency;
  String get language;
  String get receiptHistory;
  String get changePassword;
  String get logout;

  // Settings — pickers
  String get selectCurrency;
  String get selectLanguage;
  String get currencyTRY;
  String get currencyUSD;
  String get currencyEUR;
  String get currencyGBP;

  // Dialogs / common
  String get cancel;
  String get logoutConfirmTitle;
  String get logoutConfirmContent;
  String get retry;

  // Dashboard
  String get hello;
  String helloName(String name);
  String get myAccountsTitle;
  String get addAccount;
  String get myDebts;
  String get recentTransactions;
  String get viewAll;
  String get totalAssets;
  String get netAssets;
  String get creditCardDebt;
  String get noTransactionsYet;
  String get addFirstTransaction;

  // Transactions page
  String get transactionsTitle;
  String get filterAll;
  String get summaryNet;
  String get noTransactions;
  String get noTransactionsSubtitle;
  String get addTransactionBtn;
  String get transactionFallback;

  // Budgets page
  String get budgetsTitle;
  String get activeBudgets;
  String get totalBudget;
  String get spent;
  String get remaining;
  String get spentArc;
  String get noBudgets;
  String get noBudgetsSubtitle;
  String get createBudgetBtn;

  // Subscriptions page
  String get subscriptionsTitle;
  String get monthlyTotal;
  String get activeLabel;
  String get noSubscriptions;
  String get noSubscriptionsSubtitle;
  String get addSubscriptionBtn;

  // Category localization — null means use backend name as-is
  String? translateCategory(String name);

  // Common actions
  String get save;
  String get saveAccount;
  String get saveChanges;
  String get delete;
  String get edit;
  String get update;
  String get ok;
  String get setAsDefault;
  String get archive;
  String get camera;
  String get gallery;
  String get loginAction;
  String get installment;
  String get scanAgain;
  String get goBack;
  String get registerAction;

  // Page titles
  String get addAccountTitle;
  String get editAccountTitle;
  String get newBudgetTitle;
  String get reportsTitle;
  String get receiptPreviewTitle;
  String get debtsTitle;
  String get smartTracking;

  // Dialog / sheet titles & content
  String get deleteTransactionTitle;
  String get deleteTransactionContent;
  String get deleteBudgetTitle;
  String deleteBudgetContent(String name);
  String get editBudgetTitle;
  String get cancelSubscriptionTitle;
  String get deleteSubscriptionTitle;
  String deleteSubscriptionContent(String name);
  String get deleteDebtTitle;
  String deleteDebtContent(String name);
  String get deleteReceiptTitle;
  String get selectPhotoTitle;
  String get addDebtTitle;
  String get addSubscriptionTitle;
  String get archiveAccountTitle;
  String get archiveAccountContent;
  String get archiveConfirm;
  String get deleteAccountContent;

  // Section labels
  String get transactionHistory;
  String get categoryLabel;
  String get accountLabel;
  String get targetAccountLabel;
  String get addFirstAccount;
  String get noArchivedAccounts;
  String get periodLabel;
  String get startDateLabel;
  String get endDateLabel;
  String get billingCycleLabel;
  String get autoDeductLabel;
  String get installmentsSection;
  String get paymentHistoryTitle;
  String get amountLabel;
  String get merchantLabel;
  String get dateLabel;

  // Snackbar / validation messages
  String get accountDeleted;
  String get passwordMismatch;
  String get passwordTooShort;
  String get transactionCreatedSuccess;
  String get enterValidAmount;
  String get selectAccount;
  String get selectTargetAccount;
  String get selectCategory;
  String get enterBudgetName;
  String get selectCategoryPrompt;
  String get accountsLoadFailed;

  // Account detail
  String get deleteAccountTitle;
  String get noAccountsYet;
  String get noAccountsSubtitle;
  String get accountDetailTitle;
  String get noAccountsFound;
  String get refreshTooltip;

  // Auth
  String get welcomeBack;
  String get signInSubtitle;
  String get emailLabel;
  String get passwordLabel;
  String get forgotPasswordAction;
  String get orDivider;
  String get continueWithGoogle;
  String get biometricLoginBtn;
  String get noAccount;
  String get createAccount;
  String get createAccountSubtitle;
  String get fullNameLabel;
  String get fullNameHint;
  String get passwordRepeatLabel;
  String get hasAccount;
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get sendResetLink;
  String get resetLinkSentTitle;
  String resetLinkSentContent(String email);
  String get resetPasswordTitle;
  String get resetPasswordSubtitle;
  String get newPasswordLabel;
  String get updatePasswordBtn;
  String get passwordRequirements;
  String get reqMinChars;
  String get reqUppercase;
  String get reqNumber;
  String get reqMinUppercase;
  String get reqMinNumber;
  String get passwordUpdatedTitle;
  String get passwordUpdatedContent;

  // Account form
  String get accountNameLabel;
  String get accountNameRequired;
  String get currentDebt;
  String get startingBalance;
  String get debtHint;
  String get invalidAmount;
  String get creditCardDetailsLabel;
  String get creditLimitHint;
  String get creditLimitRequired;
  String get creditLimitInvalid;
  String get statementDayLabel;
  String get paymentDueDayLabel;
  String get selectBankLabel;
  String get otherBankOption;
  String get bankNameLabel;
  String get bankNameHint;

  // Edit profile
  String get removePhoto;
  String get emailNotEditable;
  String get currentPasswordHint;
  String get newPasswordHint;
  String get confirmPasswordHint;

  // Budget form
  String get budgetNameLabel;
  String get budgetNameHint;
  String get noCategoriesFound;
  String get selectPlaceholder;
  String get smartTrackingSubtitle;
  String get noteOptionalLabel;
  String get addNoteHint;

  // Budget warnings
  String budgetsExceeded(int count);
  String budgetsCritical(int count);

  // Debt section
  String installmentsPaid(String paid, String total);
  String paymentsCount(int count);
  String get noPaymentsYet;
  String get collectPaymentBtn;
  String get makePaymentBtn;
  String get viewInstallmentsBtn;
  String get receivedPaymentTitle;
  String get payDebtTitle;
  String installmentPaymentTitle(int no);
  String installmentAmountLabel(String amount);
  String remainingAmountLabel(String amount);
  String get amountHint;
  String get noteOptionalHint;
  String get remainingLabel;
  String paidLabel(String amount);
  String totalLabel(String amount);
  String get dueDatePassed;
  String get dueDateToday;
  String get dueDateTomorrow;
  String get personNameHint;
  String get descriptionOptionalHint;
  String get dueDateHint;
  String get installmentCountLabel;

  // Subscription form
  String get billingCycleDaily;
  String get billingCycleWeekly;
  String get billingCycleMonthly;
  String get billingCycleYearly;
  String get subscriptionNameHint;

  // Receipt scanner
  String get cameraNotFound;
  String get cameraStartFailed;
  String get receiptAnalyzing;
  String get scanReceiptTitle;
  String get duplicateReceiptError;
  String get imageTooLarge;
  String get serverError;

  // Receipt scanner — extra UI strings
  String get noReceiptsYet;
  String get receiptDeleteContent;
  String get receiptStatusConfirmed;
  String get receiptStatusParsed;
  String get receiptStatusProcessing;
  String get receiptStatusFailed;
  String ocrConfidence(int pct);
  String get alignReceiptHint;
  String get selectAccountHint;
  String get selectCategoryHint;
  String get merchantNameHint;
  String get productsLabel;
  String get duplicateReceiptWarning;
  String get unknownMerchant;
  String get unknownDate;
  String photoCaptureError(String e);
  String receiptProcessError(String e);

  // Transaction widgets
  String get recurringTransaction;
  String get recurringFrequencyLabel;
  String get endDateOptional;
  String get descriptionOptional;
  String get noteOptional;
  String get todayLabel;
  String monthName(int m);
  String monthAbbr(int m);

  // Reports
  String get cashFlowTitle;
  String get expenseDistributionTitle;
  String get categoryTrendsTitle;
  String get periodThisMonth;
  String get period3Months;
  String get periodThisYear;
  String get previousLabel;

  // Debts — extra UI strings
  String get debtTypeBorrowed;
  String get debtTypeLent;
  String get summaryLent;
  String get summaryBorrowed;
  String get paymentCollection;
  String get paymentLabel;
  String installmentNo(int no);
  String partiallyPaid(String amount);
  String get allOption;
  String get noDebtsTitle;
  String get noDebtsSubtitle;
  String get addDebtBtn;
  String get collectBtn;
  String get payBtn;

  // Budget — extra UI strings
  String get periodCustom;
  String get budgetAmountLabel;
  String get budgetEndDate;
  String get budgetEndDateUnset;
  String get amountTRY;

  // Account type labels
  String get accountTypeBank;
  String get accountTypeCash;
  String get accountTypeCreditCard;
  String get accountTypeInvestment;

  // Account — extra UI strings
  String get defaultBadge;
  String get defaultAccountLabel;
  String get defaultAccountSubtitle;
  String get usedLabel;
  String get balanceLabel;
  String get usedSlashLimit;
  String usedAmount(String amount);
  String limitAmount(String amount);
  String get lastSixMonths;
  String get topCategoriesThisMonth;
  String get incomeChartLabel;
  String get expenseChartLabel;
  String get restoreBtn;
  String get loadFailed;
  String get archiveHint;

  // Subscriptions — extra UI strings
  String upcomingRenewals(int count);
}

// ─── Turkish ────────────────────────────────────────────────────────────────

class _Tr extends AppStrings {
  const _Tr();

  @override String get navHome => 'Anasayfa';
  @override String get navTransactions => 'İşlemler';
  @override String get navBudgets => 'Bütçe';
  @override String get navSubscriptions => 'Abonelik';

  @override String get income => 'Gelir';
  @override String get expense => 'Gider';
  @override String get transfer => 'Transfer';
  @override String get scanReceipt => 'Fiş Tara';

  @override String get settings => 'Ayarlar';
  @override String get sectionAccount => 'Hesap';
  @override String get sectionPreferences => 'Tercihler';
  @override String get sectionTools => 'Araçlar';
  @override String get sectionSecurity => 'Güvenlik';
  @override String get sectionSession => 'Oturum';

  @override String get editProfile => 'Profili Düzenle';
  @override String get myAccounts => 'Hesaplarım';
  @override String get archivedAccounts => 'Arşivlenmiş Hesaplar';
  @override String get notifications => 'Bildirimler';
  @override String get biometricLogin => 'Biyometrik Giriş';
  @override String get currency => 'Para Birimi';
  @override String get language => 'Dil';
  @override String get receiptHistory => 'Fiş Geçmişi';
  @override String get changePassword => 'Şifre Değiştir';
  @override String get logout => 'Çıkış Yap';

  @override String get selectCurrency => 'Para Birimi Seç';
  @override String get selectLanguage => 'Dil Seç';
  @override String get currencyTRY => 'Türk Lirası';
  @override String get currencyUSD => 'Amerikan Doları';
  @override String get currencyEUR => 'Euro';
  @override String get currencyGBP => 'İngiliz Sterlini';

  @override String get cancel => 'İptal';
  @override String get logoutConfirmTitle => 'Çıkış Yap';
  @override String get logoutConfirmContent => 'Hesabınızdan çıkış yapmak istediğinize emin misiniz?';
  @override String get retry => 'Tekrar Dene';

  @override String get hello => 'Merhaba';
  @override String helloName(String name) => 'Merhaba, $name';
  @override String get myAccountsTitle => 'Hesaplarım';
  @override String get addAccount => '+ Ekle';
  @override String get myDebts => 'Borçlarım';
  @override String get recentTransactions => 'Son İşlemler';
  @override String get viewAll => 'Tümünü Gör';
  @override String get totalAssets => 'TOPLAM VARLIK';
  @override String get netAssets => 'Net Varlık';
  @override String get creditCardDebt => 'CC Borcu';
  @override String get noTransactionsYet => 'Henüz işlem yok';
  @override String get addFirstTransaction => 'İlk işleminizi ekleyin';

  @override String get transactionsTitle => 'İşlemler';
  @override String get filterAll => 'Hepsi';
  @override String get summaryNet => 'Net';
  @override String get noTransactions => 'Henüz işlem yok';
  @override String get noTransactionsSubtitle => 'İlk işleminizi ekleyerek\ngelir ve giderlerinizi takip edin.';
  @override String get addTransactionBtn => 'İşlem Ekle';
  @override String get transactionFallback => 'İşlem';

  @override String get budgetsTitle => 'Bütçeler';
  @override String get activeBudgets => 'Aktif Bütçeler';
  @override String get totalBudget => 'Toplam Bütçe';
  @override String get spent => 'Harcanan';
  @override String get remaining => 'Kalan';
  @override String get spentArc => 'harcandı';
  @override String get noBudgets => 'Henüz bütçe yok';
  @override String get noBudgetsSubtitle => 'Harcamalarını takip etmek için\nbir bütçe oluştur.';
  @override String get createBudgetBtn => 'Bütçe Oluştur';

  @override String get subscriptionsTitle => 'Abonelikler';
  @override String get monthlyTotal => 'Aylık Toplam';
  @override String get activeLabel => 'Aktif';
  @override String get noSubscriptions => 'Abonelik yok';
  @override String get noSubscriptionsSubtitle => 'Netflix, Spotify gibi aboneliklerinizi\nekleyerek otomatik takip edin.';
  @override String get addSubscriptionBtn => 'Abonelik Ekle';

  @override String? translateCategory(String name) => null;

  @override String get save => 'Kaydet';
  @override String get saveAccount => 'Hesabı Kaydet';
  @override String get saveChanges => 'Değişiklikleri Kaydet';
  @override String get delete => 'Sil';
  @override String get edit => 'Düzenle';
  @override String get update => 'Güncelle';
  @override String get ok => 'Tamam';
  @override String get setAsDefault => 'Varsayılan Yap';
  @override String get archive => 'Arşivle';
  @override String get camera => 'Kamera';
  @override String get gallery => 'Galeri';
  @override String get loginAction => 'Giriş Yap';
  @override String get installment => 'Taksitli';
  @override String get scanAgain => 'Tekrar Tara';
  @override String get goBack => 'Geri Dön';
  @override String get registerAction => 'Kayıt Ol';

  @override String get addAccountTitle => 'Hesap Ekle';
  @override String get editAccountTitle => 'Hesabı Düzenle';
  @override String get newBudgetTitle => 'Yeni Bütçe';
  @override String get reportsTitle => 'Raporlar';
  @override String get receiptPreviewTitle => 'Makbuz Önizleme';
  @override String get debtsTitle => 'Borçlar';
  @override String get smartTracking => 'Akıllı Takip';

  @override String get deleteTransactionTitle => 'İşlemi Sil';
  @override String get deleteTransactionContent => 'Bu işlem silinecek ve hesap bakiyesi güncellenecek.';
  @override String get deleteBudgetTitle => 'Bütçeyi Sil';
  @override String deleteBudgetContent(String name) => '"$name" bütçesi silinecek.';
  @override String get editBudgetTitle => 'Bütçeyi Düzenle';
  @override String get cancelSubscriptionTitle => 'Aboneliği İptal Et';
  @override String get deleteSubscriptionTitle => 'Aboneliği Sil';
  @override String deleteSubscriptionContent(String name) => '$name aboneliği silinecek. Gelecek ödemeler durur.';
  @override String get deleteDebtTitle => 'Borcu Sil';
  @override String deleteDebtContent(String name) => '$name ile olan borç kaydı silinecek.';
  @override String get deleteReceiptTitle => 'Fişi Sil';
  @override String get selectPhotoTitle => 'Fotoğraf Seç';
  @override String get addDebtTitle => 'Borç Ekle';
  @override String get addSubscriptionTitle => 'Abonelik Ekle';
  @override String get archiveAccountTitle => 'Hesabı Arşivle';
  @override String get archiveAccountContent => 'Hesap gizlenecek, işlem geçmişi korunacak. Arşivlenen hesapları ayarlardan geri getirebilirsiniz.';
  @override String get archiveConfirm => 'Arşivle';
  @override String get deleteAccountContent => 'Bu hesap kalıcı olarak silinecek. İşlem geçmişi olan hesaplar silinemez.';

  @override String get transactionHistory => 'İşlem Geçmişi';
  @override String get categoryLabel => 'Kategori';
  @override String get accountLabel => 'Hesap';
  @override String get targetAccountLabel => 'Hedef Hesap';
  @override String get addFirstAccount => 'İlk Hesabı Ekle';
  @override String get noArchivedAccounts => 'Arşivlenmiş hesap yok';
  @override String get periodLabel => 'Dönem';
  @override String get startDateLabel => 'Başlangıç';
  @override String get endDateLabel => 'Bitiş';
  @override String get billingCycleLabel => 'Fatura Dönemi';
  @override String get autoDeductLabel => 'Otomatik Kesinti';
  @override String get installmentsSection => 'Taksitler';
  @override String get paymentHistoryTitle => 'Ödeme Geçmişi';
  @override String get amountLabel => 'Tutar';
  @override String get merchantLabel => 'İşyeri';
  @override String get dateLabel => 'Tarih';

  @override String get accountDeleted => 'Hesap silindi';
  @override String get passwordMismatch => 'Yeni şifreler eşleşmiyor.';
  @override String get passwordTooShort => 'Şifre en az 8 karakter olmalı.';
  @override String get transactionCreatedSuccess => 'İşlem başarıyla oluşturuldu';
  @override String get enterValidAmount => 'Geçerli bir tutar girin.';
  @override String get selectAccount => 'Bir hesap seçin.';
  @override String get selectTargetAccount => 'Hedef hesap seçin.';
  @override String get selectCategory => 'Bir kategori seçin.';
  @override String get enterBudgetName => 'Bütçe adı girin.';
  @override String get selectCategoryPrompt => 'Bir kategori seçin.';
  @override String get accountsLoadFailed => 'Hesaplar yüklenemedi';

  @override String get deleteAccountTitle => 'Hesabı Sil';
  @override String get noAccountsYet => 'Henüz hesap eklemediniz';
  @override String get noAccountsSubtitle => 'Gelir ve giderlerinizi takip etmek için\nilk hesabınızı oluşturun.';
  @override String get accountDetailTitle => 'Hesap Detayı';
  @override String get noAccountsFound => 'Hesap bulunamadı';
  @override String get refreshTooltip => 'Yenile';

  @override String get welcomeBack => 'Wallet\'a Tekrar\nHoş Geldiniz';
  @override String get signInSubtitle => 'Hesabınıza giriş yapın';
  @override String get emailLabel => 'E-posta';
  @override String get passwordLabel => 'Şifre';
  @override String get forgotPasswordAction => 'Şifremi unuttum';
  @override String get orDivider => 'veya';
  @override String get continueWithGoogle => 'Google ile Devam Et';
  @override String get biometricLoginBtn => 'Parmak İzi ile Giriş';
  @override String get noAccount => 'Hesabın yok mu?';
  @override String get createAccount => 'Hesap Oluştur';
  @override String get createAccountSubtitle => 'Finansal özgürlüğünüze başlayın';
  @override String get fullNameLabel => 'Ad Soyad';
  @override String get fullNameHint => 'Adınızı girin';
  @override String get passwordRepeatLabel => 'Şifre Tekrar';
  @override String get hasAccount => 'Zaten hesabın var mı?';
  @override String get forgotPasswordTitle => 'Şifremi Unuttum';
  @override String get forgotPasswordSubtitle => 'E-posta adresinizi girin, şifre sıfırlama bağlantısı gönderelim.';
  @override String get sendResetLink => 'Bağlantı Gönder';
  @override String get resetLinkSentTitle => 'Bağlantı Gönderildi!';
  @override String resetLinkSentContent(String email) => '$email adresine şifre sıfırlama bağlantısı gönderildi.';
  @override String get resetPasswordTitle => 'Yeni Şifrenizi\nBelirleyin';
  @override String get resetPasswordSubtitle => 'Güvenli bir şifre oluşturun.';
  @override String get newPasswordLabel => 'Yeni Şifre';
  @override String get updatePasswordBtn => 'Şifreyi Güncelle';
  @override String get passwordRequirements => 'Şifre Gereksinimleri';
  @override String get reqMinChars => 'En az 8 karakter';
  @override String get reqUppercase => 'Büyük harf içeriyor';
  @override String get reqNumber => 'Rakam içeriyor';
  @override String get reqMinUppercase => 'En az 1 büyük harf';
  @override String get reqMinNumber => 'En az 1 rakam';
  @override String get passwordUpdatedTitle => 'Şifre Güncellendi!';
  @override String get passwordUpdatedContent => 'Şifreniz başarıyla güncellendi. Yeni şifrenizle giriş yapabilirsiniz.';

  @override String get accountNameLabel => 'Hesap Adı';
  @override String get accountNameRequired => 'Hesap adı gerekli';
  @override String get currentDebt => 'Mevcut Borç (opsiyonel)';
  @override String get startingBalance => 'Başlangıç Bakiyesi';
  @override String get debtHint => 'Borcunuz yoksa boş bırakın';
  @override String get invalidAmount => 'Geçersiz tutar';
  @override String get creditCardDetailsLabel => 'Kredi Kartı Detayları';
  @override String get creditLimitHint => 'Kredi limiti';
  @override String get creditLimitRequired => 'Kredi limiti gerekli';
  @override String get creditLimitInvalid => 'Geçerli bir limit girin';
  @override String get statementDayLabel => 'Ekstre Günü';
  @override String get paymentDueDayLabel => 'Son Ödeme Günü';
  @override String get selectBankLabel => 'Banka Seç';
  @override String get otherBankOption => 'Diğer';
  @override String get bankNameLabel => 'Banka Adı';
  @override String get bankNameHint => 'Banka adını girin';

  @override String get removePhoto => 'Fotoğrafı Kaldır';
  @override String get emailNotEditable => 'E-posta adresi değiştirilemez';
  @override String get currentPasswordHint => 'Mevcut şifre';
  @override String get newPasswordHint => 'Yeni şifre';
  @override String get confirmPasswordHint => 'Yeni şifre tekrar';

  @override String get budgetNameLabel => 'Bütçe Adı';
  @override String get budgetNameHint => 'Örn. Market Bütçesi';
  @override String get noCategoriesFound => 'Kategori bulunamadı.';
  @override String get selectPlaceholder => 'Seç';
  @override String get smartTrackingSubtitle => 'İşlemler otomatik hesaplanır';
  @override String get noteOptionalLabel => 'Not (isteğe bağlı)';
  @override String get addNoteHint => 'Açıklama ekle...';

  @override String budgetsExceeded(int count) => '$count bütçeniz limiti aştı';
  @override String budgetsCritical(int count) => '$count bütçeniz kritik seviyeye yaklaştı';

  @override String installmentsPaid(String paid, String total) => '$paid/$total ödendi';
  @override String paymentsCount(int count) => '$count işlem';
  @override String get noPaymentsYet => 'Henüz ödeme yapılmadı.';
  @override String get collectPaymentBtn => 'Tahsil Et';
  @override String get makePaymentBtn => 'Borç Öde';
  @override String get viewInstallmentsBtn => 'Taksitleri Gör';
  @override String get receivedPaymentTitle => 'Ödeme Aldım';
  @override String get payDebtTitle => 'Ödeme Yap';
  @override String installmentPaymentTitle(int no) => '$no. Taksit Ödemesi';
  @override String installmentAmountLabel(String amount) => 'Taksit tutarı: $amount';
  @override String remainingAmountLabel(String amount) => 'Kalan: $amount';
  @override String get amountHint => 'Tutar (₺)';
  @override String get noteOptionalHint => 'Not (opsiyonel)';
  @override String get remainingLabel => 'Kalan tutar';
  @override String paidLabel(String amount) => '$amount ödendi';
  @override String totalLabel(String amount) => 'Toplam: $amount';
  @override String get dueDatePassed => 'Vadesi geçti';
  @override String get dueDateToday => 'Bugün vadesi doluyor';
  @override String get dueDateTomorrow => 'Yarın vadesi doluyor';
  @override String get personNameHint => 'Kişi / Kurum Adı';
  @override String get descriptionOptionalHint => 'Açıklama (opsiyonel)';
  @override String get dueDateHint => 'Vade tarihi (opsiyonel)';
  @override String get installmentCountLabel => 'Taksit Sayısı:';

  @override String get billingCycleDaily => 'Günlük';
  @override String get billingCycleWeekly => 'Haftalık';
  @override String get billingCycleMonthly => 'Aylık';
  @override String get billingCycleYearly => 'Yıllık';
  @override String get subscriptionNameHint => 'Abonelik adı (Netflix, Spotify...)';

  @override String get cameraNotFound => 'Kamera bulunamadı';
  @override String get cameraStartFailed => 'Kamera başlatılamadı';
  @override String get receiptAnalyzing => 'Makbuz analiz ediliyor...';
  @override String get scanReceiptTitle => 'Makbuz Tara';
  @override String get duplicateReceiptError => 'Bu fişi daha önce taradınız';
  @override String get imageTooLarge => 'Görsel çok büyük (maks 10 MB)';
  @override String get serverError => 'Sunucu hatası, tekrar deneyin';

  @override String get noReceiptsYet => 'Henüz fiş taranmadı.';
  @override String get receiptDeleteContent => 'Bu fiş kaydı kalıcı olarak silinecek.';
  @override String get receiptStatusConfirmed => 'Onaylandı';
  @override String get receiptStatusParsed => 'Tarandı';
  @override String get receiptStatusProcessing => 'İşleniyor';
  @override String get receiptStatusFailed => 'Başarısız';
  @override String ocrConfidence(int pct) => 'OCR güven skoru: %$pct';
  @override String get alignReceiptHint => 'Makbuzu çerçeve içine hizalayın';
  @override String get selectAccountHint => 'Hesap seç';
  @override String get selectCategoryHint => 'Kategori seç';
  @override String get merchantNameHint => 'İşyeri adı';
  @override String get productsLabel => 'ÜRÜNLER';
  @override String get duplicateReceiptWarning => 'Bu makbuz daha önce işlenmiş olabilir';
  @override String get unknownMerchant => 'Bilinmeyen Market';
  @override String get unknownDate => 'Tarih bilinmiyor';
  @override String photoCaptureError(String e) => 'Fotoğraf çekilemedi: $e';
  @override String receiptProcessError(String e) => 'Fiş işlenemedi: $e';

  @override String get recurringTransaction => 'Tekrarlayan İşlem';
  @override String get recurringFrequencyLabel => 'Sıklık';
  @override String get endDateOptional => 'Bitiş tarihi (opsiyonel)';
  @override String get descriptionOptional => 'Açıklama (opsiyonel)';
  @override String get noteOptional => 'Not (opsiyonel)';
  @override String get todayLabel => 'Bugün';
  @override String monthName(int m) => const ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'][m - 1];
  @override String monthAbbr(int m) => const ['Oca','Şub','Mar','Nis','May','Haz','Tem','Ağu','Eyl','Eki','Kas','Ara'][m - 1];

  @override String get cashFlowTitle => 'Nakit Akışı';
  @override String get expenseDistributionTitle => 'Harcama Dağılımı';
  @override String get categoryTrendsTitle => 'Kategori Trendleri';
  @override String get periodThisMonth => 'Bu Ay';
  @override String get period3Months => '3 Ay';
  @override String get periodThisYear => 'Bu Yıl';
  @override String get previousLabel => 'önceki';

  @override String get debtTypeBorrowed => 'Borç';
  @override String get debtTypeLent => 'Alacak';
  @override String get summaryLent => 'Alacaklarım';
  @override String get summaryBorrowed => 'Borçlarım';
  @override String get paymentCollection => 'Tahsilat';
  @override String get paymentLabel => 'Ödeme';
  @override String installmentNo(int no) => '$no. Taksit';
  @override String partiallyPaid(String amount) => '$amount ödendi';
  @override String get allOption => 'Tümü';
  @override String get noDebtsTitle => 'Borç kaydı yok';
  @override String get noDebtsSubtitle => 'Borç ve alacaklarınızı takip etmek\niçin ilk kaydı oluşturun.';
  @override String get addDebtBtn => 'Borç Ekle';
  @override String get collectBtn => 'Tahsil Et';
  @override String get payBtn => 'Öde';

  @override String get periodCustom => 'Özel';
  @override String get budgetAmountLabel => 'BÜTÇE TUTARI';
  @override String get budgetEndDate => 'Bitiş Tarihi';
  @override String get budgetEndDateUnset => 'Belirsiz';
  @override String get amountTRY => 'Tutar (₺)';

  @override String get accountTypeBank => 'Banka';
  @override String get accountTypeCash => 'Nakit';
  @override String get accountTypeCreditCard => 'Kredi Kartı';
  @override String get accountTypeInvestment => 'Yatırım';

  @override String get defaultBadge => 'Varsayılan';
  @override String get defaultAccountLabel => 'Varsayılan hesap';
  @override String get defaultAccountSubtitle => 'Yeni işlemlerde otomatik seçilir';
  @override String get usedLabel => 'KULLANILAN';
  @override String get balanceLabel => 'BAKİYE';
  @override String get usedSlashLimit => 'Kullanılan / Limit';
  @override String usedAmount(String amount) => 'Kullanılan: $amount';
  @override String limitAmount(String amount) => 'Limit: $amount';
  @override String get lastSixMonths => 'Son 6 Ay';
  @override String get topCategoriesThisMonth => 'Bu Ay En Çok Harcanan';
  @override String get incomeChartLabel => 'Gelir';
  @override String get expenseChartLabel => 'Gider';
  @override String get restoreBtn => 'Geri Yükle';
  @override String get loadFailed => 'Yüklenemedi';
  @override String get archiveHint => 'Hesap detayından arşivleyebilirsiniz';

  @override String upcomingRenewals(int count) => '$count abonelik önümüzdeki 7 günde yenileniyor';
}

// ─── English ─────────────────────────────────────────────────────────────────

class _En extends AppStrings {
  const _En();

  @override String get navHome => 'Home';
  @override String get navTransactions => 'Transactions';
  @override String get navBudgets => 'Budgets';
  @override String get navSubscriptions => 'Subscriptions';

  @override String get income => 'Income';
  @override String get expense => 'Expense';
  @override String get transfer => 'Transfer';
  @override String get scanReceipt => 'Scan Receipt';

  @override String get settings => 'Settings';
  @override String get sectionAccount => 'Account';
  @override String get sectionPreferences => 'Preferences';
  @override String get sectionTools => 'Tools';
  @override String get sectionSecurity => 'Security';
  @override String get sectionSession => 'Session';

  @override String get editProfile => 'Edit Profile';
  @override String get myAccounts => 'My Accounts';
  @override String get archivedAccounts => 'Archived Accounts';
  @override String get notifications => 'Notifications';
  @override String get biometricLogin => 'Biometric Login';
  @override String get currency => 'Currency';
  @override String get language => 'Language';
  @override String get receiptHistory => 'Receipt History';
  @override String get changePassword => 'Change Password';
  @override String get logout => 'Logout';

  @override String get selectCurrency => 'Select Currency';
  @override String get selectLanguage => 'Select Language';
  @override String get currencyTRY => 'Turkish Lira';
  @override String get currencyUSD => 'US Dollar';
  @override String get currencyEUR => 'Euro';
  @override String get currencyGBP => 'British Pound';

  @override String get cancel => 'Cancel';
  @override String get logoutConfirmTitle => 'Logout';
  @override String get logoutConfirmContent => 'Are you sure you want to logout?';
  @override String get retry => 'Try Again';

  @override String get hello => 'Hello';
  @override String helloName(String name) => 'Hello, $name';
  @override String get myAccountsTitle => 'My Accounts';
  @override String get addAccount => '+ Add';
  @override String get myDebts => 'My Debts';
  @override String get recentTransactions => 'Recent Transactions';
  @override String get viewAll => 'View All';
  @override String get totalAssets => 'TOTAL ASSETS';
  @override String get netAssets => 'Net Assets';
  @override String get creditCardDebt => 'CC Debt';
  @override String get noTransactionsYet => 'No transactions yet';
  @override String get addFirstTransaction => 'Add your first transaction';

  @override String get transactionsTitle => 'Transactions';
  @override String get filterAll => 'All';
  @override String get summaryNet => 'Net';
  @override String get noTransactions => 'No transactions yet';
  @override String get noTransactionsSubtitle => 'Add your first transaction\nto track income and expenses.';
  @override String get addTransactionBtn => 'Add Transaction';
  @override String get transactionFallback => 'Transaction';

  @override String get budgetsTitle => 'Budgets';
  @override String get activeBudgets => 'Active Budgets';
  @override String get totalBudget => 'Total Budget';
  @override String get spent => 'Spent';
  @override String get remaining => 'Remaining';
  @override String get spentArc => 'spent';
  @override String get noBudgets => 'No budgets yet';
  @override String get noBudgetsSubtitle => 'Create a budget\nto track your spending.';
  @override String get createBudgetBtn => 'Create Budget';

  @override String get subscriptionsTitle => 'Subscriptions';
  @override String get monthlyTotal => 'Monthly Total';
  @override String get activeLabel => 'Active';
  @override String get noSubscriptions => 'No subscriptions';
  @override String get noSubscriptionsSubtitle => 'Track subscriptions like\nNetflix and Spotify automatically.';
  @override String get addSubscriptionBtn => 'Add Subscription';

  @override String? translateCategory(String name) => _categoryMap[name];

  @override String get save => 'Save';
  @override String get saveAccount => 'Save Account';
  @override String get saveChanges => 'Save Changes';
  @override String get delete => 'Delete';
  @override String get edit => 'Edit';
  @override String get update => 'Update';
  @override String get ok => 'OK';
  @override String get setAsDefault => 'Set as Default';
  @override String get archive => 'Archive';
  @override String get camera => 'Camera';
  @override String get gallery => 'Gallery';
  @override String get loginAction => 'Log In';
  @override String get installment => 'Installment';
  @override String get scanAgain => 'Scan Again';
  @override String get goBack => 'Go Back';
  @override String get registerAction => 'Sign Up';

  @override String get addAccountTitle => 'Add Account';
  @override String get editAccountTitle => 'Edit Account';
  @override String get newBudgetTitle => 'New Budget';
  @override String get reportsTitle => 'Reports';
  @override String get receiptPreviewTitle => 'Receipt Preview';
  @override String get debtsTitle => 'Debts';
  @override String get smartTracking => 'Smart Tracking';

  @override String get deleteTransactionTitle => 'Delete Transaction';
  @override String get deleteTransactionContent => 'This transaction will be deleted and the account balance will be updated.';
  @override String get deleteBudgetTitle => 'Delete Budget';
  @override String deleteBudgetContent(String name) => '"$name" budget will be deleted.';
  @override String get editBudgetTitle => 'Edit Budget';
  @override String get cancelSubscriptionTitle => 'Cancel Subscription';
  @override String get deleteSubscriptionTitle => 'Delete Subscription';
  @override String deleteSubscriptionContent(String name) => '$name subscription will be deleted. Future payments will stop.';
  @override String get deleteDebtTitle => 'Delete Debt';
  @override String deleteDebtContent(String name) => 'The debt record with $name will be deleted.';
  @override String get deleteReceiptTitle => 'Delete Receipt';
  @override String get selectPhotoTitle => 'Select Photo';
  @override String get addDebtTitle => 'Add Debt';
  @override String get addSubscriptionTitle => 'Add Subscription';
  @override String get archiveAccountTitle => 'Archive Account';
  @override String get archiveAccountContent => 'The account will be hidden but transaction history will be preserved. You can restore archived accounts from settings.';
  @override String get archiveConfirm => 'Archive';
  @override String get deleteAccountContent => 'This account will be permanently deleted. Accounts with transaction history cannot be deleted.';

  @override String get transactionHistory => 'Transaction History';
  @override String get categoryLabel => 'Category';
  @override String get accountLabel => 'Account';
  @override String get targetAccountLabel => 'Target Account';
  @override String get addFirstAccount => 'Add First Account';
  @override String get noArchivedAccounts => 'No archived accounts';
  @override String get periodLabel => 'Period';
  @override String get startDateLabel => 'Start';
  @override String get endDateLabel => 'End';
  @override String get billingCycleLabel => 'Billing Cycle';
  @override String get autoDeductLabel => 'Auto Deduction';
  @override String get installmentsSection => 'Installments';
  @override String get paymentHistoryTitle => 'Payment History';
  @override String get amountLabel => 'Amount';
  @override String get merchantLabel => 'Merchant';
  @override String get dateLabel => 'Date';

  @override String get accountDeleted => 'Account deleted';
  @override String get passwordMismatch => 'New passwords do not match.';
  @override String get passwordTooShort => 'Password must be at least 8 characters.';
  @override String get transactionCreatedSuccess => 'Transaction created successfully';
  @override String get enterValidAmount => 'Enter a valid amount.';
  @override String get selectAccount => 'Select an account.';
  @override String get selectTargetAccount => 'Select a target account.';
  @override String get selectCategory => 'Select a category.';
  @override String get enterBudgetName => 'Enter a budget name.';
  @override String get selectCategoryPrompt => 'Please select a category.';
  @override String get accountsLoadFailed => 'Failed to load accounts';

  @override String get deleteAccountTitle => 'Delete Account';
  @override String get noAccountsYet => 'No accounts yet';
  @override String get noAccountsSubtitle => 'Create your first account\nto track income and expenses.';
  @override String get accountDetailTitle => 'Account Detail';
  @override String get noAccountsFound => 'No accounts found';
  @override String get refreshTooltip => 'Refresh';

  @override String get welcomeBack => 'Welcome Back\nto Wallet';
  @override String get signInSubtitle => 'Sign in to your account';
  @override String get emailLabel => 'Email';
  @override String get passwordLabel => 'Password';
  @override String get forgotPasswordAction => 'Forgot password';
  @override String get orDivider => 'or';
  @override String get continueWithGoogle => 'Continue with Google';
  @override String get biometricLoginBtn => 'Login with Fingerprint';
  @override String get noAccount => 'Don\'t have an account?';
  @override String get createAccount => 'Create Account';
  @override String get createAccountSubtitle => 'Start your financial freedom';
  @override String get fullNameLabel => 'Full Name';
  @override String get fullNameHint => 'Enter your name';
  @override String get passwordRepeatLabel => 'Repeat Password';
  @override String get hasAccount => 'Already have an account?';
  @override String get forgotPasswordTitle => 'Forgot Password';
  @override String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you a reset link.';
  @override String get sendResetLink => 'Send Link';
  @override String get resetLinkSentTitle => 'Link Sent!';
  @override String resetLinkSentContent(String email) => 'A password reset link has been sent to $email.';
  @override String get resetPasswordTitle => 'Set Your\nNew Password';
  @override String get resetPasswordSubtitle => 'Create a secure password.';
  @override String get newPasswordLabel => 'New Password';
  @override String get updatePasswordBtn => 'Update Password';
  @override String get passwordRequirements => 'Password Requirements';
  @override String get reqMinChars => 'At least 8 characters';
  @override String get reqUppercase => 'Contains uppercase letter';
  @override String get reqNumber => 'Contains a number';
  @override String get reqMinUppercase => 'At least 1 uppercase letter';
  @override String get reqMinNumber => 'At least 1 number';
  @override String get passwordUpdatedTitle => 'Password Updated!';
  @override String get passwordUpdatedContent => 'Your password has been updated. You can now log in with your new password.';

  @override String get accountNameLabel => 'Account Name';
  @override String get accountNameRequired => 'Account name is required';
  @override String get currentDebt => 'Current Debt (optional)';
  @override String get startingBalance => 'Starting Balance';
  @override String get debtHint => 'Leave empty if no debt';
  @override String get invalidAmount => 'Invalid amount';
  @override String get creditCardDetailsLabel => 'Credit Card Details';
  @override String get creditLimitHint => 'Credit limit';
  @override String get creditLimitRequired => 'Credit limit is required';
  @override String get creditLimitInvalid => 'Enter a valid limit';
  @override String get statementDayLabel => 'Statement Day';
  @override String get paymentDueDayLabel => 'Payment Due Day';
  @override String get selectBankLabel => 'Select Bank';
  @override String get otherBankOption => 'Other';
  @override String get bankNameLabel => 'Bank Name';
  @override String get bankNameHint => 'Enter bank name';

  @override String get removePhoto => 'Remove Photo';
  @override String get emailNotEditable => 'Email address cannot be changed';
  @override String get currentPasswordHint => 'Current password';
  @override String get newPasswordHint => 'New password';
  @override String get confirmPasswordHint => 'Repeat new password';

  @override String get budgetNameLabel => 'Budget Name';
  @override String get budgetNameHint => 'e.g. Grocery Budget';
  @override String get noCategoriesFound => 'No categories found.';
  @override String get selectPlaceholder => 'Select';
  @override String get smartTrackingSubtitle => 'Transactions are auto-calculated';
  @override String get noteOptionalLabel => 'Note (optional)';
  @override String get addNoteHint => 'Add a description...';

  @override String budgetsExceeded(int count) => '$count of your budgets exceeded the limit';
  @override String budgetsCritical(int count) => '$count of your budgets are near the limit';

  @override String installmentsPaid(String paid, String total) => '$paid/$total paid';
  @override String paymentsCount(int count) => '$count transactions';
  @override String get noPaymentsYet => 'No payments made yet.';
  @override String get collectPaymentBtn => 'Collect';
  @override String get makePaymentBtn => 'Pay Debt';
  @override String get viewInstallmentsBtn => 'View Installments';
  @override String get receivedPaymentTitle => 'I Received Payment';
  @override String get payDebtTitle => 'Make Payment';
  @override String installmentPaymentTitle(int no) => 'Installment $no Payment';
  @override String installmentAmountLabel(String amount) => 'Installment amount: $amount';
  @override String remainingAmountLabel(String amount) => 'Remaining: $amount';
  @override String get amountHint => 'Amount (₺)';
  @override String get noteOptionalHint => 'Note (optional)';
  @override String get remainingLabel => 'Remaining amount';
  @override String paidLabel(String amount) => '$amount paid';
  @override String totalLabel(String amount) => 'Total: $amount';
  @override String get dueDatePassed => 'Past due';
  @override String get dueDateToday => 'Due today';
  @override String get dueDateTomorrow => 'Due tomorrow';
  @override String get personNameHint => 'Person / Organization Name';
  @override String get descriptionOptionalHint => 'Description (optional)';
  @override String get dueDateHint => 'Due date (optional)';
  @override String get installmentCountLabel => 'Installment Count:';

  @override String get billingCycleDaily => 'Daily';
  @override String get billingCycleWeekly => 'Weekly';
  @override String get billingCycleMonthly => 'Monthly';
  @override String get billingCycleYearly => 'Yearly';
  @override String get subscriptionNameHint => 'Subscription name (Netflix, Spotify...)';

  @override String get cameraNotFound => 'Camera not found';
  @override String get cameraStartFailed => 'Camera could not be started';
  @override String get receiptAnalyzing => 'Analyzing receipt...';
  @override String get scanReceiptTitle => 'Scan Receipt';
  @override String get duplicateReceiptError => 'You have already scanned this receipt';
  @override String get imageTooLarge => 'Image too large (max 10 MB)';
  @override String get serverError => 'Server error, please try again';

  @override String get noReceiptsYet => 'No receipts scanned yet.';
  @override String get receiptDeleteContent => 'This receipt will be permanently deleted.';
  @override String get receiptStatusConfirmed => 'Confirmed';
  @override String get receiptStatusParsed => 'Scanned';
  @override String get receiptStatusProcessing => 'Processing';
  @override String get receiptStatusFailed => 'Failed';
  @override String ocrConfidence(int pct) => 'OCR confidence: $pct%';
  @override String get alignReceiptHint => 'Align receipt within the frame';
  @override String get selectAccountHint => 'Select account';
  @override String get selectCategoryHint => 'Select category';
  @override String get merchantNameHint => 'Merchant name';
  @override String get productsLabel => 'PRODUCTS';
  @override String get duplicateReceiptWarning => 'This receipt may have been processed before';
  @override String get unknownMerchant => 'Unknown Merchant';
  @override String get unknownDate => 'Unknown date';
  @override String photoCaptureError(String e) => 'Photo capture failed: $e';
  @override String receiptProcessError(String e) => 'Receipt processing failed: $e';

  @override String get recurringTransaction => 'Recurring Transaction';
  @override String get recurringFrequencyLabel => 'Frequency';
  @override String get endDateOptional => 'End date (optional)';
  @override String get descriptionOptional => 'Description (optional)';
  @override String get noteOptional => 'Note (optional)';
  @override String get todayLabel => 'Today';
  @override String monthName(int m) => const ['January','February','March','April','May','June','July','August','September','October','November','December'][m - 1];
  @override String monthAbbr(int m) => const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  @override String get cashFlowTitle => 'Cash Flow';
  @override String get expenseDistributionTitle => 'Expense Distribution';
  @override String get categoryTrendsTitle => 'Category Trends';
  @override String get periodThisMonth => 'This Month';
  @override String get period3Months => '3 Months';
  @override String get periodThisYear => 'This Year';
  @override String get previousLabel => 'prev';

  @override String get debtTypeBorrowed => 'Borrowed';
  @override String get debtTypeLent => 'Lent';
  @override String get summaryLent => 'My Receivables';
  @override String get summaryBorrowed => 'My Debts';
  @override String get paymentCollection => 'Collection';
  @override String get paymentLabel => 'Payment';
  @override String installmentNo(int no) => 'Installment $no';
  @override String partiallyPaid(String amount) => '$amount paid';
  @override String get allOption => 'All';
  @override String get noDebtsTitle => 'No debt records';
  @override String get noDebtsSubtitle => 'Create your first record\nto track debts and receivables.';
  @override String get addDebtBtn => 'Add Debt';
  @override String get collectBtn => 'Collect';
  @override String get payBtn => 'Pay';

  @override String get periodCustom => 'Custom';
  @override String get budgetAmountLabel => 'BUDGET AMOUNT';
  @override String get budgetEndDate => 'End Date';
  @override String get budgetEndDateUnset => 'Unlimited';
  @override String get amountTRY => 'Amount (₺)';

  @override String get accountTypeBank => 'Bank';
  @override String get accountTypeCash => 'Cash';
  @override String get accountTypeCreditCard => 'Credit Card';
  @override String get accountTypeInvestment => 'Investment';

  @override String get defaultBadge => 'Default';
  @override String get defaultAccountLabel => 'Default account';
  @override String get defaultAccountSubtitle => 'Auto-selected for new transactions';
  @override String get usedLabel => 'USED';
  @override String get balanceLabel => 'BALANCE';
  @override String get usedSlashLimit => 'Used / Limit';
  @override String usedAmount(String amount) => 'Used: $amount';
  @override String limitAmount(String amount) => 'Limit: $amount';
  @override String get lastSixMonths => 'Last 6 Months';
  @override String get topCategoriesThisMonth => 'Top Spending This Month';
  @override String get incomeChartLabel => 'Income';
  @override String get expenseChartLabel => 'Expense';
  @override String get restoreBtn => 'Restore';
  @override String get loadFailed => 'Failed to load';
  @override String get archiveHint => 'You can archive from account details';

  @override String upcomingRenewals(int count) => '$count subscription(s) renewing in the next 7 days';

  static const _categoryMap = <String, String>{
    'Market': 'Groceries',
    'Ulaşım': 'Transport',
    'Yeme-İçme': 'Food & Drink',
    'Faturalar': 'Bills',
    'Kira / Konut': 'Rent & Housing',
    'Sağlık': 'Health',
    'Eğlence': 'Entertainment',
    'Alışveriş': 'Shopping',
    'Eğitim': 'Education',
    'Teknoloji': 'Technology',
    'Spor': 'Sports',
    'Kişisel Bakım': 'Personal Care',
    'Sigorta': 'Insurance',
    'Ulaşım (Araç)': 'Vehicle',
    'Hediye / Bağış': 'Gifts & Donations',
    'Çocuk': 'Children',
    'Diğer (Gider)': 'Other (Expense)',
    'Diğer Market': 'Other Grocery',
    'Benzin': 'Fuel',
    'Toplu Taşıma': 'Public Transit',
    'Taksi': 'Taxi',
    'Otopark': 'Parking',
    'Bakım/Servis': 'Maintenance',
    'Restoran': 'Restaurant',
    'Kafe': 'Cafe',
    'Yemek Siparişi': 'Food Delivery',
    'Elektrik': 'Electricity',
    'Su': 'Water',
    'Doğalgaz': 'Natural Gas',
    'İnternet': 'Internet',
    'Telefon': 'Phone',
    'Kira': 'Rent',
    'Aidat': 'HOA Fee',
    'Tamir/Tadilat': 'Repairs',
    'İlaç': 'Medicine',
    'Muayene': 'Checkup',
    'Diş': 'Dental',
    'Gözlük/Lens': 'Glasses/Lenses',
    'Sinema': 'Cinema',
    'Konser': 'Concert',
    'Oyun': 'Gaming',
    'Hobi': 'Hobbies',
    'Tatil': 'Vacation',
    'Giyim': 'Clothing',
    'Ayakkabı': 'Shoes',
    'Aksesuar': 'Accessories',
    'Kozmetik': 'Cosmetics',
    'Okul': 'School',
    'Kurs': 'Courses',
    'Kitap': 'Books',
    'Online Eğitim': 'Online Learning',
    'Elektronik': 'Electronics',
    'Yazılım': 'Software',
    'Uygulama': 'Apps',
    'Spor Salonu': 'Gym',
    'Ekipman': 'Equipment',
    'Supplement': 'Supplements',
    'Kuaför': 'Hairdresser',
    'Cilt Bakımı': 'Skincare',
    'Parfüm': 'Perfume',
    'Sağlık Sigortası': 'Health Insurance',
    'Araç Sigortası': 'Car Insurance',
    'Vergi': 'Tax',
    'Kasko': 'Comprehensive Insurance',
    'Hediye': 'Gift',
    'Bağış': 'Donation',
    'Zekat/Fitre': 'Zakat/Fitrah',
    'Kreş': 'Daycare',
    'Oyuncak': 'Toys',
    'Çocuk Giyim': "Children's Clothing",
    'Maaş': 'Salary',
    'Yatırım Geliri': 'Investment Income',
    'Devlet': 'Government',
    'Diğer (Gelir)': 'Other (Income)',
    'Ana Maaş': 'Main Salary',
    'Ek İş': 'Side Job',
    'Prim': 'Bonus',
    'Proje': 'Projects',
    'Danışmanlık': 'Consulting',
    'Faiz': 'Interest',
    'Temettü': 'Dividend',
    'Kira Geliri': 'Rental Income',
    'Altın Satış': 'Gold Sale',
    'Vergi İadesi': 'Tax Refund',
    'Teşvik': 'Subsidy',
    'Burs': 'Scholarship',
    'İkinci El Satış': 'Second-Hand Sale',
    'Borç Ödemesi': 'Debt Payment',
    'Alacak Tahsilatı': 'Debt Collection',
    'Abonelik': 'Subscription',
  };
}
