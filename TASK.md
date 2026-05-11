# Stitch Wallet App — Görev Takip Dosyası

> Son güncelleme: 6 Mayıs 2026 (Sprint 0 CI/CD pipeline tamamlandı — GitHub Actions workflow'ları `api-ci.yml` + `mobile-ci.yml`; PR #1 sırasında ortaya çıkan teknik borç da temizlendi)  
> ✅ = Tamamlandı | 🔧 = Kısmen yapıldı | ❌ = Henüz başlanmadı  
> ☑ = Kodda mevcut ancak migration henüz çalıştırılmadı

**Referans Dosyaları:**
- `SCHEMA.md` — Veritabanı şeması (Prisma modelleri, ER diyagramı, kategori sistemi)
- `DEVELOPMENT_PLAN_V1.md` — Temel özellikler mimarisi (Sprint 0-8)
- `DEVELOPMENT_PLAN_V2.md` — İleri özellikler mimarisi (Sprint 9-12)
- `STITCH_PROMPTS.md` — UI tasarım promptları

---

# V1 — TEMEL ÖZELLİKLER

> **Mimari referans:** `DEVELOPMENT_PLAN_V1.md`  
> **Şema referans:** `SCHEMA.md`

---

## Sprint 0 — Proje Kurulumu
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 5 (Sprint 0) + `SCHEMA.md`

### Backend (NestJS)
- [x] NestJS projesi oluşturuldu (`api/` dizini)
- [x] Prisma entegrasyonu yapıldı (`prisma/schema.prisma`) — tüm V1+V2 modelleri şemada tanımlı
- [x] PrismaService + PrismaModule (global) oluşturuldu
- [x] Migration çalıştırıldı (V1 modelleri için; V2 modelleri `schema.prisma`'da mevcut — Sprint 9-12 başlangıcında migrate edilecek)
- [x] Docker Compose yapılandırması (MySQL/MariaDB)
- [x] Global ValidationPipe, ExceptionFilter, TransformInterceptor
- [x] CORS yapılandırması
- [x] Environment değişkenleri (.env)
- [x] Seed script — 2 seviyeli kategori sistemi (17 gider + 5 gelir ana kategori + alt kategoriler)
- [x] Seed script — CategoryInflationMap (kategori → TÜİK TÜFE eşleştirmesi)
- [x] CI/CD pipeline — GitHub Actions `api-ci.yml`: lint + build + unit (76) + e2e (25, MariaDB container) — `061bbe5`

### Frontend (Flutter)
- [x] Flutter projesi oluşturuldu (`mobile/` dizini)
- [x] Tema sistemi (AppColors, AppTypography, AppSpacing)
- [x] Dark theme (Material 3) yapılandırıldı
- [x] Dio HTTP client + auth interceptor
- [x] GoRouter navigasyon iskeleti
- [x] GetIt dependency injection kurulumu
- [x] Secure storage (token saklama)
- [x] CurrencyFormatter utility
- [x] IconMapper utility
- [x] CI/CD pipeline — GitHub Actions `mobile-ci.yml`: flutter analyze + test (33) — `061bbe5`

---

## Sprint 1 — Kimlik Doğrulama (Auth)
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.0 (Auth kurgusuna dahil)

### Backend
- [x] User modeli + migration
- [x] PasswordResetToken modeli
- [x] `POST /api/auth/register` — bcrypt hash, validation, duplicate check
- [x] `POST /api/auth/login` — JWT access (15dk) + refresh token (7gün)
- [x] `POST /api/auth/forgot-password` — token üretimi (1 saat geçerli)
- [x] `POST /api/auth/reset-password` — token doğrulama + şifre güncelleme
- [x] `POST /api/auth/refresh` — refresh token ile yeni access token
- [x] `POST /api/auth/logout`
- [x] JwtAuthGuard + RefreshTokenGuard
- [x] @CurrentUser() decorator
- [x] `POST /api/auth/google/mobile` — Google OAuth entegrasyonu (ID token flow; `aud` claim → `GOOGLE_CLIENT_ID` doğrulaması, `GoogleMobileAuthDto` validasyonu)
- [x] E-posta gönderimi (nodemailer) — şifre sıfırlama bağlantısı

### Frontend
- [x] LoginPage (e-posta + şifre + Google butonu)
- [x] RegisterPage (ad, e-posta, şifre, şifre tekrar)
- [x] ForgotPasswordPage
- [x] ResetPasswordPage
- [x] AuthBloc (login/register/forgot/reset state yönetimi)
- [x] AuthRepository
- [x] Token yönetimi (secure storage + Dio interceptor)
- [x] Google Sign-In entegrasyonu — `POST /api/auth/google/mobile` (ID token → tokeninfo doğrulama), mobile `google_sign_in` paketi ile implemente edildi
- [x] Şifre güvenlik kuralları checklist UI — `_PasswordChecklist` widget, `ValueListenableBuilder` ile canlı güncelleniyor (min 8 karakter, büyük harf, rakam)

---

## Sprint 2 — Hesaplar + Anasayfa Dashboard
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.0 (Hesaplar Modülü)

### Backend — Hesap Temel CRUD
- [x] Account modeli + migration (BANK/CASH/CREDIT_CARD/INVESTMENT)
- [x] Category modeli + migration
- [x] `GET /api/accounts` — kullanıcının hesapları
- [x] `POST /api/accounts` — yeni hesap ekle
- [x] `PATCH /api/accounts/:id` — hesap güncelle
- [x] `DELETE /api/accounts/:id` — hesap sil
- [x] `GET /api/dashboard` — toplam varlık, aylık değişim, son işlemler, hesaplar
- [x] `GET /api/categories` — tüm kategoriler listesi
- [x] `POST /api/categories` — özel kategori ekle
- [x] Seed doğrulama: özel kategoriler (Borç Ödemesi, Alacak Tahsilatı, Abonelik) eklendi mi kontrol

### Backend — Hesaplar Genişletilmiş (YENİ)
- [x] Account modeline yeni alanlar ekle + migration:
  - `isDefault` (varsayılan hesap)
  - `isArchived` (arşivlenmiş)
  - `creditLimit` (kredi kartı limiti)
  - `statementDay` (ekstre kesim günü, 1-28)
  - `paymentDueDay` (son ödeme günü, 1-28)
- [x] `GET /api/accounts/summary` — toplam varlık + CC borcu + net varlık hesaplaması
- [x] `GET /api/accounts/:id/transactions` — hesaba özel işlem geçmişi
- [x] `GET /api/accounts/:id/analytics` — aylık giriş/çıkış + kategori dağılımı
- [x] `PATCH /api/accounts/:id/archive` — hesabı arşivle (isArchived=true, isActive=false)
- [x] `PATCH /api/accounts/:id/restore` — arşivden geri getir
- [x] `PATCH /api/accounts/:id/set-default` — varsayılan hesap yap (diğerlerini false yap)
- [x] `GET /api/accounts/:id/statement` — [CC] mevcut ekstre özeti
- [x] Kredi kartı limit kontrolü: harcama sonrası %80/%90/%100 aşarsa log bildirimi (`AccountsService.onTransactionCreated`)
- [x] Cron Job (08:00): `CreditCardStatementJob` — ekstre kesim günü bildirim

### Backend — Dashboard Güncelleme
- [x] Dashboard endpoint'ini güncelle:
  - Toplam Varlık = SUM(balance) WHERE type IN (BANK, CASH, INVESTMENT) AND !isArchived
  - Kredi Kartı Borcu = ABS(SUM(balance)) WHERE type = CREDIT_CARD AND balance < 0
  - Net Varlık = Toplam Varlık - CC Borcu
  - Aylık değişim = bu ay net varlık - geçen ay net varlık

### Frontend — Dashboard
- [x] BottomNavBar (AppShell — 5 tab)
- [x] DashboardPage layout
- [x] Kullanıcı selamlama + avatar
- [x] Toplam varlık gösterimi
- [x] Aylık gelir/gider chip'leri (trend okları)
- [x] Hızlı işlem butonları (Gelir/Gider/Transfer/Tara)
- [x] Hesap kartları (bakiye gizleme toggle)
- [x] Son işlemler listesi
- [x] Pull-to-refresh
- [x] DashboardBloc
- [x] DashboardRepository + DashboardModel
- [x] AccountModel + AccountsRepository
- [x] Dashboard BalanceCard güncelle: Toplam Varlık + CC Borcu + Net Varlık gösterimi
- [x] Hesap kartları carousel animasyonu (tasarımdaki gibi)
- [x] Kredi kartı kartında: limit bar (kullanılan/kalan) gösterimi

### Frontend — Hesap Yönetimi (YENİ)
- [x] AddAccountPage: tip seçimi, ad, bakiye, ikon, renk
  - Kredi kartı seçildiğinde: limit, kesim günü, son ödeme günü alanları
  - "Varsayılan yap" toggle
- [x] EditAccountPage: mevcut bilgileri güncelleme
- [x] AccountDetailPage: hesap detay sayfası
  - Üst kart: ad, bakiye, [CC: limit/kullanılan/kalan, ekstre bilgisi]
  - Bu ay giriş/çıkış
  - Aylık giriş/çıkış mini bar chart (son 6 ay)
  - En çok harcama kategorileri listesi
  - İşlem geçmişi (read-only liste)
  - "Varsayılan Yap" / "Düzenle" / "Arşivle" / "Sil" aksiyonları
- [x] Arşivlenmiş hesaplar listesi (ayarlardan erişim) — ArchivedAccountsPage + AccountsListPage
- [x] AccountsBloc (hesap CRUD + arşiv + varsayılan)

---

## Sprint 3 — İşlemler Modülü (Transactions)
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.1 + 8.4 (Transaction Hub)

### Backend — Temel CRUD
- [x] Transaction modeli + migration + indexler
- [x] `POST /api/transactions` — gelir/gider/transfer kaydı + bakiye güncelleme
- [x] `GET /api/transactions` — filtre + sayfalama
- [x] `GET /api/transactions/summary` — gelir/gider/net hesaplama
- [x] `GET /api/transactions/:id` — işlem detayı
- [x] `PATCH /api/transactions/:id` — işlem güncelle
- [x] `DELETE /api/transactions/:id` — işlem sil + bakiye geri alma
- [x] Tarih aralığı filtreleme
- [x] Kategori bazlı filtreleme (query param)
- [x] Hesap bazlı filtreleme (query param)
- [x] Arama (search) fonksiyonu

### Backend — Transaction Hub (YENİ — Merkezi Mimari)
- [x] `TransactionSource` enum ekle (MANUAL / RECURRING / DEBT_PAYMENT / DEBT_COLLECTION / SUBSCRIPTION)
- [x] Transaction modeline `source`, `relatedDebtId`, `relatedSubId` alanları ekle
- [x] Migration oluştur ve çalıştır
- [x] `@nestjs/event-emitter` entegrasyonu
- [x] `TransactionCreatedEvent`, `TransactionDeletedEvent`, `TransactionUpdatedEvent` tanımla
- [x] `TransactionsService.create()` sonrası event emit et
- [x] Raporlarda source bazlı filtreleme (gerçek gelir vs alacak tahsilatı ayrımı) — DEBT_COLLECTION gelirden çıkarıldı

### Backend — Tag Sistemi (YENİ)
- [x] `Tag` modeli + migration
- [x] `TransactionTag` join tablosu (many-to-many)
- [x] `GET /api/tags` — kullanıcının tüm etiketleri
- [x] `POST /api/tags` — yeni etiket oluştur
- [x] `DELETE /api/tags/:id` — etiket sil
- [x] Transaction oluşturma/güncelleme sırasında tag bağlama

### Backend — Tekrarlayan İşlemler (YENİ)
- [x] `RecurringTransaction` modeli + `RecurrenceFrequency` enum + migration
- [x] `GET /api/recurring-transactions` — şablon listesi
- [x] `POST /api/recurring-transactions` — yeni şablon + ilk işlemi hemen oluştur
- [x] `PATCH /api/recurring-transactions/:id` — şablonu güncelle
- [x] `DELETE /api/recurring-transactions/:id` — şablonu durdur/sil
- [x] Cron Job (00:05): `RecurringTransactionJob` — nextRunDate kontrolü + otomatik işlem oluştur

### Frontend
- [x] TransactionsPage (temel layout)
- [x] AddTransactionPage (temel layout)
- [x] TransactionsBloc + AddTransactionBloc
- [x] TransactionModel + TransactionsRepository
- [x] Özet kartları (Gelir/Gider/Net — tasarımdaki gibi)
- [x] Filtre chip'leri (Hepsi/Gelir/Gider/Transfer)
- [x] Tarihe göre gruplu liste (BUGÜN, DÜN başlıkları)
- [x] İşlem silme (swipe-to-delete)
- [x] Gider/Gelir toggle (tasarımdaki segment control)
- [x] Miktar girişi (₺ formatı, büyük font)
- [x] Kategori seçici grid (ikonlu, renkli)
- [ ] Tag seçici chip listesi (çoklu seçim + yeni tag ekleme) — formdan kaldırıldı, ileriye ertelendi
- [x] Hesap seçici chip'ler (Ziraat/Nakit/...)
- [x] Tekrarlayan toggle + frekans seçimi + bitiş tarihi
- [x] FAB (+) butonu
- [x] İşlem kaynağı göstergesi (ikon: manuel / abonelik / borç / tekrarlayan)

---

## Sprint 4 — Bütçeler Modülü (Budgets)
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.4 (Transaction Hub — event-driven budget tracking)

### Backend — Temel CRUD
- [x] Budget modeli + migration
- [x] `GET /api/budgets` — tüm bütçeler
- [x] `GET /api/budgets/overview` — toplam bütçe/harcama özeti
- [x] `POST /api/budgets` — yeni bütçe oluştur
- [x] `PATCH /api/budgets/:id` — bütçe güncelle
- [x] `DELETE /api/budgets/:id` — bütçe sil
- [x] Harcanan tutarı hesaplama (transactions'dan)

### Backend — Event-Driven Bütçe Takibi (YENİ)
- [x] `@OnEvent('transaction.created')` listener — BudgetService
- [x] `@OnEvent('transaction.deleted')` listener — spent yeniden hesapla
- [x] `@OnEvent('transaction.updated')` listener — kategori/tutar değişirse güncelle
- [x] `recalculateSpent()` metodu — ilgili kategorideki EXPENSE'leri topla
- [x] Bildirim eşikleri: %80 uyarı, %90 kritik, %100+ aşım (log olarak — FCM'siz)
- [x] Push notification entegrasyonu (FCM)
- [x] Cron Job (09:10): `BudgetDailyCheckJob` — günlük bütçe durumu özeti

### Frontend
- [x] BudgetsPage (dairesel özet, kart listesi, kaydır-sil, boş durum)
- [x] AddBudgetPage (tutar kart input, kategori grid, dönem seçici, tarih picker, akıllı takip toggle)
- [x] BudgetsBloc + AddBudgetBloc
- [x] BudgetModel + BudgetsRepository
- [x] Dairesel ilerleme widget (CustomPainter — toplam % gösterimi)
- [x] Kategori bazlı progress bar kartları (limit durumu renkleri — OK/WARNING/CRITICAL/EXCEEDED)
- [x] Bütçe tutarı girişi (büyük font, ₺ formatı, kart tasarımı)
- [x] Kategori seçici grid (EXPENSE + BOTH kategoriler)
- [x] "Akıllı Takip Aktif" toggle + açıklama
- [x] "Düzenle" butonu + bottom sheet (tutar, ad, dönem, bitiş tarihi, akıllı takip)
- [x] Bütçe aşım uyarı banner'ı (EXCEEDED=kırmızı, CRITICAL=turuncu)

---

## Sprint 5 — Borç Takibi + Abonelikler
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.2 (Borçlar) + 8.3 (Abonelikler)

### Backend — Borçlar (Temel CRUD)
- [x] Debt modeli + migration (LENT/BORROWED, PENDING/PAID/OVERDUE)
- [x] `GET /api/debts` — borç listesi
- [x] `GET /api/debts/summary` — alacak/borç özeti
- [x] `POST /api/debts` — yeni borç ekle
- [x] `PATCH /api/debts/:id` — borç güncelle
- [x] `DELETE /api/debts/:id` — borç sil

### Backend — Borçlar (YENİ — Taksit + Kısmi Ödeme + İşlem Entegrasyonu)
- [x] Debt modeli güncelle: `totalAmount`, `paidAmount`, `hasInstallments` alanları
- [x] `DebtInstallment` modeli + migration (installmentNo, amount, paidAmount, dueDate, status)
- [x] `DebtPayment` modeli + migration (amount, paidAt, note, installmentId opsiyonel)
- [x] `POST /api/debts` — taksitli borç desteği (taksit sayısı + ilk taksit tarihi)
- [x] `POST /api/debts/:id/payments` — ödeme kaydet → OTOMATİK Transaction oluştur
  - Borç (BORROWED) ödemesi → Transaction (EXPENSE, source: DEBT_PAYMENT)
  - Alacak (LENT) tahsilatı → Transaction (INCOME, source: DEBT_COLLECTION)
  - Hesap bakiyesi anlık güncellenir
- [x] `GET /api/debts/:id/payments` — ödeme geçmişi
- [x] `GET /api/debts/:id/installments` — taksit listesi
- [x] Kısmi ödeme: paidAmount += ödenen tutar, tam ödendiyse status = PAID
- [x] Taksit durum kontrolü: tüm taksitler PAID → Debt.status = PAID
- [x] Cron Job (00:10): `DebtOverdueJob` — vadesi geçmiş borç/taksitleri OVERDUE yap
- [x] Cron Job (09:05): `DebtDueNotifyJob` — yarın vadesi dolacak borçlar için bildirim (log)

### Backend — Abonelikler (Temel CRUD)
- [x] Subscription modeli + migration
- [x] `GET /api/subscriptions` — abonelik listesi
- [x] `GET /api/subscriptions/summary` — aylık toplam
- [x] `POST /api/subscriptions` — yeni abonelik
- [x] `PATCH /api/subscriptions/:id` — abonelik güncelle
- [x] `DELETE /api/subscriptions/:id` — abonelik sil

### Backend — Abonelikler (YENİ — İşlem Entegrasyonu)
- [x] Subscription modeline `accountId` (zorunlu) ve `autoDeduct` alanları ekle + migration
- [x] `POST /api/subscriptions` güncelle — ilk satın almada OTOMATİK Transaction oluştur (EXPENSE, source: SUBSCRIPTION)
- [x] `PATCH /api/subscriptions/:id/toggle` — aktif/pasif toggle
- [x] `GET /api/subscriptions/upcoming` — önümüzdeki 7 günde yenilenecekler
- [x] Cron Job (00:15): `SubscriptionRenewalJob` — yenilenme → Transaction oluştur + bakiye düş + nextRenewal ilerlet
- [x] Cron Job (09:00): `UpcomingRenewalNotifyJob` — yarın yenilenecek abonelikler bildirimi (log)
- [x] Abonelik iptal → isActive = false, gelecek işlemler durur, geçmiş korunur

### Frontend — Borçlar
- [x] DebtsPage (temel layout — SliverAppBar + RefreshIndicator)
- [x] DebtsBloc (event/state tanımlı)
- [x] DebtModel + DebtsRepository
- [x] Alacaklarım / Borçlarım özet kartları (yeşil/kırmızı, toplam + kalan)
- [x] Filtre chip'leri (Tümü / Alacak / Borç)
- [x] Borç listesi (kişi/kurum, toplam, kalan, progress bar)
- [x] Status badge'leri (Ödendi=yeşil, Beklemede=sarı, Gecikmiş=kırmızı)
- [x] Taksit göstergesi (taksit ikonu — detay ekranı henüz yok)
- [x] Borç ekleme ekranı (taksitli/taksitsiz seçim)
- [x] Borç detay sayfası (taksit listesi + ödeme geçmişi + ödeme FAB — DebtDetailBloc + DebtDetailPage)
- [x] Ödeme yap bottom sheet (tutar + hesap seçimi)
- [x] "Ödeme Aldım" butonu (alacak tahsilatı için)
- [x] FAB (+) butonu

### Frontend — Abonelikler
- [x] SubscriptionsPage (temel layout — SliverAppBar + RefreshIndicator)
- [x] SubscriptionsBloc (event/state tanımlı)
- [x] SubscriptionModel + SubscriptionsRepository
- [x] Aylık toplam gider kartı (büyük font)
- [x] "Yaklaşan Yenilenme" uyarı bandı (turuncu)
- [x] Abonelik listesi (ikon, tutar, periyot, bağlı hesap, Aktif/Pasif toggle)
- [x] "Yarın yenilenecek" uyarı etiketi
- [x] Abonelik ekleme ekranı (hesap seçimi zorunlu)
- [x] Abonelik detay sayfası (detay kartı, toggle aktif/pasif, silme — SubscriptionDetailPage)
- [x] Aktif/Pasif toggle (karttan doğrudan)
- [x] FAB (+) butonu

---

## Sprint 6 — Raporlar + Fiş Tarama
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 8.5 (Fiş Tarama Modülü)

### Backend — Raporlar
- [x] `GET /api/reports/expense-distribution` — kategori bazlı harcama dağılımı + yüzde
- [x] `GET /api/reports/cash-flow` — aylık gelir/gider/net bar chart verisi
- [x] `GET /api/reports/trends` — dönem karşılaştırması + en çok harcama kategorileri
- [x] Dönem filtreleme (Bu Ay / Son 3 Ay / Bu Yıl / Özel tarih)

### Backend — Fiş Tarama (Prisma Model Güncellemeleri)
- [x] Receipt modeli + migration (temel)
- [x] ReceiptsService (temel yapı)
- [x] ReceiptsController (temel yapı)
- [x] Receipt modeli güncelle: `ocrSource`, `confidence`, `parsedTax`, `paymentMethod`, `status (ReceiptStatus enum)` alanları
- [x] `ReceiptItem` modeli + migration (name, quantity, unitPrice, totalPrice, sortOrder)
- [x] `MerchantCategoryMap` modeli + migration (merchantKey, categoryId, hitCount, userId nullable=global)
- [x] `ReceiptStatus` enum ekle (PROCESSING, PARSED, CONFIRMED, FAILED)

### Backend — Fiş Tarama (OCR + Parse)
- [x] `POST /api/receipts/scan` — görsel yükleme (multer) + hibrit OCR tetikleme
- [x] Cloud Vision API entegrasyonu (`OcrService`) — backend fallback
- [x] `ReceiptParserService` — Türkçe fiş parse motoru:
  - [x] TOPLAM tutar çıkarma (TOPLAM/GENEL TOPLAM/TOP./TUTAR regex)
  - [x] Tarih çıkarma (DD/MM/YYYY, DD.MM.YYYY, YYYY-MM-DD)
  - [x] İşyeri adı çıkarma (ilk satır, A.Ş./LTD/TİC/MARKET pattern)
  - [x] KDV tutarı çıkarma (KDV %X, TOPKDV)
  - [x] Ödeme tipi çıkarma (NAKİT/KREDİ KARTI/TEMASSIZ)
  - [x] Ürün satırları çıkarma (ad + adet + tutar pattern)
- [x] Güvenilirlik skoru hesaplama (toplam bulundu? tarih bulundu? ≥3 satır?)

### Backend — Fiş Tarama (API Endpoint'leri)
- [x] `POST /api/receipts/scan` — yükleme + parse + ReceiptParseResult döndür
- [x] `POST /api/receipts/:id/confirm` — parse sonucunu onayla → Transaction oluştur (source: MANUAL)
- [x] `PATCH /api/receipts/:id` — parse sonucunu düzelt (tutar/tarih/işyeri)
- [x] `GET /api/receipts` — kullanıcının tüm fişleri (sayfalama + durum filtresi)
- [x] `GET /api/receipts/:id` — fiş detayı (items dahil)
- [x] `DELETE /api/receipts/:id` — fiş sil
- [x] `GET /api/merchant-mappings` — kullanıcının işyeri-kategori eşleştirmeleri
- [x] `POST /api/merchant-mappings` — yeni eşleştirme ekle / güncelle

### Backend — Fiş Tarama (Akıllı Özellikler)
- [x] Mükerrer fiş kontrolü: tutar + tarih + işyeri kombinasyonu (7 gün pencere)
- [x] Akıllı kategori eşleştirme: merchantKey normalize → MerchantCategoryMap sorgu
  - [x] Önce kullanıcı mapping'i (userId), sonra global mapping (userId=NULL)
  - [x] Eşleşme yoksa → null döner (Flutter "Kategorisiz" gösterir)
- [x] Kullanıcı kategori değiştirince → MerchantCategoryMap güncelle (hitCount++)
- [x] Fiş görselini local storage'a kaydet (uploads/receipts/)
- [x] Confirm sonrası Transaction oluştur + hesap bakiyesi güncelle

### Frontend — Raporlar
- [x] ReportsPage layout (BlocProvider + error/loading/loaded states)
- [x] Dönem filtreleri chip'leri (Bu Ay / 3 Ay / Bu Yıl)
- [x] Harcama dağılımı donut chart (fl_chart PieChart)
- [x] Aylık nakit akışı bar chart (fl_chart BarChart — Gelir vs Gider)
- [x] Kategori bazlı detay listesi (ikon, yüzde, tutar)
- [x] Kategori trendleri listesi (dönem karşılaştırması)
- [x] ReportsBloc + ReportRepository

### Frontend — Fiş Tarama
- [x] ReceiptScannerPage (kamera viewfinder)
  - [x] Scanner overlay çerçevesi (köşe işaretleri custom painter)
  - [x] "Fişi çerçevenin içine yerleştirin" rehber metni
  - [x] Galeri'den seçim butonu
  - [x] Çekim butonu + flaş toggle
- [x] Cihaz üstü OCR: `google_mlkit_text_recognition` entegrasyonu
  - [x] Güvenilirlik skoru hesapla (≥%70 → cihaz sonucu kullan)
  - [x] Skor düşükse → backend'e gönder (Cloud Vision fallback)
- [x] ReceiptPreviewPage — parse sonucu önizleme
  - [x] Fiş görseli üst kısım (küçük resim)
  - [x] Düzenlenebilir alanlar: tutar, tarih, işyeri, kategori
  - [x] Ürün listesi (ReceiptItem'lar — satır satır)
  - [x] Hesap seçici (hangi hesaptan düşülecek)
  - [x] "Mükerrer fiş" uyarı banner'ı (benzer fiş bulunduysa)
  - [x] "İşlem Oluştur" onay butonu
  - [x] "Tekrar Tara" butonu (başarısız parse)
- [x] ReceiptHistoryPage — geçmiş taramalar listesi (ReceiptHistoryBloc + swipe-to-delete + durum badge)
- [x] ReceiptPreviewBloc (scan → parse → preview → confirm state yönetimi)
- [x] ReceiptModel + ReceiptItemModel + ReceiptsRepository
- [x] Flutter paketleri: `camera`, `google_mlkit_text_recognition`, `image_picker`

---

## Sprint 7 — Ayarlar + Profil
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 4 (Flutter Mimarisi)

### Backend
- [x] UsersService (temel yapı)
- [x] UsersController (temel yapı)
- [x] `GET /api/users/me` — mevcut kullanıcı profili (hasPassword + isGoogleLinked flag'leri dahil)
- [x] `PATCH /api/users/me` — profil güncelle (fullName, currency, language, biometricEnabled, notificationsEnabled)
- [x] `POST /api/users/me/avatar` — avatar yükleme (local, max 5MB, jpg/png/webp; eski dosya otomatik silinir)
- [x] `DELETE /api/users/me/avatar` — avatar kaldır
- [x] `POST /api/users/me/change-password` — mevcut şifre doğrulama + değiştirme (Google hesabı korumalı)
- [x] `DELETE /api/users/me` — hesap sil (cascade)
- [x] `main.ts` güncellendi: `uploads/` klasörü `/uploads` prefix'i ile static dosya olarak servis edilir

### Frontend
- [x] SettingsPage layout (gruplu liste — Hesap/Tercihler/Güvenlik/Oturum)
- [x] Profil kartı (avatar + ad + e-posta)
- [x] "Profil" menü öğesi → EditProfilePage
- [x] "Hesaplarım" menü öğesi → AccountsListPage
- [x] "Arşivlenmiş Hesaplar" menü öğesi → ArchivedAccountsPage
- [x] Bildirimler toggle
- [x] Biyometrik giriş toggle
- [x] Şifre değiştir sayfası (bottom sheet)
- [x] "Çıkış Yap" butonu (onay dialog, kırmızı)
- [x] EditProfilePage (avatar değiştirme, ad düzenleme)
- [x] SettingsBloc
- [x] Para Birimi: TRY-only (seçici kaldırıldı — çoklu para birimi Sprint 10'a ertelendi, TCMB kur altyapısı orada kurulacak)
- [x] Dil seçici (Türkçe/English)
- [x] l10n yapılandırması (app_tr.arb, app_en.arb)

---

## Sprint 8 — Test + Optimizasyon + Yayın Hazırlığı
> 📖 Detay: `DEVELOPMENT_PLAN_V1.md` → Section 6 (Teknik Kararlar)

### Backend Testler
- [x] Auth modülü unit testler (16 test — register/login/refresh/forgotPw/resetPw/googleAuth)
- [x] Transactions modülü unit testler (16 test — findAll/getSummary/findOne/create/update/remove)
- [x] Budgets modülü unit testler (13 test — CRUD + event listener'lar)
- [x] Debts modülü unit testler (15 test — CRUD + createPayment + markOverdue)
- [x] Subscriptions modülü unit testler (16 test — CRUD + toggle + processRenewals)
- [x] E2E testler — Auth akışı (12 test: register/login/refresh/logout/forgot-password)
- [x] E2E testler — Transactions CRUD (11 test: list/create/summary/delete)
- [x] E2E testler — App sağlık kontrolleri (2 test)

### Frontend Testler
- [ ] Auth widget testleri
- [ ] Dashboard widget testleri
- [ ] Transactions widget testleri
- [x] BLoC testleri — AuthBloc (9 test: login/register/forgot/reset/logout) + TransactionsBloc (7 test: load/filter/delete/rollback) = **16 test, tümü geçti**
- [x] DebtsBloc + BudgetsBloc testleri — DebtsBloc (9 test: load/filter/delete-rollback/payment/refresh) + BudgetsBloc (7 test: load/delete/update/refresh) = **16 test, tümü geçti**
- [ ] Integration testleri (kritik akışlar)

### Optimizasyon & Son Dokunuşlar
- [x] Shimmer loading animasyonları (TransactionsShimmer, DebtsShimmer, SubscriptionsShimmer, BudgetsShimmer — gerçek Shimmer.fromColors animasyonu)
- [x] Empty state ekranları — EmptyBudgetsView, EmptyView (debts/subscriptions/transactions) mevcut, tasarıma uygun
- [x] Error handling ekranları — ErrorView'lar bloc-bağımsız onRetry callback'e dönüştürüldü (transactions, debts, subscriptions)
- [x] Lazy loading + infinite scroll — TransactionsBloc pagination (sayfa başına 20), ScrollController ile scroll listener, `isLoadingMore` spinner
- [x] Image caching (profil fotoğrafları — CachedNetworkImage ile değiştirildi)
- [ ] App icon tasarımı
- [x] Splash screen — `flutter_native_splash` ile #131313 renk, Android + iOS oluşturuldu
- [ ] Android store hazırlığı (signing, listing)
- [ ] iOS store hazırlığı (provisioning, listing)

---

# V2 — İLERİ ÖZELLİKLER

> **Mimari referans:** `DEVELOPMENT_PLAN_V2.md`  
> **Şema referans:** `SCHEMA.md` (V2 modelleri: InflationRate, PortfolioAsset, Insight, FamilyGroup vb.)  
> **Ön koşul:** V1 (Sprint 0-8) tamamlanmış olmalı

---

## Sprint 9 — Enflasyon-Duyarlı Bütçeleme
> 📖 Detay: `DEVELOPMENT_PLAN_V2.md` → Section 8.6

### Backend ✅ Tamamlandı (PR #6 + #7)

> ☑ Modeller hazır: `InflationRate`, `CategoryInflationMap` — `schema.prisma`'da tanımlı, CategoryInflationMap seed'i Sprint 0'da girildi.

- [x] Migration çalıştır: `npx prisma migrate dev --name add_inflation_models`
- [x] `InflationService` — TÜİK EVDS API entegrasyonu (PR #6, EVDS3 göçü PR #7 ile uyarlandı)
- [x] Cron Job (her ayın 5'i, 10:00; yedek ayın 10'u): `InflationFetchJob` — aylık TÜFE verilerini çek
- [x] TÜİK kategori eşleştirme seed data — Sprint 0'da `CategoryInflationMap` seed olarak girildi
- [x] `GET /api/inflation/current` — güncel enflasyon oranları
- [x] `GET /api/inflation/history` — geçmiş veriler (?months=6)
- [x] `GET /api/budgets/:id/inflation-suggestion` — bütçe ayarlama önerisi hesapla
- [x] `POST /api/budgets/:id/apply-inflation` — enflasyon önerisini uygula
- [x] `GET /api/reports/inflation-comparison` — harcama vs enflasyon raporu

> **Not (EVDS3 göçü, 2026-05-11):** TCMB EVDS API'sini `evds2.tcmb.gov.tr/service/evds/` → `evds3.tcmb.gov.tr/igmevdsms-dis/` adresine taşıdı. Üç breaking change: API anahtarı artık HTTP header (`key: ...`), çoklu seri ayırıcısı `-` (virgül değil), yanıttaki `Tarih` formatı `"YYYY-M"`. Lokal smoke test ile doğrulandı (`scripts/trigger-inflation-fetch.ts` aracı ile 261 kayıt çekildi).

### Frontend
- [ ] InflationSuggestionCard widget (bütçe sayfasında öneri kartı)
- [ ] InflationComparisonTable widget (raporlarda kategori bazlı karşılaştırma)
- [ ] InflationTrendChart widget (harcama vs enflasyon çizgi grafiği — fl_chart)
- [ ] BudgetsPage'e enflasyon öneri kartı entegrasyonu
- [ ] ReportsPage'e "Enflasyon Karşılaştırması" bölümü

---

## Sprint 10 — Altın / Döviz Portföy Takibi
> 📖 Detay: `DEVELOPMENT_PLAN_V2.md` → Section 8.7

### Backend

> ☑ Modeller hazır: `AssetType` enum, `PortfolioAsset`, `PortfolioTx`, `ExchangeRate` — `schema.prisma`'da tanımlı.

- [ ] Migration çalıştır: `npx prisma migrate dev --name add_portfolio_models`
- [ ] `ExchangeRateService` — TCMB + altın API entegrasyonu
- [ ] Cron Job (saatlik, 08:00-22:00): `ExchangeRateFetchJob` — kur güncelleme
- [ ] `GET /api/exchange-rates` — güncel tüm kurlar
- [ ] `GET /api/portfolio` — kullanıcının varlıkları (canlı değer dahil)
- [ ] `GET /api/portfolio/summary` — toplam değer, kâr/zarar, TL + USD bazlı
- [ ] `POST /api/portfolio/buy` — varlık alım kaydı
- [ ] `POST /api/portfolio/sell` — varlık satım kaydı
- [ ] `GET /api/portfolio/history` — alım/satım geçmişi
- [ ] `GET /api/portfolio/performance` — varlık bazlı performans
- [ ] Dashboard endpoint'ini güncelle: portföy canlı değer + çoklu para birimi net varlık

### Frontend
- [ ] PortfolioPage — ana portföy ekranı (varlık listesi + toplam değer)
- [ ] AddPortfolioTxPage — alım/satım ekleme (varlık seçimi, miktar, fiyat)
- [ ] AssetCard widget (varlık kartı: miktar, güncel değer, kâr/zarar %)
- [ ] ExchangeRateTicker widget (canlı kur bandı — dashboard üstü)
- [ ] PortfolioPieChart widget (varlık dağılımı — fl_chart)
- [ ] ProfitLossIndicator widget (+%2,5 yeşil / -%1,3 kırmızı)
- [ ] PortfolioBloc + ExchangeRateBloc
- [ ] PortfolioModel + PortfolioRepository
- [ ] Dashboard BalanceCard güncelle: TL + USD bazlı net varlık gösterimi
- [ ] BottomNavBar veya Dashboard'a portföy erişim noktası ekle

---

## Sprint 11 — Akıllı Harcama Analizi (Insights)
> 📖 Detay: `DEVELOPMENT_PLAN_V2.md` → Section 8.8

### Backend

> ☑ Model hazır: `Insight` — `schema.prisma`'da tanımlı.

- [ ] Migration çalıştır: `npx prisma migrate dev --name add_insight_model`
- [ ] `InsightRulesService` — 7 kural tabanlı analiz motoru:
  - [ ] spending_spike: kategori harcama artışı (%30+ artış tespiti)
  - [ ] unused_subscription: 60 gündür kullanılmayan abonelik
  - [ ] recurring_small_expense: küçük ama birikimli harcamalar (Starbucks x14)
  - [ ] weekend_spending: hafta sonu vs hafta içi harcama paterni
  - [ ] budget_forecast: ay ortası bütçe projeksiyonu
  - [ ] saving_opportunity: tasarruf başarısı tespiti + teşvik
  - [ ] income_expense_ratio: gelir-gider dengesi uyarısı (%90+ harcama)
- [ ] Cron Job (her ayın 1'i, 08:00): `MonthlyInsightJob` — tüm kullanıcılar için insight üret
- [ ] Eski insight'ları temizleme (6 aydan eski + dismissed)
- [ ] `GET /api/insights` — kullanıcının insight'ları (?period=2026-04&unread=true)
- [ ] `GET /api/insights/summary` — okunmamış sayısı + son insight
- [ ] `PATCH /api/insights/:id/read` — okundu işaretle
- [ ] `PATCH /api/insights/:id/dismiss` — kapat
- [ ] `POST /api/insights/generate` — manuel tetikleme

### Frontend
- [ ] InsightsPage — tüm insight'lar listesi (filtreli: bilgi/uyarı/başarı)
- [ ] InsightCard widget (ikon, başlık, mesaj, aksiyon butonları)
- [ ] InsightBadge widget (okunmamış sayısı — dashboard'da)
- [ ] InsightsCarousel widget (dashboard'da kaydırılabilir öneri kartları)
- [ ] InsightsBloc + InsightsRepository
- [ ] DashboardPage'e "Akıllı Öneriler" bölümü ekle
- [ ] Push notification entegrasyonu (aylık insight hazır bildirimi)

---

## Sprint 12 — Aile / Ortak Bütçe (v2)
> 📖 Detay: `DEVELOPMENT_PLAN_V2.md` → Section 8.9

### Backend

> ☑ Modeller hazır: `FamilyGroup`, `FamilyMember`, `FamilyInvite`, `SharedBudget`, `SharedExpense` — `schema.prisma`'da tanımlı.

- [ ] Migration çalıştır: `npx prisma migrate dev --name add_family_models`
- [ ] `FamilyService` — grup oluşturma, davet, üye yönetimi
- [ ] E-posta davet sistemi (token üretimi + doğrulama)
- [ ] `@OnEvent('transaction.created')` → SharedBudgetListener:
  - [ ] Kullanıcının grubu var mı kontrol et
  - [ ] İlgili kategoride ortak bütçe var mı kontrol et
  - [ ] Varsa → SharedExpense oluştur + spent güncelle
  - [ ] Tüm grup üyelerine bildirim gönder
- [ ] `POST /api/family/groups` — grup oluştur
- [ ] `GET /api/family/groups` — kullanıcının grupları
- [ ] `GET /api/family/groups/:id` — grup detayı
- [ ] `POST /api/family/groups/:id/invite` — üye davet et
- [ ] `POST /api/family/invites/:token/accept` — daveti kabul et
- [ ] `POST /api/family/invites/:token/reject` — daveti reddet
- [ ] `POST /api/family/groups/:id/budgets` — ortak bütçe oluştur
- [ ] `GET /api/family/groups/:id/budgets` — ortak bütçe listesi
- [ ] `GET /api/family/groups/:id/contributions` — katkı dağılımı raporu
- [ ] `DELETE /api/family/groups/:id/members/:userId` — üyeyi çıkar

### Frontend
- [ ] FamilyGroupPage — grup yönetimi (üyeler, ayarlar)
- [ ] SharedBudgetsPage — ortak bütçeler listesi + ilerleme
- [ ] InvitePage — üye davet ekranı (e-posta girişi)
- [ ] ContributionReportPage — katkı dağılımı raporu (çubuk grafik)
- [ ] MemberAvatarRow widget (üye avatarları)
- [ ] ContributionBar widget (Batuhan %64 / Ayşe %36)
- [ ] SharedBudgetCard widget (ortak bütçe kartı + progress bar)
- [ ] InviteStatusBadge widget (Beklemede/Kabul Edildi/Reddedildi)
- [ ] FamilyBloc + SharedBudgetBloc
- [ ] Ayarlar sayfasına "Aile Bütçesi" menü öğesi ekle

---

## Çapraz Modül — Merkezi Entegrasyon Görevleri

> Bu görevler birden fazla sprint'i etkiler ve Transaction Hub mimarisinin temelini oluşturur.

### Altyapı
- [x] `@nestjs/event-emitter` paketi kur ve EventEmitterModule'ü global olarak kaydet
- [x] `@nestjs/schedule` paketi kur ve ScheduleModule'ü kaydet
- [x] `BalanceService` oluştur (increment/decrement/transfer — Prisma $transaction ile atomik)
- [x] `NotificationService` oluştur (FCM entegrasyonu)
- [x] Sistem kategorileri seed data güncelle (+ "Borç Ödemesi", "Alacak Tahsilatı", "Abonelik")

### Event Akışı
- [x] `TransactionCreatedEvent` → BudgetService dinler → spent hesapla + bildirim
- [x] `TransactionDeletedEvent` → BudgetService dinler → spent azalt
- [x] `TransactionUpdatedEvent` → BudgetService dinler → her iki bütçeyi güncelle
- [x] Borç ödeme → TransactionsService.create(source: DEBT_PAYMENT) → event emit
- [x] Alacak tahsilatı → TransactionsService.create(source: DEBT_COLLECTION) → event emit
- [x] Abonelik yenilenme → TransactionsService.create(source: SUBSCRIPTION) → event emit

### Raporlama Ayrımı
- [x] Rapor endpoint'lerinde `source` filtresi: gerçek gelir vs alacak tahsilatı ayrımı
- [x] Dashboard'da "Bu ay" hesaplamasında DEBT_COLLECTION'ı gerçek gelirden ayır

---

## Genel İlerleme Özeti

| Sprint | Modül | Backend | Frontend | Durum |
|--------|-------|---------|----------|-------|
| Sprint 0 | Proje Kurulumu | ✅ %100 | ✅ %100 | ✅ CI/CD pipeline tamamlandı (PR #1) |
| Sprint 1 | Auth | ✅ %100 | ✅ %100 | ✅ Tamamlandı |
| Sprint 2 | Hesaplar + Dashboard | ✅ %100 | ✅ %100 | ✅ Tamamlandı |
| Sprint 3 | İşlemler | ✅ %100 | 🔧 %93 | 🔧 Frontend: yalnızca tag seçici eksik (ertelendi) |
| Sprint 4 | Bütçeler | ✅ %100 | ✅ %100 | ✅ Tamamlandı |
| Sprint 5 | Borçlar + Abonelikler | ✅ %100 | ✅ %100 | ✅ Borç detay + Abonelik detay tamamlandı |
| Sprint 6 | Raporlar + Fiş Tarama | ✅ %100 | ✅ %100 | ✅ Tamamlandı |
| Sprint 7 | Ayarlar + Profil | ✅ %100 | 🔧 %88 | 🔧 Para birimi/dil seçici, l10n eksik |
| Sprint 8 | Test + Optimizasyon | ✅ %90 | 🔧 %88 | 🔧 Backend: 76 unit + 25 e2e ✅, ESLint 0 hata ✅, Railway ✅; Frontend: shimmer ✅, BLoC testleri 32/32 ✅, empty states ✅, infinite scroll ✅, splash screen ✅; widget/integration testleri + app icon eksik |
| **Sprint 9** | **Enflasyon Bütçeleme** | ✅ %100 | ❌ %0 | 🔧 Backend tamam (PR #6 + #7), EVDS3 göçü uyarlandı; frontend bekliyor |
| **Sprint 10** | **Altın/Döviz Portföy** | ❌ %0 | ❌ %0 | ❌ Başlanmadı |
| **Sprint 11** | **Akıllı Harcama Analizi** | ❌ %0 | ❌ %0 | ❌ Başlanmadı |
| **Sprint 12** | **Aile/Ortak Bütçe (v2)** | ❌ %0 | ❌ %0 | ❌ Başlanmadı |
| Çapraz | Merkezi Entegrasyon | ✅ %100 | — | ✅ Event akışı ✅, Report/Dashboard source filtresi ✅, FCM bildirimleri ✅ |

**Tahmini genel ilerleme: ~%90** — V1 backend ✅ + Sprint 9 backend ✅, frontend Sprint 0-8 ~%95  
**Toplam sprint: 13** (Sprint 0-8 temel + Sprint 9-12 fark yaratan özellikler)  
**Sıradaki (Backend):** Sprint 10 (Altın/Döviz Portföy)  
**Sıradaki (Frontend):** Sprint 9 enflasyon UI bileşenleri (InflationSuggestionCard, InflationComparisonTable, InflationTrendChart + Budgets/Reports entegrasyonu)
