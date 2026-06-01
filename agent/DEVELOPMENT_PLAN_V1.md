# Stitch Wallet App — Geliştirme Planı V1 (Temel Özellikler)

> **Proje:** Kişisel Finans Yönetim Uygulaması  
> **Teknoloji:** NestJS + MySQL (Backend) | Flutter (Frontend)  
> **Kapsam:** Sprint 0-8 — Auth, Hesaplar, İşlemler, Bütçeler, Borçlar, Abonelikler, Fiş Tarama, Raporlar, Ayarlar  
> **Tasarım Konsepti:** "The Digital Private Vault" — Premium dark-mode finans deneyimi
> 
> **İlişkili dosyalar:**
> - `SCHEMA.md` — Veritabanı şeması (Prisma modelleri, ER diyagramı, kategori sistemi)
> - `DEVELOPMENT_PLAN_V2.md` — İleri özellikler (Sprint 9-12)
> - `TASK.md` — Görev takibi
> - `STITCH_PROMPTS.md` — Tasarım promptları

---

## 1. Ekran Envanteri ve Analiz

Tasarımdan çıkarılan toplam **15 ekran**, 6 ana modülde gruplandırılmıştır.

### 1.1 Kimlik Doğrulama Modülü (Auth)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Giriş Yap** | E-posta + şifre ile login | E-posta input, şifre input (göster/gizle), "Giriş Yap" butonu, Google OAuth, "Kayıt Ol" linki |
| **Kayıt Ol** | Yeni hesap oluşturma | Ad Soyad, E-posta, Şifre, Şifre Tekrar inputları, "Kayıt Ol" butonu, "Giriş Yap" linki |
| **Şifremi Unuttum** | Şifre sıfırlama talebi | E-posta input, "Bağlantı Gönder" butonu |
| **Şifre Sıfırlama** | Yeni şifre belirleme | Yeni Şifre, Şifre Tekrar inputları, güvenlik kuralları checklist, "Şifreyi Güncelle" butonu |

### 1.2 Ana Sayfa (Dashboard)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Anasayfa** | Finansal genel bakış | Toplam varlık (₺45.230,00), aylık değişim (+₺3.840), hızlı işlem butonları (Gelir/Gider/Transfer/Tara), banka hesapları carousel (Ziraat Bankası, Nakit, vb.), son işlemler listesi |

### 1.3 İşlemler Modülü (Transactions)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **İşlemler Listesi** | Tüm gelir/gider kayıtları | Özet kartları (Gelir/Gider/Net), filtre chip'leri (Hepsi/Gelir/Gider/Market), tarihe göre gruplu liste, FAB (+) butonu |
| **İşlem Ekle** | Yeni gelir/gider kaydı | Gider/Gelir toggle, miktar girişi (₺), kategori seçimi (Market/Ulaşım/Eğlence/Sağlık/Alışveriş), hesap seçimi (Ziraat/Nakit/B...), başlık, not (opsiyonel), "Kaydet" butonu |

### 1.4 Bütçe Modülü (Budget)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Bütçeler** | Bütçe takip ekranı | Toplam harcama / toplam bütçe (₺12.450/₺20.000), dairesel ilerleme (%62), kategori bazlı bütçe kartları (progress bar + limit durumu), "Düzenle" linki, FAB (+) |
| **Bütçe Ekle** | Yeni bütçe oluşturma | Bütçe tutarı girişi, kategori seçimi (6 kategori + Diğer), bütçe adı, not, "Akıllı Takip Aktif" toggle (%80 bildirim), "Bütçe Oluştur" butonu |

### 1.5 Borç Takibi Modülü (Debts)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Borç Takibi** | Alacak/borç yönetimi | Alacaklarım / Borçlarım özet kartları, borç listesi (kişi/kurum, tutar, tarih, durum badge'leri: Ödendi/Beklemede/Gecikmiş), FAB (+) |

### 1.6 Abonelikler Modülü (Subscriptions)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Abonelikler** | Aktif abonelik takibi | Aylık toplam gider (₺845,90), aktif abonelik sayısı, abonelik listesi (Netflix/Spotify/YouTube/Adobe/Google One — tutar, periyot, yenilenme uyarısı), FAB (+) |

### 1.7 Raporlar Modülü (Reports)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Raporlar** | Finansal analiz ve grafikler | Dönem filtreleri (Bu Ay/Son 3 Ay/Bu Yıl/Özel), harcama dağılımı donut chart (kategori bazlı), aylık nakit akışı bar chart (Gelir vs Gider), kategori detay listesi |

### 1.8 Fiş Tarama (Receipt Scanner)

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Fiş Tara** | Kamera ile fiş okuma | Kamera viewfinder, çerçeve kılavuzu, "Fişi çerçevenin içine yerleştirin" rehber metni, galeri seçeneği, çekim butonu |

### 1.9 Ayarlar ve Profil

| Ekran | Açıklama | Temel Bileşenler |
|-------|----------|-------------------|
| **Ayarlar** | Uygulama ayarları | Hesap Ayarları (Profil/Banka Hesapları/Kategoriler), Tercihler (Bildirimler toggle/Para Birimi/Dil), Güvenlik (Biyometrik toggle/Şifre Değiştir), Destek (Yardım/Bize Ulaşın), "Oturumu Kapat" |
| **Profil Düzenle** | Kullanıcı bilgi güncelleme | Profil fotoğrafı (düzenle), Ad Soyad, E-posta, "Değişikleri Kaydet" butonu |

---

> **📋 Section 2 (Veritabanı Şeması)** → Bkz. `SCHEMA.md`

---

## 3. Backend Mimarisi (NestJS)

### 3.1 Proje Yapısı

```
api/
├── prisma/
│   ├── schema.prisma              # Veritabanı şeması (yukarıdaki Prisma modeli)
│   ├── migrations/                # Prisma migration dosyaları
│   └── seed.ts                    # Sistem kategorileri, varsayılan veriler
│
├── src/
│   ├── common/
│   │   ├── decorators/            # @CurrentUser(), @ApiPagination()
│   │   ├── dto/                   # PaginationDto, ApiResponseDto
│   │   ├── filters/               # HttpExceptionFilter, PrismaExceptionFilter
│   │   ├── guards/                # JwtAuthGuard, RolesGuard
│   │   ├── interceptors/          # TransformInterceptor, LoggingInterceptor
│   │   └── pipes/                 # ValidationPipe
│   │
│   ├── config/
│   │   ├── jwt.config.ts
│   │   └── app.config.ts
│   │
│   ├── prisma/
│   │   ├── prisma.service.ts      # PrismaClient wrapper (OnModuleInit/Destroy)
│   │   └── prisma.module.ts       # Global Prisma modülü
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   ├── dto/
│   │   │   │   ├── login.dto.ts
│   │   │   │   ├── register.dto.ts
│   │   │   │   ├── forgot-password.dto.ts
│   │   │   │   └── reset-password.dto.ts
│   │   │   └── strategies/
│   │   │       ├── jwt.strategy.ts
│   │   │       ├── google.strategy.ts
│   │   │       └── refresh-token.strategy.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── users.module.ts
│   │   │   └── dto/
│   │   │       ├── update-profile.dto.ts
│   │   │       └── update-settings.dto.ts
│   │   │
│   │   ├── accounts/
│   │   │   ├── accounts.controller.ts
│   │   │   ├── accounts.service.ts
│   │   │   ├── accounts.module.ts
│   │   │   └── dto/
│   │   │
│   │   ├── transactions/
│   │   │   ├── transactions.controller.ts
│   │   │   ├── transactions.service.ts
│   │   │   ├── transactions.module.ts
│   │   │   └── dto/
│   │   │       ├── create-transaction.dto.ts
│   │   │       └── filter-transaction.dto.ts
│   │   │
│   │   ├── budgets/
│   │   │   ├── budgets.controller.ts
│   │   │   ├── budgets.service.ts
│   │   │   ├── budgets.module.ts
│   │   │   └── dto/
│   │   │
│   │   ├── debts/
│   │   │   ├── debts.controller.ts
│   │   │   ├── debts.service.ts
│   │   │   ├── debts.module.ts
│   │   │   └── dto/
│   │   │
│   │   ├── subscriptions/
│   │   │   ├── subscriptions.controller.ts
│   │   │   ├── subscriptions.service.ts
│   │   │   ├── subscriptions.module.ts
│   │   │   └── dto/
│   │   │
│   │   ├── categories/
│   │   │   ├── categories.controller.ts
│   │   │   ├── categories.service.ts
│   │   │   ├── categories.module.ts
│   │   │   └── dto/
│   │   │
│   │   ├── reports/
│   │   │   ├── reports.controller.ts
│   │   │   ├── reports.service.ts
│   │   │   └── reports.module.ts
│   │   │
│   │   ├── receipts/
│   │   │   ├── receipts.controller.ts
│   │   │   ├── receipts.service.ts
│   │   │   ├── receipts.module.ts
│   │   │   └── dto/
│   │   │
│   │   └── notifications/
│   │       ├── notifications.service.ts
│   │       └── notifications.module.ts
│   │
│   ├── app.module.ts
│   └── main.ts
│
├── test/
├── docker-compose.yml
├── .env.example
├── package.json
└── tsconfig.json
```

### 3.2 API Endpoint Tablosu

#### Auth Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/auth/register` | Yeni kullanıcı kaydı |
| `POST` | `/api/auth/login` | E-posta + şifre ile giriş |
| `POST` | `/api/auth/google` | Google OAuth ile giriş |
| `POST` | `/api/auth/forgot-password` | Şifre sıfırlama bağlantısı gönder |
| `POST` | `/api/auth/reset-password` | Yeni şifre belirle |
| `POST` | `/api/auth/refresh` | Access token yenile |
| `POST` | `/api/auth/logout` | Oturumu kapat |

#### Users Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/users/me` | Mevcut kullanıcı profili |
| `PATCH` | `/api/users/me` | Profil güncelle (ad, e-posta) |
| `PATCH` | `/api/users/me/settings` | Ayarlar güncelle (dil, para birimi, bildirim, biyometrik) |
| `PATCH` | `/api/users/me/avatar` | Profil fotoğrafı güncelle (multipart) |
| `PATCH` | `/api/users/me/password` | Şifre değiştir |

#### Accounts Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/accounts` | Aktif hesaplar (?includeArchived=true ile arşivliler dahil) |
| `GET` | `/api/accounts/summary` | Toplam varlık + CC borcu + net varlık |
| `GET` | `/api/accounts/:id` | Hesap detayı |
| `GET` | `/api/accounts/:id/transactions` | Hesaba özel işlem geçmişi |
| `GET` | `/api/accounts/:id/analytics` | Aylık giriş/çıkış + kategori dağılımı |
| `GET` | `/api/accounts/:id/statement` | [CC] Mevcut ekstre özeti |
| `POST` | `/api/accounts` | Yeni hesap ekle (CC ise limit + kesim/ödeme günleri) |
| `PATCH` | `/api/accounts/:id` | Hesap güncelle |
| `PATCH` | `/api/accounts/:id/archive` | Hesabı arşivle |
| `PATCH` | `/api/accounts/:id/restore` | Arşivden geri getir |
| `PATCH` | `/api/accounts/:id/set-default` | Varsayılan hesap yap |

#### Transactions Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/transactions` | İşlem listesi (filtre + sayfalama) |
| `GET` | `/api/transactions/summary` | Gelir/Gider/Net özeti |
| `GET` | `/api/transactions/:id` | İşlem detayı |
| `POST` | `/api/transactions` | Yeni işlem ekle (tagIds[], isRecurring opsiyonel) |
| `PATCH` | `/api/transactions/:id` | İşlem güncelle |
| `DELETE` | `/api/transactions/:id` | İşlem sil |

**Filtre Parametreleri:** `?type=income|expense&source=manual|recurring|...&category_id=UUID&account_id=UUID&tag_ids=UUID,UUID&start_date=DATE&end_date=DATE&search=STRING&page=1&limit=20`

#### Tags Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/tags` | Kullanıcının tüm etiketleri |
| `POST` | `/api/tags` | Yeni etiket oluştur |
| `DELETE` | `/api/tags/:id` | Etiket sil |

#### Recurring Transactions Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/recurring-transactions` | Tekrarlayan işlem şablonları |
| `POST` | `/api/recurring-transactions` | Yeni şablon + ilk işlemi hemen oluştur |
| `PATCH` | `/api/recurring-transactions/:id` | Şablonu güncelle |
| `DELETE` | `/api/recurring-transactions/:id` | Şablonu durdur/sil |

#### Budgets Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/budgets` | Tüm bütçeler (harcanan dahil) |
| `GET` | `/api/budgets/overview` | Toplam bütçe özeti |
| `POST` | `/api/budgets` | Yeni bütçe oluştur |
| `PATCH` | `/api/budgets/:id` | Bütçe güncelle |
| `DELETE` | `/api/budgets/:id` | Bütçe sil |

#### Debts Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/debts` | Borç listesi (filtre: type, status) |
| `GET` | `/api/debts/summary` | Alacak toplamı, borç toplamı, net |
| `GET` | `/api/debts/:id` | Borç detayı (taksitler + ödeme geçmişi dahil) |
| `POST` | `/api/debts` | Yeni borç oluştur (taksitli/taksitsiz) |
| `PATCH` | `/api/debts/:id` | Borç güncelle |
| `DELETE` | `/api/debts/:id` | Borç sil (cascade: taksitler + ödemeler) |
| `POST` | `/api/debts/:id/payments` | Ödeme kaydet → otomatik Transaction oluştur |
| `GET` | `/api/debts/:id/payments` | Ödeme geçmişi |
| `GET` | `/api/debts/:id/installments` | Taksit listesi |

#### Subscriptions Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/subscriptions` | Abonelik listesi (filtre: isActive) |
| `GET` | `/api/subscriptions/summary` | Aylık toplam, aktif sayısı, yaklaşan yenilenme |
| `GET` | `/api/subscriptions/:id` | Abonelik detayı |
| `GET` | `/api/subscriptions/upcoming` | Önümüzdeki 7 gün içinde yenilenecekler |
| `POST` | `/api/subscriptions` | Yeni abonelik ekle (accountId zorunlu) |
| `PATCH` | `/api/subscriptions/:id` | Abonelik güncelle |
| `PATCH` | `/api/subscriptions/:id/toggle` | Aktif/Pasif toggle |
| `DELETE` | `/api/subscriptions/:id` | Abonelik sil |

#### Categories Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/categories` | Tüm kategoriler (sistem + kullanıcı) |
| `POST` | `/api/categories` | Özel kategori ekle |
| `PATCH` | `/api/categories/:id` | Kategori güncelle |
| `DELETE` | `/api/categories/:id` | Kategori sil |

#### Reports Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/reports/expense-distribution` | Kategori bazlı harcama dağılımı (donut chart) |
| `GET` | `/api/reports/cash-flow` | Aylık gelir/gider akışı (bar chart) |
| `GET` | `/api/reports/trends` | Harcama trendleri |

**Filtre:** `?period=this_month|last_3_months|this_year&start_date=DATE&end_date=DATE`

#### Receipts Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/receipts/scan` | Fiş görseli yükle + Cloud OCR başlat (multipart) |
| `GET` | `/api/receipts` | Kullanıcının tüm fiş geçmişi |
| `GET` | `/api/receipts/:id` | OCR sonuç detayı (items dahil) |
| `PATCH` | `/api/receipts/:id` | Parse sonucunu düzelt (merchant, amount, date) |
| `DELETE` | `/api/receipts/:id` | Fiş kaydını sil |
| `POST` | `/api/receipts/:id/create-transaction` | Parse sonucundan Transaction oluştur |
| `GET` | `/api/receipts/check-duplicate` | Mükerrer kontrol (query: amount, date, merchant) |

#### Merchant Mappings Endpoints
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/merchant-mappings` | Merchant → kategori eşleştirme listesi |
| `POST` | `/api/merchant-mappings` | Yeni eşleştirme ekle (kullanıcı düzeltmesinden öğren) |

#### Dashboard Endpoint
| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/dashboard` | Toplam varlık, aylık değişim, son işlemler, hesap bakiyeleri — tek çağrıda |

---

## 4. Frontend Mimarisi (Flutter)

### 4.1 Proje Yapısı

```
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # #131313, #BAC3FF, #70D8C8, #FFB68F ...
│   │   ├── app_typography.dart      # Inter font, Display-LG → Label-SM
│   │   ├── app_spacing.dart         # 4, 8, 12, 16, 24 spacing tokens
│   │   └── api_endpoints.dart
│   ├── theme/
│   │   └── app_theme.dart           # Dark theme (ThemeData)
│   ├── network/
│   │   ├── api_client.dart          # Dio HTTP client
│   │   ├── api_interceptors.dart    # Auth token, error handling
│   │   └── api_response.dart
│   ├── utils/
│   │   ├── currency_formatter.dart  # ₺45.230,00 formatı
│   │   ├── date_formatter.dart      # Türkçe tarih formatları
│   │   └── validators.dart          # E-posta, şifre validasyonu
│   ├── storage/
│   │   └── secure_storage.dart      # Token saklama
│   └── di/
│       └── injection.dart           # GetIt dependency injection
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── account_model.dart
│   │   ├── transaction_model.dart
│   │   ├── budget_model.dart
│   │   ├── debt_model.dart
│   │   ├── subscription_model.dart
│   │   ├── category_model.dart
│   │   ├── receipt_model.dart
│   │   └── report_model.dart
│   │
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── user_repository.dart
│   │   ├── account_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── budget_repository.dart
│   │   ├── debt_repository.dart
│   │   ├── subscription_repository.dart
│   │   ├── category_repository.dart
│   │   ├── report_repository.dart
│   │   └── receipt_repository.dart
│   │
│   └── datasources/
│       ├── remote/                  # API çağrıları
│       └── local/                   # Hive/SQLite cache
│
├── presentation/
│   ├── auth/
│   │   ├── bloc/
│   │   │   ├── auth_bloc.dart
│   │   │   ├── auth_event.dart
│   │   │   └── auth_state.dart
│   │   ├── pages/
│   │   │   ├── login_page.dart
│   │   │   ├── register_page.dart
│   │   │   ├── forgot_password_page.dart
│   │   │   └── reset_password_page.dart
│   │   └── widgets/
│   │       ├── auth_input_field.dart
│   │       ├── auth_button.dart
│   │       └── google_sign_in_button.dart
│   │
│   ├── dashboard/
│   │   ├── bloc/
│   │   │   └── dashboard_bloc.dart
│   │   ├── pages/
│   │   │   └── dashboard_page.dart
│   │   └── widgets/
│   │       ├── balance_card.dart          # Gradient toplam varlık kartı
│   │       ├── quick_actions_row.dart     # Gelir/Gider/Transfer/Tara
│   │       ├── account_carousel.dart      # Banka hesapları horizontal scroll
│   │       ├── account_card.dart          # Tek hesap kartı
│   │       └── recent_transactions.dart   # Son işlemler listesi
│   │
│   ├── transactions/
│   │   ├── bloc/
│   │   │   └── transactions_bloc.dart
│   │   ├── pages/
│   │   │   ├── transactions_page.dart
│   │   │   └── add_transaction_page.dart
│   │   └── widgets/
│   │       ├── summary_cards.dart         # Gelir/Gider/Net kartları
│   │       ├── filter_chips.dart          # Hepsi/Gelir/Gider/Market
│   │       ├── transaction_tile.dart      # Tek işlem satırı
│   │       ├── amount_input.dart          # ₺ miktar girişi
│   │       ├── category_selector.dart     # Kategori grid seçici
│   │       └── account_selector.dart      # Hesap chip'leri
│   │
│   ├── budgets/
│   │   ├── bloc/
│   │   │   └── budgets_bloc.dart
│   │   ├── pages/
│   │   │   ├── budgets_page.dart
│   │   │   └── add_budget_page.dart
│   │   └── widgets/
│   │       ├── budget_overview_card.dart   # Dairesel ilerleme
│   │       ├── budget_category_tile.dart   # Progress bar'lı kategori
│   │       └── smart_tracking_toggle.dart
│   │
│   ├── debts/
│   │   ├── bloc/
│   │   │   └── debts_bloc.dart
│   │   ├── pages/
│   │   │   └── debts_page.dart
│   │   └── widgets/
│   │       ├── debt_summary_cards.dart     # Alacak/Borç kartları
│   │       ├── debt_tile.dart             # Borç satırı + status badge
│   │       └── status_badge.dart          # Ödendi/Beklemede/Gecikmiş
│   │
│   ├── subscriptions/
│   │   ├── bloc/
│   │   │   └── subscriptions_bloc.dart
│   │   ├── pages/
│   │   │   └── subscriptions_page.dart
│   │   └── widgets/
│   │       ├── subscription_summary.dart
│   │       └── subscription_tile.dart
│   │
│   ├── reports/
│   │   ├── bloc/
│   │   │   └── reports_bloc.dart
│   │   ├── pages/
│   │   │   └── reports_page.dart
│   │   └── widgets/
│   │       ├── period_filter_chips.dart
│   │       ├── donut_chart.dart           # fl_chart
│   │       ├── bar_chart.dart             # fl_chart
│   │       └── category_breakdown.dart
│   │
│   ├── receipt_scanner/
│   │   ├── bloc/
│   │   │   └── receipt_bloc.dart
│   │   ├── pages/
│   │   │   └── receipt_scanner_page.dart
│   │   └── widgets/
│   │       └── scanner_overlay.dart
│   │
│   ├── settings/
│   │   ├── bloc/
│   │   │   └── settings_bloc.dart
│   │   ├── pages/
│   │   │   ├── settings_page.dart
│   │   │   └── edit_profile_page.dart
│   │   └── widgets/
│   │       ├── settings_section.dart
│   │       └── settings_tile.dart
│   │
│   └── shared/
│       ├── bottom_nav_bar.dart            # Glassmorphism tab bar
│       ├── app_scaffold.dart
│       ├── loading_widget.dart
│       └── empty_state_widget.dart
│
├── navigation/
│   ├── app_router.dart                    # GoRouter tanımları
│   └── route_names.dart
│
└── l10n/
    ├── app_tr.arb                         # Türkçe
    └── app_en.arb                         # İngilizce
```

### 4.2 Temel Flutter Paketleri

| Paket | Versiyon | Kullanım |
|-------|----------|----------|
| `flutter_bloc` | ^8.x | State management |
| `dio` | ^5.x | HTTP client |
| `go_router` | ^14.x | Navigasyon |
| `get_it` + `injectable` | latest | Dependency injection |
| `fl_chart` | ^0.68.x | Donut chart, bar chart (Raporlar) |
| `camera` | ^0.11.x | Fiş tarama kamera erişimi |
| `google_mlkit_text_recognition` | latest | OCR (fiş okuma) |
| `flutter_secure_storage` | latest | Token saklama |
| `google_sign_in` | latest | Google OAuth |
| `local_auth` | latest | Biyometrik giriş |
| `intl` | latest | Tarih/para formatı (₺45.230,00) |
| `cached_network_image` | latest | Profil fotoğrafı cache |
| `image_picker` | latest | Galeri/kamera seçimi |
| `shimmer` | latest | Yükleme animasyonları |
| `hive_flutter` | latest | Lokal cache |
| `json_annotation` + `json_serializable` | latest | JSON parsing |
| `equatable` | latest | Bloc state karşılaştırma |
| `freezed` | latest | Immutable data class |

### 4.3 Navigasyon Yapısı

```
AppRouter
├── /login                    → LoginPage
├── /register                 → RegisterPage
├── /forgot-password          → ForgotPasswordPage
├── /reset-password/:token    → ResetPasswordPage
│
└── / (ShellRoute — BottomNavBar)
    ├── /home                 → DashboardPage          [Tab: ANASAYFA]
    ├── /transactions         → TransactionsPage       [Tab: İŞLEMLER]
    │   └── /transactions/add → AddTransactionPage     (full-screen modal)
    ├── /budgets              → BudgetsPage            [Tab: BÜTÇE]
    │   └── /budgets/add      → AddBudgetPage          (full-screen modal)
    ├── /debts                → DebtsPage              [Tab: BORÇ]
    └── /subscriptions        → SubscriptionsPage      [Tab: ABONELİKLER]

    (AppBar/Drawer'dan erişilenler)
    ├── /reports              → ReportsPage
    ├── /receipt-scanner      → ReceiptScannerPage
    ├── /settings             → SettingsPage
    └── /settings/profile     → EditProfilePage
```

### 4.4 Tasarım Sistemi — Flutter Token'ları

```dart
// app_colors.dart
class AppColors {
  // Core Palette
  static const surface          = Color(0xFF131313);
  static const primary          = Color(0xFFBAC3FF);
  static const primaryContainer = Color(0xFF3C4C9F);
  static const secondary        = Color(0xFF70D8C8);  // Gelir / Yeşil
  static const tertiary         = Color(0xFFFFB68F);  // Gider / Turuncu
  static const error            = Color(0xFFFFB4AB);

  // Surface Variants
  static const surfaceContainerLow     = Color(0xFF1A1A1A);
  static const surfaceContainerHigh    = Color(0xFF2A2A2A);
  static const surfaceContainerHighest = Color(0xFF353535);

  // Text
  static const onSurface        = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFF9A9A9A);
  static const onPrimary        = Color(0xFF1A1A2E);

  // Outline
  static const outlineVariant   = Color(0xFF3A3A3A);  // ghost border: %10 opacity
}

// app_typography.dart  (Inter font)
// Display-LG:  700, 3.5rem (56px)  → Ana bakiyeler
// Headline-MD: 600, 1.75rem (28px) → Bölüm başlıkları
// Title-SM:    600, 1rem (16px)    → Kart başlıkları
// Body-MD:     400, 0.875rem (14px)→ İşlem detayları
// Label-SM:    500, 0.6875rem (11px)→ Uppercase overline'lar
```

---

## 5. Sprint Planı

### Sprint 0 — Proje Kurulumu (3 gün)

- [ ] NestJS projesi oluştur (`@nestjs/cli`)
- [ ] MySQL + Docker Compose yapılandır
- [ ] Prisma entegrasyonu, `schema.prisma` oluştur, `prisma generate` + `prisma migrate dev --name init`
- [ ] PrismaService + PrismaModule (global) oluştur
- [ ] Seed script (sistem kategorileri: Market/Ulaşım/Eğlence/Sağlık/Alışveriş)
- [ ] Flutter projesi oluştur
- [ ] Tema sistemi (AppColors, AppTypography, AppTheme)
- [ ] Dio HTTP client + interceptor'lar
- [ ] GoRouter navigasyon iskelet
- [ ] CI/CD temel pipeline (lint + test)

### Sprint 1 — Kimlik Doğrulama (5 gün)

**Backend:**
- [ ] User entity + migration
- [ ] `POST /auth/register` — bcrypt hash, validation
- [ ] `POST /auth/login` — JWT access + refresh token
- [ ] `POST /auth/google` — Google OAuth entegrasyonu
- [ ] `POST /auth/forgot-password` — e-posta gönderimi (nodemailer)
- [ ] `POST /auth/reset-password` — token doğrulama + şifre güncelleme
- [ ] JwtAuthGuard, RefreshToken mekanizması

**Frontend:**
- [ ] LoginPage (tasarıma birebir uygun)
- [ ] RegisterPage
- [ ] ForgotPasswordPage
- [ ] ResetPasswordPage (güvenlik kuralları checklist)
- [ ] AuthBloc (login/register/forgot/reset state yönetimi)
- [ ] Google Sign-In entegrasyonu
- [ ] Secure storage ile token yönetimi

### Sprint 2 — Hesaplar + Anasayfa Dashboard (5 gün)

**Backend:**
- [ ] Account entity + migration
- [ ] Category entity + seed data (Market/Ulaşım/Eğlence/Sağlık/Alışveriş)
- [ ] CRUD endpoint'leri: `/api/accounts`, `/api/categories`
- [ ] `GET /api/dashboard` — toplam varlık, aylık değişim, son işlemler, hesaplar

**Frontend:**
- [ ] BottomNavBar (glassmorphism, 5 tab)
- [ ] DashboardPage layout
- [ ] BalanceCard (gradient, toplam varlık, aylık değişim)
- [ ] QuickActionsRow (Gelir/Gider/Transfer/Tara butonları)
- [ ] AccountCarousel (yatay scroll, banka kartları)
- [ ] RecentTransactions listesi
- [ ] DashboardBloc

### Sprint 3 — İşlemler Modülü (5 gün)

**Backend:**
- [ ] Transaction entity + migration + indexler
- [ ] `POST /api/transactions` — gelir/gider/transfer kaydı + hesap bakiye güncelleme
- [ ] `GET /api/transactions` — filtre + sayfalama + tarih gruplama
- [ ] `GET /api/transactions/summary` — gelir/gider/net hesaplama
- [ ] Transaction silme/güncelleme + bakiye geri alma

**Frontend:**
- [ ] TransactionsPage (özet kartları + filtre chip'leri + gruplu liste)
- [ ] TransactionTile widget
- [ ] AddTransactionPage (Gider/Gelir toggle, miktar, kategori grid, hesap seçimi)
- [ ] AmountInput widget (₺ formatı)
- [ ] CategorySelector widget
- [ ] AccountSelector widget
- [ ] TransactionsBloc

### Sprint 4 — Bütçeler Modülü (4 gün)

**Backend:**
- [ ] Budget entity + migration
- [ ] CRUD endpoint'leri + otomatik `spent` hesaplama (transactions'dan)
- [ ] `GET /api/budgets/overview` — toplam bütçe/harcama özeti
- [ ] Akıllı Takip: %80 eşiğinde push notification tetikleme

**Frontend:**
- [ ] BudgetsPage (dairesel ilerleme + kategori listesi)
- [ ] BudgetOverviewCard (CustomPainter ile circular progress)
- [ ] BudgetCategoryTile (progress bar + limit durumu renkleri)
- [ ] AddBudgetPage (tutar, kategori seçimi, akıllı takip toggle)
- [ ] BudgetsBloc

### Sprint 5 — Borç Takibi + Abonelikler (5 gün)

**Backend:**
- [ ] Debt entity + migration
- [ ] CRUD + durum yönetimi (pending → paid / overdue)
- [ ] Vade kontrolü: günlük cron job ile gecikmiş borçları işaretle
- [ ] Subscription entity + migration
- [ ] CRUD + yenilenme tarihi hesaplama
- [ ] Abonelik yenilenme hatırlatma bildirimi

**Frontend:**
- [ ] DebtsPage (özet kartları + borç listesi + status badge'leri)
- [ ] StatusBadge widget (Ödendi=yeşil, Beklemede=sarı, Gecikmiş=kırmızı)
- [ ] SubscriptionsPage (aylık toplam + abonelik listesi)
- [ ] SubscriptionTile (logo, tutar, periyot, yenilenme uyarısı)
- [ ] DebtsBloc + SubscriptionsBloc

### Sprint 6 — Raporlar + Fiş Tarama (5 gün)

**Backend:**
- [ ] `GET /api/reports/expense-distribution` — kategori bazlı aggregate
- [ ] `GET /api/reports/cash-flow` — aylık gelir/gider gruplu veri
- [ ] `POST /api/receipts/scan` — görsel yükleme + OCR entegrasyonu (Google Vision veya Tesseract)
- [ ] Receipt entity + OCR sonuç parse

**Frontend:**
- [ ] ReportsPage (dönem filtreleri)
- [ ] DonutChart (fl_chart PieChart — harcama dağılımı)
- [ ] BarChart (fl_chart BarChart — aylık nakit akışı)
- [ ] CategoryBreakdown listesi
- [ ] ReceiptScannerPage (kamera + overlay çerçeve)
- [ ] OCR sonucu → otomatik işlem oluşturma akışı
- [ ] ReportsBloc + ReceiptBloc

### Sprint 7 — Ayarlar + Profil + Son Dokunuşlar (4 gün)

**Backend:**
- [ ] `PATCH /api/users/me` — profil güncelleme
- [ ] `PATCH /api/users/me/avatar` — dosya yükleme (S3 veya local storage)
- [ ] `PATCH /api/users/me/settings` — dil, para birimi, bildirim tercihleri
- [ ] `PATCH /api/users/me/password` — mevcut şifre doğrulama + değiştirme

**Frontend:**
- [ ] SettingsPage (gruplu ayar listesi)
- [ ] EditProfilePage (avatar değiştirme, ad/e-posta)
- [ ] Biyometrik giriş entegrasyonu (local_auth)
- [ ] Dil değiştirme (l10n)
- [ ] Para birimi değiştirme

### Sprint 8 — Test + Optimizasyon + Yayın Hazırlığı (5 gün)

- [ ] Backend unit testler (her service için)
- [ ] Backend e2e testler (auth akışı, transaction CRUD)
- [ ] Flutter widget testleri
- [ ] Flutter integration testleri (kritik akışlar)
- [ ] Performance optimizasyonu (lazy loading, pagination, image caching)
- [ ] Error handling ve boş durum ekranları (empty state)
- [ ] Shimmer loading animasyonları
- [ ] App icon, splash screen
- [ ] Android/iOS store hazırlıkları

---

## 6. Teknik Kararlar ve Notlar

### 6.1 Kimlik Doğrulama Stratejisi
Access token (15dk) + Refresh token (7 gün) yapısı kullanılacak. Access token her API isteğinde header'da gönderilir. Süresi dolduğunda Dio interceptor otomatik olarak refresh endpoint'ini çağırır.

### 6.2 Bakiye Hesaplama
Her işlem eklendiğinde/silindiğinde ilgili hesabın `balance` alanı bir database transaction içinde güncellenir. Dashboard'daki "Toplam Varlık" tüm aktif hesapların bakiye toplamıdır.

### 6.3 Bütçe Harcama Takibi
`budgets.spent` alanı doğrudan saklanmaz; ilgili kategorideki işlemlerden anlık hesaplanır veya performans için cron job ile periyodik güncellenir.

### 6.4 Fiş Tarama (OCR)
İlk fazda Google ML Kit (on-device) kullanılacak. Daha gelişmiş OCR için backend'de Google Cloud Vision API veya Tesseract entegrasyonu düşünülebilir.

### 6.5 Push Notification
Firebase Cloud Messaging (FCM) entegrasyonu ile bütçe aşımı (%80), borç vade hatırlatma ve abonelik yenilenme bildirimleri gönderilecek.

### 6.6 Tasarım Sistemi Uyum Kuralları
- Asla `#000000` arka plan kullanma → `#131313` kullan
- 1px border yasak → tonal surface geçişleri ile ayır
- Metin rengi asla `#FFFFFF` → `#E5E2E1` (on-surface) kullan
- Primary butonlar pill shape (24px radius)
- Input field'lar: border yok, `surfaceContainerHighest` arka plan, 12px radius

---

## 7. Özet Takvim

| Sprint | Süre | Modül |
|--------|------|-------|
| Sprint 0 | 3 gün | Proje Kurulumu |
| Sprint 1 | 5 gün | Kimlik Doğrulama (Auth) |
| Sprint 2 | 5 gün | Hesaplar + Dashboard |
| Sprint 3 | 5 gün | İşlemler (Transactions) |
| Sprint 4 | 4 gün | Bütçeler (Budgets) |
| Sprint 5 | 5 gün | Borçlar + Abonelikler |
| Sprint 6 | 5 gün | Raporlar + Fiş Tarama |
| Sprint 7 | 4 gün | Ayarlar + Profil |
| Sprint 8 | 5 gün | Test + Optimizasyon |
| **Toplam** | **~41 iş günü** | **~8-9 hafta** |

---

## 8. Detaylı Modül Kurguları

> Bu bölüm Hesaplar, İşlemler, Borç/Alacak, Abonelikler ve Bütçe modüllerinin
> iş mantığını, veri akışlarını ve birbirleriyle olan entegrasyonlarını tanımlar.

---

### 8.0 HESAPLAR MODÜLÜ (Accounts) — Detaylı Kurgu

#### 8.0.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Kredi Kartı Modeli | Akıllı Basitlik | Harcama = anlık gider, ekstre ödemesi = transfer. Bakiye negatif (borç). |
| Kredi Kartı Limit | Limit + basit ekstre | Limit, kesim tarihi, son ödeme tarihi tanımlanır. Ekstre tutarı otomatik hesaplanır. |
| Dashboard | Net varlık göster | Toplam Varlık (banka+nakit+yatırım) ve Net Varlık (kredi kartı borçları düşülmüş) |
| Hesap Silme | Arşivle | Hesap pasif yapılır, listede gizlenir ama işlem geçmişi ve raporlar korunur |
| Varsayılan Hesap | Kullanıcı seçer | Bir hesap "varsayılan" olarak işaretlenir, tüm formlarda ön seçili gelir |
| Hesap Detayı | Detaylı profil | Her hesabın kendi sayfası: işlem geçmişi, giriş/çıkış grafiği, kategori dağılımı |

#### 8.0.2 Hesap Tipleri ve Davranış Farkları

| Tip | Bakiye Anlamı | Dashboard'a Etkisi | Özel Alanlar |
|-----|---------------|--------------------|--------------| 
| `BANK` | Pozitif = sahip olunan para | Toplam Varlık'a eklenir | — |
| `CASH` | Pozitif = fiziksel nakit | Toplam Varlık'a eklenir | — |
| `CREDIT_CARD` | Negatif = bankaya borç | Net Varlık'tan düşülür | `creditLimit`, `statementDay`, `paymentDueDay` |
| `INVESTMENT` | Pozitif = portföy değeri | Toplam Varlık'a eklenir | — |

**Kredi kartı bakiye mantığı:**

```
Kredi Kartı Limiti: ₺10.000
Kullanılan (borç):   ₺3.200  (bakiye: -₺3.200)
Kalan kullanılabilir: ₺6.800  (limit - |bakiye|)

Harcama yapınca:  bakiye -= tutar  (borç artar, daha negatif)
Ödeme yapınca:    bakiye += tutar  (borç azalır, sıfıra yaklaşır)
```

#### 8.0.3 Güncellenmiş Prisma Modeli

```prisma
model Account {
  id              String      @id @default(uuid()) @db.VarChar(36)
  userId          String      @map("user_id") @db.VarChar(36)
  name            String      @db.VarChar(100)              /// "Ziraat Bankası", "Nakit Cüzdan"
  type            AccountType
  balance         Decimal     @default(0.00) @db.Decimal(15, 2)
  icon            String?     @db.VarChar(50)
  color           String?     @db.VarChar(7)
  isActive        Boolean     @default(true) @map("is_active")
  isDefault       Boolean     @default(false) @map("is_default")   /// YENİ
  isArchived      Boolean     @default(false) @map("is_archived")  /// YENİ

  // Kredi kartına özel alanlar
  creditLimit     Decimal?    @map("credit_limit") @db.Decimal(15, 2)   /// YENİ: ₺10.000
  statementDay    Int?        @map("statement_day")                      /// YENİ: ekstre kesim günü (1-28)
  paymentDueDay   Int?        @map("payment_due_day")                    /// YENİ: son ödeme günü (1-28)

  createdAt       DateTime    @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt       DateTime    @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user                  User                   @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions          Transaction[]          @relation("AccountTransactions")
  transfersReceived     Transaction[]          @relation("TransferToAccount")
  recurringTransactions RecurringTransaction[]
  subscriptions         Subscription[]

  @@index([userId, isActive, isArchived], map: "idx_accounts_user_active")
  @@map("accounts")
}
```

#### 8.0.4 İş Akışları

**A) Hesap Oluşturma**

```
Kullanıcı "Hesap Ekle" ekranında:
  ├─ Tip seçer: Banka / Nakit / Kredi Kartı / Yatırım
  ├─ Ad girer: "Ziraat Bankası"
  ├─ Başlangıç bakiyesi: ₺38.500
  ├─ İkon + renk seçer
  │
  ├─ Kredi Kartı seçildiyse ek alanlar:
  │     ├─ Kart limiti: ₺10.000
  │     ├─ Ekstre kesim günü: 15 (her ayın 15'i)
  │     ├─ Son ödeme günü: 5 (bir sonraki ayın 5'i)
  │     └─ Mevcut borç: ₺3.200 (başlangıç bakiyesi: -₺3.200)
  │
  ├─ "Varsayılan hesap yap" toggle (opsiyonel)
  │
  └─ Kaydet:
        ├─ Account oluşturulur
        ├─ "Varsayılan" seçildiyse → diğer hesapların isDefault = false yap
        └─ Kredi kartı ise → balance = -mevcutBorç olarak kaydedilir
```

**B) Kredi Kartı Harcaması (Transaction Hub ile entegre)**

```
Kullanıcı İşlem Ekle → Hesap: "Yapı Kredi Kartı" seçer
  │
  ├─ TransactionsService.create():
  │     type: EXPENSE
  │     source: MANUAL
  │     amount: ₺450
  │     accountId: krediKartı.id
  │
  ├─ Account.balance -= 450  →  -₺3.200 → -₺3.650 (borç arttı)
  │
  ├─ Limit kontrolü:
  │     |balance| > creditLimit?  →  ₺3.650 < ₺10.000 ✓ OK
  │     |balance| > creditLimit * 0.80?  →  Uyarı bildirimi
  │
  ├─ Bütçe event'i tetiklenir (Market bütçesi güncellenir)
  │
  └─ Dashboard güncellenir:
        Toplam Varlık: ₺38.500 + ₺6.100 = ₺44.600 (CC dahil değil)
        Kredi Kartı Borcu: ₺3.650
        Net Varlık: ₺44.600 - ₺3.650 = ₺40.950
```

**C) Kredi Kartı Ekstre Ödemesi**

```
Kullanıcı "Transfer" işlemi oluşturur:
  ├─ Kaynak: Ziraat Bankası
  ├─ Hedef: Yapı Kredi Kartı
  ├─ Tutar: ₺3.650 (ekstre tutarı)
  │
  └─ TransactionsService.create():
        type: TRANSFER
        source: MANUAL
        amount: 3.650
        accountId: ziraat.id (kaynak)
        transferToAccountId: yapiKredi.id (hedef)

        ├─ Ziraat.balance -= 3.650  →  ₺38.500 → ₺34.850
        ├─ YapıKredi.balance += 3.650  →  -₺3.650 → ₺0 (borç kapandı)
        │
        └─ NOT: Transfer olduğu için bütçeyi ETKİLEMEZ
              (gider değil, sadece para yer değiştirdi)
```

**D) Basit Ekstre Hesaplama**

```
Her ayın statementDay'inde (örn: 15'i):
  │
  ├─ O dönemdeki kredi kartı EXPENSE işlemlerini topla
  │   (önceki ekstre kesim → bu ekstre kesim arası)
  │
  ├─ Ekstre tutarı = toplam
  ├─ Son ödeme tarihi = paymentDueDay (sonraki ayın 5'i)
  │
  └─ Bildirim gönder:
        "Yapı Kredi kartı ekstreniz hazır: ₺2.450
         Son ödeme: 5 Haziran 2026"
```

**E) Hesap Arşivleme**

```
Kullanıcı "Hesabı Kaldır" butonuna basar:
  │
  ├─ isArchived = true
  ├─ isActive = false
  ├─ isDefault = false (varsayılansa, bir sonraki hesap varsayılan olur)
  │
  ├─ Hesap artık:
  │     ✗ Hesap listesinde görünmez
  │     ✗ Yeni işlem eklenirken seçilemez
  │     ✗ Abonelik bağlanamaz
  │     ✓ Geçmiş işlemler "Ziraat Bankası (arşiv)" olarak görünür
  │     ✓ Raporlarda geçmiş veriler korunur
  │
  └─ "Geri Getir" ile isArchived = false yapılabilir
```

**F) Varsayılan Hesap**

```
Varsayılan hesap şu ekranlarda ön seçili gelir:
  ├─ İşlem Ekle → Hesap seçici'de varsayılan seçili
  ├─ Abonelik Ekle → Hesap seçici'de varsayılan seçili
  ├─ Borç Ödeme → Hesap seçici'de varsayılan seçili
  └─ Transfer → Kaynak hesap olarak varsayılan seçili

Kurallar:
  ├─ Kullanıcı başına sadece 1 varsayılan hesap
  ├─ Kredi kartı varsayılan olabilir (bazı kullanıcılar her şeyi kartla öder)
  ├─ Varsayılan hesap arşivlenirse → bir sonraki aktif hesap otomatik varsayılan olur
  └─ Hiç hesap yoksa → ilk eklenen otomatik varsayılan olur
```

#### 8.0.5 Dashboard — Net Varlık Hesaplaması

```
Dashboard Üst Kart (BalanceCard):
  │
  ├─ TOPLAM VARLIK (büyük font):
  │     = SUM(balance) WHERE type IN (BANK, CASH, INVESTMENT) AND isArchived = false
  │     → ₺44.600
  │
  ├─ KREDİ KARTI BORCU (küçük, kırmızı):
  │     = ABS(SUM(balance)) WHERE type = CREDIT_CARD AND balance < 0 AND isArchived = false
  │     → -₺3.650
  │
  ├─ NET VARLIK (orta font, altında):
  │     = Toplam Varlık - Kredi Kartı Borcu
  │     → ₺40.950
  │
  └─ AYLIK DEĞİŞİM:
        = Bu ayın net varlığı - geçen ayın net varlığı
        → +₺3.840 (yeşil, yukarı ok)
```

#### 8.0.6 Hesap Detay Sayfası

```
AccountDetailPage (her hesap tipine özel)
│
├── Üst Kart:
│     ├── Hesap adı + ikon + renk
│     ├── Bakiye (büyük font)
│     ├── [Kredi Kartı] Limit: ₺10.000 | Kullanılan: ₺3.650 | Kalan: ₺6.350
│     ├── [Kredi Kartı] Sonraki ekstre: 15 Haz | Son ödeme: 5 Tem
│     └── Bu ay giriş/çıkış: +₺12.400 / -₺3.860
│
├── Aylık Giriş/Çıkış Mini Grafiği (son 6 ay, bar chart)
│
├── En Çok Harcama Kategorileri (bu hesaptan, pie chart mini)
│
├── İşlem Geçmişi (bu hesaba ait, tarihe göre gruplu)
│     ├─ Tüm source'lar dahil (MANUAL, SUBSCRIPTION, DEBT_PAYMENT...)
│     └─ Filtre: Hepsi / Gelir / Gider / Transfer
│
├── [Kredi Kartı] "Ekstre Öde" kısayol butonu → Transfer ekranı (hedef: bu kart)
│
└── Ayarlar:
      ├─ "Varsayılan Yap" toggle
      ├─ "Düzenle" (ad, ikon, renk, limit)
      └─ "Arşivle" butonu
```

#### 8.0.7 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/accounts` | Aktif hesaplar (arşivlenmiş hariç) |
| `GET` | `/api/accounts?includeArchived=true` | Arşivlenmiş dahil tüm hesaplar |
| `GET` | `/api/accounts/:id` | Hesap detayı |
| `GET` | `/api/accounts/:id/transactions` | Bu hesabın işlem geçmişi |
| `GET` | `/api/accounts/:id/analytics` | Bu hesabın aylık giriş/çıkış + kategori dağılımı |
| `GET` | `/api/accounts/summary` | Toplam varlık, CC borcu, net varlık |
| `POST` | `/api/accounts` | Yeni hesap ekle (CC ise limit + kesim/ödeme günleri dahil) |
| `PATCH` | `/api/accounts/:id` | Hesap güncelle |
| `PATCH` | `/api/accounts/:id/archive` | Hesabı arşivle |
| `PATCH` | `/api/accounts/:id/restore` | Arşivden geri getir |
| `PATCH` | `/api/accounts/:id/set-default` | Varsayılan hesap yap |
| `GET` | `/api/accounts/:id/statement` | [CC] Mevcut ekstre özeti (tutar, dönem, son ödeme) |

#### 8.0.8 Kredi Kartı Ekstre Cron Job

```
Cron Job (her gün 08:00): CreditCardStatementJob
  │
  ├─ Bugün hangi kartların ekstre kesim günü?
  │   WHERE type = CREDIT_CARD AND statementDay = TODAY.day AND isArchived = false
  │
  └─ Her kart için:
        ├─ Dönem: önceki kesim tarihi → bugün
        ├─ EXPENSE toplamı hesapla (bu dönemdeki harcamalar)
        ├─ Bildirim gönder:
        │     "Yapı Kredi ekstre: ₺2.450 — Son ödeme: 5 Haz"
        │
        └─ Limit uyarısı:
              |balance| > creditLimit * 0.80 → "Kart limitinizin %82'sini kullandınız"
```

---

### 8.1 İŞLEMLER MODÜLÜ (Transactions) — Genişletilmiş Kurgu

#### 8.1.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Tekrarlayan İşlemler | Otomatik oluşsun | Kullanıcı bir işlemi "tekrarlayan" işaretler; sistem periyotta otomatik kaydeder |
| Etiket Sistemi | Çoklu tag | Bir işlem birden fazla etikete sahip olabilir (Market + Temel İhtiyaç) |
| Bakiye Güncelleme | Anlık | İşlem kaydedildiği anda hesap bakiyesi güncellenir |

#### 8.1.2 Yeni Prisma Modelleri

```prisma
// =============================================
// ETİKETLER (Tag Sistemi — Çoklu Kategori)
// =============================================

model Tag {
  id        String   @id @default(uuid()) @db.VarChar(36)
  userId    String?  @map("user_id") @db.VarChar(36)          /// NULL = sistem etiketi
  name      String   @db.VarChar(50)                    /// "Temel İhtiyaç", "Sabit Gider"
  icon      String?  @db.VarChar(50)
  color     String   @db.VarChar(7)
  isSystem  Boolean  @default(false) @map("is_system")
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user         User?            @relation(fields: [userId], references: [id], onDelete: Cascade)
  transactions TransactionTag[]

  @@unique([userId, name])
  @@map("tags")
}

model TransactionTag {
  transactionId String @map("transaction_id") @db.VarChar(36)
  tagId         String @map("tag_id") @db.VarChar(36)

  transaction Transaction @relation(fields: [transactionId], references: [id], onDelete: Cascade)
  tag         Tag         @relation(fields: [tagId], references: [id], onDelete: Cascade)

  @@id([transactionId, tagId])
  @@map("transaction_tags")
}

// =============================================
// TEKRARLAYAN İŞLEM ŞABLONLARI
// =============================================

enum RecurrenceFrequency {
  DAILY
  WEEKLY
  MONTHLY
  YEARLY
}

model RecurringTransaction {
  id            String              @id @default(uuid()) @db.VarChar(36)
  userId        String              @map("user_id") @db.VarChar(36)
  accountId     String              @map("account_id") @db.VarChar(36)
  categoryId    String?             @map("category_id") @db.VarChar(36)
  type          TransactionType
  amount        Decimal             @db.Decimal(15, 2)
  title         String              @db.VarChar(200)     /// "Kira Ödemesi"
  note          String?             @db.Text
  frequency     RecurrenceFrequency                      /// MONTHLY, WEEKLY, vb.
  startDate     DateTime            @map("start_date") @db.Date
  endDate       DateTime?           @map("end_date") @db.Date   /// NULL = süresiz
  nextRunDate   DateTime            @map("next_run_date") @db.Date
  isActive      Boolean             @default(true) @map("is_active")
  createdAt     DateTime            @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime            @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  account  Account   @relation(fields: [accountId], references: [id])
  category Category? @relation(fields: [categoryId], references: [id])

  @@index([nextRunDate, isActive], map: "idx_recurring_next_run")
  @@map("recurring_transactions")
}
```

> **Not:** Mevcut `Transaction` modeline `tags TransactionTag[]` ilişkisi eklenir.
> `Account` modeline `recurringTransactions RecurringTransaction[]` ilişkisi eklenir.

#### 8.1.3 İş Akışları

**A) Normal İşlem Ekleme**

```
Kullanıcı "Kaydet"e basar
  │
  ├─ 1. Validasyon (tutar > 0, kategori seçili, hesap seçili)
  │
  ├─ 2. Prisma $transaction bloğu başlar:
  │     ├─ Transaction kaydı oluşturulur
  │     ├─ TransactionTag kayıtları oluşturulur (seçilen tag'ler)
  │     ├─ Account.balance güncellenir:
  │     │     income  → balance += amount
  │     │     expense → balance -= amount
  │     │     transfer → source -= amount, target += amount
  │     └─ İlgili Budget varsa → spent yeniden hesaplanır
  │
  └─ 3. Response: oluşturulan Transaction + güncel bakiye
```

**B) Tekrarlayan İşlem Oluşturma**

```
Kullanıcı "İşlem Ekle" ekranında "Tekrarlayan" toggle'ını açar
  │
  ├─ Frekans seçer: Günlük / Haftalık / Aylık / Yıllık
  ├─ Başlangıç tarihi (varsayılan: bugün)
  ├─ Bitiş tarihi (opsiyonel — boş = süresiz)
  │
  ├─ Kaydet → İlk işlem hemen oluşturulur (normal akış)
  │           + RecurringTransaction şablonu kaydedilir
  │           + nextRunDate hesaplanır
  │
  └─ Cron Job (her gün 00:05'te çalışır):
        ├─ WHERE nextRunDate <= TODAY AND isActive = true
        ├─ Her şablon için:
        │     ├─ Transaction oluştur (normal akış — bakiye güncelle)
        │     ├─ nextRunDate'i bir sonraki periyoda taşı
        │     └─ endDate geçtiyse → isActive = false yap
        └─ Log: kaç işlem otomatik oluşturuldu
```

**C) İşlem Silme / Güncelleme**

```
Silme:
  ├─ Prisma $transaction bloğu:
  │     ├─ Eski tutarı bakiyeye geri ekle/çıkar
  │     ├─ TransactionTag kayıtları cascade ile silinir
  │     └─ Transaction silinir
  └─ İlgili Budget.spent yeniden hesaplanır

Güncelleme:
  ├─ Eski tutar farkı hesaplanır (yeniTutar - eskiTutar)
  ├─ Bakiye farka göre güncellenir
  ├─ Tag'ler: eski silinir, yeni eklenir
  └─ Budget.spent yeniden hesaplanır
```

#### 8.1.4 Yeni API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/transactions` | İşlem listesi (filtre: type, categoryId, accountId, tagIds[], dateRange, search) |
| `POST` | `/api/transactions` | Yeni işlem ekle (tagIds[] dahil, isRecurring + recurrence opsiyonel) |
| `GET` | `/api/recurring-transactions` | Tekrarlayan işlem şablonları |
| `POST` | `/api/recurring-transactions` | Yeni tekrarlayan işlem şablonu |
| `PATCH` | `/api/recurring-transactions/:id` | Şablonu güncelle (tutar, frekans değiştir) |
| `DELETE` | `/api/recurring-transactions/:id` | Şablonu durdur/sil |
| `GET` | `/api/tags` | Kullanıcının tüm etiketleri |
| `POST` | `/api/tags` | Yeni etiket oluştur |
| `DELETE` | `/api/tags/:id` | Etiket sil |

#### 8.1.5 Flutter — İşlem Ekleme Ekranı Akışı

```
AddTransactionPage
├── Gider / Gelir segment control (toggle)
├── Miktar girişi (₺ formatı, büyük font)
├── Kategori seçici (grid — Market/Ulaşım/Eğlence/Sağlık/Alışveriş)
├── Tag seçici (chip listesi — çoklu seçim, + ile yeni tag ekleme)
├── Hesap seçici (horizontal chip'ler — Ziraat/Nakit/...)
├── İşlem başlığı (text input)
├── Not (opsiyonel text area)
├── Tekrarlayan toggle:
│     └── Açılırsa → Frekans dropdown (Günlük/Haftalık/Aylık/Yıllık)
│                   + Bitiş tarihi (opsiyonel date picker)
└── "Kaydet" butonu
```

---

### 8.2 BORÇ / ALACAK MODÜLÜ (Debts) — Genişletilmiş Kurgu

#### 8.2.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Taksit Desteği | Evet | Bir borç birden fazla taksite bölünebilir, her taksitin kendi vadesi var |
| Kısmi Ödeme | Evet | Her borç/taksit için ödeme geçmişi tutulur, kalan otomatik hesaplanır |
| Sosyal Özellik | Hayır | Tamamen kişisel takip, başkasına bildirim gönderilmez |

#### 8.2.2 Yeni Prisma Modelleri

```prisma
// =============================================
// BORÇ TAKİBİ — GENİŞLETİLMİŞ
// =============================================

model Debt {
  id            String     @id @default(uuid()) @db.VarChar(36)
  userId        String     @map("user_id") @db.VarChar(36)
  personName    String     @map("person_name") @db.VarChar(100)
  type          DebtType                                    /// LENT (alacak) / BORROWED (borç)
  totalAmount   Decimal    @map("total_amount") @db.Decimal(15, 2)  /// toplam borç tutarı
  paidAmount    Decimal    @default(0.00) @map("paid_amount") @db.Decimal(15, 2) /// ödenen toplam
  status        DebtStatus @default(PENDING)
  dueDate       DateTime?  @map("due_date") @db.Date       /// son vade (taksitsiz borçlar için)
  note          String?    @db.Text
  hasInstallments Boolean  @default(false) @map("has_installments")
  createdAt     DateTime   @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime   @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user         User              @relation(fields: [userId], references: [id], onDelete: Cascade)
  installments DebtInstallment[]
  payments     DebtPayment[]

  @@map("debts")
}

// =============================================
// TAKSİTLER
// =============================================

model DebtInstallment {
  id              String     @id @default(uuid()) @db.VarChar(36)
  debtId          String     @map("debt_id") @db.VarChar(36)
  installmentNo   Int        @map("installment_no")         /// 1, 2, 3, ... (sıra numarası)
  amount          Decimal    @db.Decimal(15, 2)              /// bu taksitin tutarı
  paidAmount      Decimal    @default(0.00) @map("paid_amount") @db.Decimal(15, 2)
  dueDate         DateTime   @map("due_date") @db.Date       /// bu taksitin vade tarihi
  status          DebtStatus @default(PENDING)
  createdAt       DateTime   @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  debt     Debt          @relation(fields: [debtId], references: [id], onDelete: Cascade)
  payments DebtPayment[]

  @@unique([debtId, installmentNo])
  @@index([dueDate, status], map: "idx_installment_due")
  @@map("debt_installments")
}

// =============================================
// ÖDEME GEÇMİŞİ
// =============================================

model DebtPayment {
  id              String   @id @default(uuid()) @db.VarChar(36)
  debtId          String   @map("debt_id") @db.VarChar(36)
  installmentId   String?  @map("installment_id") @db.VarChar(36)  /// NULL = taksitsiz borç ödemesi
  amount          Decimal  @db.Decimal(15, 2)
  paidAt          DateTime @default(now()) @map("paid_at") @db.Timestamp(0)
  note            String?  @db.Text
  createdAt       DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  debt        Debt             @relation(fields: [debtId], references: [id], onDelete: Cascade)
  installment DebtInstallment? @relation(fields: [installmentId], references: [id], onDelete: Cascade)

  @@map("debt_payments")
}
```

#### 8.2.3 İş Akışları

**A) Taksitsiz Borç Oluşturma**

```
Kullanıcı "Borç Ekle" ekranında:
  ├─ Tip seçer: Alacak (LENT) / Borç (BORROWED)
  ├─ Kişi/kurum adı girer: "Ahmet Yılmaz"
  ├─ Toplam tutar girer: ₺2.500
  ├─ Vade tarihi seçer (opsiyonel)
  ├─ "Taksitli mi?" → Hayır
  └─ Kaydet → Debt oluşturulur (hasInstallments = false)
```

**B) Taksitli Borç Oluşturma**

```
Kullanıcı "Taksitli mi?" → Evet seçer
  ├─ Toplam tutar: ₺12.000
  ├─ Taksit sayısı: 12
  ├─ İlk taksit tarihi: 20 Mayıs 2026
  │
  └─ Kaydet → Prisma $transaction bloğu:
        ├─ Debt oluşturulur (hasInstallments = true, totalAmount = 12.000)
        └─ 12 adet DebtInstallment oluşturulur:
              ├─ installmentNo: 1, amount: 1.000, dueDate: 20 May 2026
              ├─ installmentNo: 2, amount: 1.000, dueDate: 20 Haz 2026
              ├─ ...
              └─ installmentNo: 12, amount: 1.000, dueDate: 20 Nis 2027
```

**C) Kısmi Ödeme Kaydetme**

```
Kullanıcı borç detayında "Ödeme Yap" butonuna basar
  │
  ├─ Taksitsiz borç:
  │     ├─ Tutar girer: ₺1.000 (toplam ₺2.500'den)
  │     ├─ Kaydet → Prisma $transaction bloğu:
  │     │     ├─ DebtPayment oluşturulur (amount: 1.000)
  │     │     ├─ Debt.paidAmount += 1.000 → paidAmount: 1.000
  │     │     └─ Kalan: 2.500 - 1.000 = ₺1.500 → status hâlâ PENDING
  │     └─ paidAmount >= totalAmount olursa → status = PAID
  │
  └─ Taksitli borç:
        ├─ Hangi taksit? → Taksit #3 seçilir (₺1.000)
        ├─ Tutar girer: ₺600 (kısmi)
        ├─ Kaydet → Prisma $transaction bloğu:
        │     ├─ DebtPayment oluşturulur (installmentId: taksit3.id)
        │     ├─ DebtInstallment.paidAmount += 600
        │     ├─ Debt.paidAmount += 600
        │     └─ Taksit.paidAmount >= Taksit.amount → Taksit.status = PAID
        └─ Tüm taksitler PAID olursa → Debt.status = PAID
```

**D) Gecikme Kontrolü (Cron Job — Her gün 00:10)**

```
Cron Job:
  ├─ Taksitsiz borçlar:
  │     WHERE dueDate < TODAY AND status = PENDING
  │     → status = OVERDUE olarak güncelle
  │
  └─ Taksitli borçlar:
        DebtInstallment WHERE dueDate < TODAY AND status = PENDING
        → Installment.status = OVERDUE
        → Parent Debt'in en az bir taksiti OVERDUE ise → Debt.status = OVERDUE
```

#### 8.2.4 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/debts` | Borç listesi (filtre: type, status) |
| `GET` | `/api/debts/summary` | Alacak toplamı, borç toplamı, net |
| `GET` | `/api/debts/:id` | Borç detayı (taksitler + ödeme geçmişi dahil) |
| `POST` | `/api/debts` | Yeni borç oluştur (taksitli/taksitsiz) |
| `PATCH` | `/api/debts/:id` | Borç güncelle |
| `DELETE` | `/api/debts/:id` | Borç sil (cascade: taksitler + ödemeler) |
| `POST` | `/api/debts/:id/payments` | Ödeme kaydet (kısmi/tam) |
| `GET` | `/api/debts/:id/payments` | Ödeme geçmişi |
| `GET` | `/api/debts/:id/installments` | Taksit listesi |

#### 8.2.5 Flutter — Borç Modülü Ekranları

```
DebtsPage
├── Özet Kartları (üst bölüm):
│     ├── Alacaklarım kartı (yeşil, toplam + kalan tutar)
│     └── Borçlarım kartı (kırmızı, toplam + kalan tutar)
│
├── Filtre Chip'leri: Tümü / Alacak / Borç / Gecikmiş
│
├── Borç Listesi (gruplu):
│     └── DebtTile:
│           ├── Kişi/kurum adı + avatar/ikon
│           ├── Toplam tutar + kalan tutar
│           ├── Vade tarihi (veya "3/12 taksit ödendi")
│           ├── Progress bar (paidAmount / totalAmount)
│           └── Status badge (Ödendi / Beklemede / Gecikmiş)
│
├── FAB (+) → AddDebtPage
│
└── Borç Detay (tıklandığında):
      DebtDetailPage
      ├── Üst kart: kişi adı, toplam, kalan, durum
      ├── Taksit listesi (varsa):
      │     └── InstallmentTile: #no, tutar, vade, durum, ödenen
      ├── Ödeme geçmişi timeline
      └── "Ödeme Yap" butonu → PaymentBottomSheet
            ├── Taksit seçici (taksitliyse)
            ├── Tutar girişi
            ├── Not (opsiyonel)
            └── "Kaydet" butonu
```

---

### 8.3 ABONELİKLER MODÜLÜ (Subscriptions) — Genişletilmiş Kurgu

#### 8.3.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| İşlem Bağlantısı | Otomatik oluşsun | Yenilenme tarihinde otomatik gider işlemi oluşturulur |
| Bakiye Güncelleme | Anlık | Abonelik yenilendiğinde hesap bakiyesi anında düşer |

#### 8.3.2 Güncellenmiş Prisma Modeli

```prisma
model Subscription {
  id          String             @id @default(uuid()) @db.VarChar(36)
  userId      String             @map("user_id") @db.VarChar(36)
  name        String             @db.VarChar(100)
  amount      Decimal            @db.Decimal(15, 2)
  period      SubscriptionPeriod @default(MONTHLY)
  icon        String?            @db.VarChar(50)
  color       String?            @db.VarChar(7)
  startDate   DateTime           @map("start_date") @db.Date
  nextRenewal DateTime           @map("next_renewal") @db.Date   /// artık zorunlu
  accountId   String             @map("account_id") @db.VarChar(36)     /// YENİ: hangi hesaptan düşülecek
  categoryId  String?            @map("category_id") @db.VarChar(36)
  isActive    Boolean            @default(true) @map("is_active")
  autoDeduct  Boolean            @default(true) @map("auto_deduct") /// YENİ: otomatik işlem oluştursun mu
  createdAt   DateTime           @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt   DateTime           @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  user     User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  account  Account   @relation(fields: [accountId], references: [id])
  category Category? @relation(fields: [categoryId], references: [id])

  @@index([nextRenewal, isActive], map: "idx_subscription_renewal")
  @@map("subscriptions")
}
```

> **Değişiklikler:** `accountId` zorunlu alan olarak eklendi (hangi hesaptan düşüleceğini belirler).
> `autoDeduct` alanı eklendi. `nextRenewal` artık zorunlu.
> `Account` modeline `subscriptions Subscription[]` ilişkisi eklenir.

#### 8.3.3 İş Akışları

**A) Abonelik Oluşturma**

```
Kullanıcı "Abonelik Ekle" ekranında:
  ├─ Abonelik adı: "Netflix"
  ├─ Tutar: ₺149,99
  ├─ Periyot: Aylık / Haftalık / Yıllık
  ├─ Başlangıç tarihi: 15 Nis 2026
  ├─ Hesap seçimi: "Ziraat Bankası" (bakiyeden düşülecek hesap)
  ├─ Kategori: "Eğlence" (opsiyonel)
  ├─ Otomatik işlem oluştursun mu? → Evet (varsayılan)
  │
  └─ Kaydet:
        ├─ Subscription oluşturulur
        ├─ nextRenewal hesaplanır:
        │     startDate + period → 15 May 2026
        └─ İlk işlem hemen oluşturulmaz (bir sonraki yenilenme tarihinde)
```

**B) Otomatik Yenilenme (Cron Job — Her gün 00:15)**

```
Cron Job:
  ├─ SELECT * FROM subscriptions
  │   WHERE nextRenewal <= TODAY AND isActive = true AND autoDeduct = true
  │
  ├─ Her abonelik için → Prisma $transaction bloğu:
  │     ├─ Transaction oluştur:
  │     │     type: EXPENSE
  │     │     amount: subscription.amount
  │     │     title: "Netflix — Aylık abonelik"
  │     │     accountId: subscription.accountId
  │     │     categoryId: subscription.categoryId
  │     │
  │     ├─ Account.balance -= subscription.amount
  │     │
  │     ├─ nextRenewal güncelle:
  │     │     MONTHLY → nextRenewal + 1 ay
  │     │     WEEKLY  → nextRenewal + 1 hafta
  │     │     YEARLY  → nextRenewal + 1 yıl
  │     │
  │     └─ İlgili Budget varsa → spent yeniden hesapla
  │
  └─ Push notification gönder:
        "Netflix aboneliğiniz yenilendi: -₺149,99 (Ziraat Bankası)"
```

**C) Yaklaşan Yenilenme Bildirimi (Cron Job — Her gün 09:00)**

```
Cron Job:
  ├─ SELECT * FROM subscriptions
  │   WHERE nextRenewal = TOMORROW AND isActive = true
  │
  └─ Her biri için push notification:
        "Netflix aboneliğiniz yarın yenilenecek: ₺149,99"
        (Bu tasarımda da "⚠ Yarın yenilenecek" etiketi olarak gösterilir)
```

**D) Abonelik İptal Etme**

```
Kullanıcı "İptal Et" butonuna basar:
  ├─ isActive = false yapılır
  ├─ Gelecek otomatik işlemler oluşturulmaz
  └─ Geçmiş işlemler korunur (silinmez)
```

#### 8.3.4 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/subscriptions` | Abonelik listesi (filtre: isActive) |
| `GET` | `/api/subscriptions/summary` | Aylık toplam, aktif sayısı, yaklaşan yenilenme |
| `GET` | `/api/subscriptions/:id` | Abonelik detayı |
| `POST` | `/api/subscriptions` | Yeni abonelik ekle (accountId zorunlu) |
| `PATCH` | `/api/subscriptions/:id` | Abonelik güncelle (tutar, hesap, periyot) |
| `PATCH` | `/api/subscriptions/:id/toggle` | Aktif/Pasif toggle |
| `DELETE` | `/api/subscriptions/:id` | Abonelik sil |
| `GET` | `/api/subscriptions/upcoming` | Önümüzdeki 7 gün içinde yenilenecekler |

#### 8.3.5 Flutter — Abonelik Modülü Ekranları

```
SubscriptionsPage
├── Özet Kartı (üst bölüm):
│     ├── Aylık toplam gider (büyük font — ₺845,90)
│     ├── Aktif abonelik sayısı badge'i
│     └── Haftalık / Aylık / Yıllık breakdown (opsiyonel)
│
├── "Yaklaşan Yenilenme" uyarı bandı:
│     └── "Netflix yarın yenilenecek — ₺149,99" (turuncu uyarı)
│
├── Aktif Abonelikler Listesi:
│     └── SubscriptionTile:
│           ├── İkon/logo (renkli daire)
│           ├── Abonelik adı
│           ├── Tutar + periyot etiketi (₺149,99 / AYLIK)
│           ├── Sonraki yenilenme tarihi
│           ├── "⚠ Yarın yenilenecek" etiketi (varsa)
│           └── Bağlı hesap adı (küçük metin)
│
├── FAB (+) → AddSubscriptionPage
│
└── Abonelik Detay (tıklandığında):
      SubscriptionDetailPage
      ├── Üst kart: ad, tutar, periyot, hesap, durum
      ├── Geçmiş işlemler listesi (otomatik oluşturulan transaction'lar)
      ├── "Düzenle" butonu
      └── "İptal Et" butonu (kırmızı)
```

---

### 8.4 Merkezi Mimari: Transaction Hub Modeli

#### 8.4.1 Temel Prensip

**Transaction (İşlem) tüm para hareketlerinin tek gerçek kaynağıdır (Single Source of Truth).**

Kullanıcı ister manuel işlem eklesin, ister borç ödesin, ister abonelik yenilensin — her para hareketi
sonuçta bir `Transaction` kaydı oluşturur. Bu sayede:

- Bakiye **her zaman** Transaction'lar üzerinden hesaplanır
- Raporlar **tek tablodan** çekilir (filtreleme ile kaynak ayrıştırılır)
- Bütçe takibi **tek noktadan** tetiklenir

#### 8.4.2 Transaction Source (Kaynak) Alanı

Transaction'ın `type` alanı hâlâ INCOME / EXPENSE / TRANSFER olarak kalır.
Yeni eklenen `source` alanı para hareketinin **nereden geldiğini** belirtir:

```prisma
enum TransactionSource {
  MANUAL          // Kullanıcı elle ekledi
  RECURRING       // Tekrarlayan işlem şablonundan otomatik oluştu
  DEBT_PAYMENT    // Borç ödemesi sonucu oluştu (EXPENSE)
  DEBT_COLLECTION // Alacak tahsilatı sonucu oluştu (INCOME — ama gerçek gelir değil)
  SUBSCRIPTION    // Abonelik yenilemesi sonucu oluştu (EXPENSE)
}
```

**Transaction modeline eklenen alanlar:**

```prisma
model Transaction {
  // ... mevcut alanlar ...

  source          TransactionSource @default(MANUAL)
  relatedDebtId   String?           @map("related_debt_id") @db.VarChar(36)
  relatedSubId    String?           @map("related_subscription_id") @db.VarChar(36)

  // İlişkiler (opsiyonel — kaynağa geri referans)
  relatedDebt         Debt?         @relation(fields: [relatedDebtId], references: [id])
  relatedSubscription Subscription? @relation(fields: [relatedSubId], references: [id])
}
```

**Neden önemli?**

| Durum | type | source | Raporda gösterimi |
|-------|------|--------|-------------------|
| Kullanıcı maaş ekledi | INCOME | MANUAL | ✅ Gerçek gelir |
| Kullanıcı markete gitti | EXPENSE | MANUAL | ✅ Gerçek gider |
| Ahmet borcunu ödedi (alacak tahsilatı) | INCOME | DEBT_COLLECTION | ⚠️ Gerçek gelir DEĞİL — daha önce verilen paranın geri dönüşü |
| Ziraat kredisi taksiti ödendi | EXPENSE | DEBT_PAYMENT | ✅ Gerçek gider (borç ödemesi) |
| Netflix yenilendi | EXPENSE | SUBSCRIPTION | ✅ Gerçek gider (abonelik) |
| Kira otomatik oluştu | EXPENSE | RECURRING | ✅ Gerçek gider (tekrarlayan) |

Raporlarda "Gerçek Gelir" hesaplarken: `WHERE type = INCOME AND source != DEBT_COLLECTION`
Böylece kullanıcı "Bu ay ₺12.000 kazandım" derken alacak tahsilatları karışmaz.

#### 8.4.3 Borç/Alacak ↔ İşlemler Entegrasyonu

**Borç Ödeme Yapıldığında (Kullanıcı borçlu):**

```
Kullanıcı DebtsPage → "Ödeme Yap" butonuna basar
  │
  ├─ Tutar girer: ₺1.200 (Ziraat kredisi taksiti)
  ├─ Hesap seçer: "Ziraat Bankası" (hangi hesaptan ödenecek)
  │
  └─ Kaydet → Prisma $transaction bloğu:
        │
        ├─ 1. DebtPayment oluştur
        │     amount: 1.200, debtId: xxx, installmentId: yyy
        │
        ├─ 2. Transaction oluştur (OTOMATİK):
        │     type: EXPENSE
        │     source: DEBT_PAYMENT
        │     amount: 1.200
        │     title: "Borç Ödemesi — Ziraat Bankası (Kredi) [Taksit 3/12]"
        │     accountId: kullanıcının seçtiği hesap
        │     categoryId: "Borç Ödemeleri" (sistem kategorisi)
        │     relatedDebtId: xxx
        │
        ├─ 3. Account.balance -= 1.200 (anlık güncelleme)
        │
        ├─ 4. Debt.paidAmount += 1.200
        │     DebtInstallment.paidAmount += 1.200
        │     Status kontrolü (PAID oldu mu?)
        │
        └─ 5. TransactionCreatedEvent emit → BudgetService dinler
```

**Alacak Tahsil Edildiğinde (Kullanıcı alacaklı):**

```
Kullanıcı DebtsPage → Ahmet Yılmaz → "Ödeme Aldım" butonuna basar
  │
  ├─ Tutar girer: ₺1.000 (₺2.500 alacağın kısmi tahsilatı)
  ├─ Hesap seçer: "Nakit" (paranın girdiği hesap)
  │
  └─ Kaydet → Prisma $transaction bloğu:
        │
        ├─ 1. DebtPayment oluştur
        │
        ├─ 2. Transaction oluştur (OTOMATİK):
        │     type: INCOME
        │     source: DEBT_COLLECTION   ← gerçek gelir değil!
        │     amount: 1.000
        │     title: "Alacak Tahsilatı — Ahmet Yılmaz"
        │     accountId: kullanıcının seçtiği hesap
        │     relatedDebtId: xxx
        │
        ├─ 3. Account.balance += 1.000
        │
        └─ 4. Debt.paidAmount += 1.000
              Status kontrolü
```

#### 8.4.4 Abonelik ↔ İşlemler Entegrasyonu

**Abonelik İlk Satın Alındığında:**

```
Kullanıcı "Abonelik Ekle" → Netflix, ₺149,99, Aylık, Ziraat Bankası
  │
  └─ Kaydet → Prisma $transaction bloğu:
        │
        ├─ 1. Subscription oluştur (nextRenewal = startDate + 1 ay)
        │
        ├─ 2. İlk Transaction oluştur:
        │     type: EXPENSE
        │     source: SUBSCRIPTION
        │     amount: 149.99
        │     title: "Netflix — Abonelik başlatıldı"
        │     accountId: Ziraat Bankası
        │     categoryId: Eğlence
        │     relatedSubId: subscription.id
        │
        ├─ 3. Account.balance -= 149.99
        │
        └─ 4. TransactionCreatedEvent emit → BudgetService
```

**Periyodik Yenilenme (Cron Job 00:15):**

```
Cron Job → aktif abonelikler WHERE nextRenewal <= TODAY
  │
  └─ Her abonelik için:
        ├─ Transaction oluştur (source: SUBSCRIPTION)
        ├─ Account.balance -= amount
        ├─ nextRenewal ilerlet (+1 ay / +1 hafta / +1 yıl)
        ├─ TransactionCreatedEvent emit → BudgetService
        └─ Notification: "Netflix yenilendi: -₺149,99"
```

**Abonelik İptal Edildiğinde:**

```
Kullanıcı "İptal Et" butonuna basar:
  ├─ isActive = false → gelecek yenilenme durur
  ├─ Geçmiş transaction'lar SİLİNMEZ (tarihçe korunur)
  └─ Dashboard'da "İptal edilmiş" olarak gösterilir
```

#### 8.4.5 Bütçe ↔ İşlemler Entegrasyonu (Event-Driven)

**Temel Prensip:** Bütçe, Transaction'lara "tepki veren" pasif bir modüldür.
Kendi başına para hareketi oluşturmaz, ama her para hareketini izler.

**Event-Driven Mimari:**

```typescript
// =============================================
// 1. EVENT TANIMLARI
// =============================================

// @nestjs/event-emitter kullanılır

class TransactionCreatedEvent {
  transactionId: string;
  userId: string;
  type: TransactionType;      // INCOME | EXPENSE
  source: TransactionSource;  // MANUAL | SUBSCRIPTION | DEBT_PAYMENT | ...
  amount: number;
  categoryId: string;
  accountId: string;
}

class TransactionDeletedEvent {
  // aynı alanlar — geri alma için
}

class TransactionUpdatedEvent {
  oldCategoryId: string;
  newCategoryId: string;
  oldAmount: number;
  newAmount: number;
}
```

```typescript
// =============================================
// 2. TRANSACTİON SERVİS — Event Emit
// =============================================

@Injectable()
class TransactionsService {
  constructor(
    private prisma: PrismaService,
    private eventEmitter: EventEmitter2,
  ) {}

  async create(dto: CreateTransactionDto) {
    const transaction = await this.prisma.$transaction(async (tx) => {
      // 1. Transaction oluştur
      // 2. Bakiye güncelle
      // 3. Tag'leri ekle
      return created;
    });

    // Transaction başarılı olduktan SONRA event emit et
    this.eventEmitter.emit('transaction.created', new TransactionCreatedEvent({
      transactionId: transaction.id,
      userId: transaction.userId,
      type: transaction.type,
      source: transaction.source,
      amount: transaction.amount,
      categoryId: transaction.categoryId,
      accountId: transaction.accountId,
    }));

    return transaction;
  }
}
```

```typescript
// =============================================
// 3. BUDGET SERVİS — Event Listener
// =============================================

@Injectable()
class BudgetService {
  @OnEvent('transaction.created')
  async handleTransactionCreated(event: TransactionCreatedEvent) {
    // Sadece EXPENSE işlemleri bütçeyi etkiler
    if (event.type !== 'EXPENSE') return;

    // Bu kategoriye ait aktif bütçe var mı?
    const budget = await this.prisma.budget.findFirst({
      where: {
        userId: event.userId,
        categoryId: event.categoryId,
        isActive: true,
        startDate: { lte: new Date() },
        OR: [
          { endDate: null },
          { endDate: { gte: new Date() } },
        ],
      },
    });

    if (!budget) return;

    // Bütçe harcamasını yeniden hesapla
    // (ilgili kategorideki tüm EXPENSE'leri topla)
    const totalSpent = await this.recalculateSpent(budget);

    // Bildirim kontrolü
    const percentage = (totalSpent / budget.amount) * 100;

    if (percentage >= 100) {
      // 🔴 Bütçe AŞILDI
      this.notificationService.sendBudgetWarning(
        event.userId,
        budget.name,
        percentage,
        'EXCEEDED'
      );
    } else if (percentage >= 80 && budget.smartTracking) {
      // 🟡 %80 eşiğine ulaşıldı
      this.notificationService.sendBudgetWarning(
        event.userId,
        budget.name,
        percentage,
        'WARNING'
      );
    }
  }

  @OnEvent('transaction.deleted')
  async handleTransactionDeleted(event: TransactionDeletedEvent) {
    // Bütçe harcamasını yeniden hesapla (azaltma)
  }

  @OnEvent('transaction.updated')
  async handleTransactionUpdated(event: TransactionUpdatedEvent) {
    // Kategori veya tutar değiştiyse her iki bütçeyi yeniden hesapla
  }

  private async recalculateSpent(budget: Budget): Promise<number> {
    // Bu bütçenin kategorisindeki EXPENSE transaction'ları topla
    // Dönem filtresi uygula (weekly/monthly/yearly)
    const result = await this.prisma.transaction.aggregate({
      where: {
        userId: budget.userId,
        categoryId: budget.categoryId,
        type: 'EXPENSE',
        transactionDate: {
          gte: budget.startDate,
          lte: budget.endDate ?? new Date(),
        },
      },
      _sum: { amount: true },
    });

    const spent = result._sum.amount ?? 0;

    // spent alanını güncelle (cache amaçlı)
    await this.prisma.budget.update({
      where: { id: budget.id },
      data: { spent },
    });

    return spent;
  }
}
```

**Bütçeyi etkileyen senaryolar ve kaynakları:**

| Senaryo | Transaction type | source | Bütçe etkisi |
|---------|-----------------|--------|--------------|
| Kullanıcı markete gitti | EXPENSE | MANUAL | ✅ Market bütçesi → spent artar |
| Netflix yenilendi | EXPENSE | SUBSCRIPTION | ✅ Eğlence bütçesi → spent artar |
| Ziraat kredi taksiti ödendi | EXPENSE | DEBT_PAYMENT | ✅ Borç Ödemeleri bütçesi → spent artar |
| Kira otomatik oluştu | EXPENSE | RECURRING | ✅ Konut bütçesi → spent artar |
| Maaş geldi | INCOME | MANUAL | ❌ Bütçeyi etkilemez |
| Alacak tahsil edildi | INCOME | DEBT_COLLECTION | ❌ Bütçeyi etkilemez |

**Bildirim Eşikleri:**

```
Bütçe: ₺3.000 (Market)
  │
  ├─ %0-79:  Normal — yeşil progress bar
  ├─ %80:    🟡 Uyarı bildirimi (smartTracking aktifse)
  │          "Market bütçenizin %80'ine ulaştınız (₺2.400/₺3.000)"
  ├─ %90:    🟠 Kritik uyarı
  │          "Market bütçeniz dolmak üzere! (₺2.700/₺3.000)"
  └─ %100+:  🔴 Aşım bildirimi
             "Market bütçenizi ₺150 aştınız! (₺3.150/₺3.000)"
```

#### 8.4.6 Tam Veri Akış Diyagramı

```
  ┌─────────────┐   ┌─────────────┐   ┌──────────────┐   ┌────────────┐
  │   Kullanıcı  │   │  Cron Jobs  │   │   Borç       │   │ Abonelik   │
  │   (Manuel)   │   │  (Recurring)│   │   Modülü     │   │ Modülü     │
  └──────┬───────┘   └──────┬──────┘   └──────┬───────┘   └──────┬─────┘
         │                  │                  │                  │
         │ source:MANUAL    │ source:RECURRING │ source:DEBT_*   │ source:SUBSCRIPTION
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                    TransactionsService.create()                     ║
  ║                                                                    ║
  ║  1. Transaction kaydı oluştur (type + source + relatedId)          ║
  ║  2. Account.balance güncelle (Prisma $transaction — atomik)        ║
  ║  3. Tag'leri bağla                                                 ║
  ║  4. Event emit: "transaction.created"                              ║
  ╚════════════════════════════╤═══════════════════════════════════════╝
                               │
                    ┌──────────┴──────────┐
                    │  EventEmitter2      │
                    │  "transaction.created"│
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │ BudgetService │  │ ReportCache  │  │ Notification │
    │ (Listener)    │  │ (Listener)   │  │ Service      │
    │               │  │              │  │              │
    │ • spent hesapla│  │ • cache      │  │ • bütçe uyarı│
    │ • %80 kontrol │  │   invalidate │  │ • özet push  │
    │ • bildirim    │  │              │  │              │
    └──────────────┘  └──────────────┘  └──────────────┘
```

#### 8.4.7 Cron Job Takvimi

| Saat | Job | Modül | Açıklama |
|------|-----|-------|----------|
| 00:05 | `RecurringTransactionJob` | İşlemler | Tekrarlayan işlemleri otomatik oluştur |
| 00:10 | `DebtOverdueJob` | Borçlar | Vadesi geçmiş borç/taksitleri OVERDUE yap |
| 00:15 | `SubscriptionRenewalJob` | Abonelikler | Yenilenme tarihindeki aboneliklerin işlemlerini oluştur |
| 08:00 | `CreditCardStatementJob` | Hesaplar | Ekstre kesim günü → bildirim + limit uyarısı |
| 09:00 | `UpcomingRenewalNotifyJob` | Abonelikler | Yarın yenilenecek abonelikler için bildirim |
| 09:05 | `DebtDueNotifyJob` | Borçlar | Yarın vadesi dolacak borçlar için bildirim |
| 09:10 | `BudgetDailyCheckJob` | Bütçeler | Günlük bütçe durumu özetini push notification olarak gönder |

#### 8.4.8 Paylaşılan Servisler

```typescript
// Tüm modüller bu merkezi servisleri kullanır:

BalanceService {
  // Tek sorumluluk: hesap bakiyesi güncelleme (Prisma $transaction içinde)
  increment(accountId, amount)   // gelir, alacak tahsilatı
  decrement(accountId, amount)   // gider, abonelik, borç ödemesi
  transfer(fromId, toId, amount) // hesaplar arası
}

NotificationService {
  // Tüm bildirimler buradan geçer (FCM)
  sendBudgetWarning(userId, budgetName, percentage, level)  // WARNING | EXCEEDED
  sendDebtReminder(userId, debtId, dueDate)
  sendSubscriptionRenewal(userId, subscriptionName, amount)
  sendRecurringCreated(userId, title, amount)
  sendDailySummary(userId, todayExpense, budgetStatus[])
}
```

#### 8.4.9 NestJS Modül Bağımlılıkları

```
PrismaModule (GLOBAL)
  └── PrismaService — tüm modüller kullanır

EventEmitterModule (GLOBAL)
  └── @nestjs/event-emitter — event bus

TransactionsModule
  ├── imports: PrismaModule, AccountsModule (BalanceService)
  ├── exports: TransactionsService
  └── Görev: Transaction oluştur + event emit et

BudgetsModule
  ├── imports: PrismaModule, NotificationsModule
  ├── listens: "transaction.created", "transaction.deleted", "transaction.updated"
  └── Görev: Spent hesapla + bildirim gönder

DebtsModule
  ├── imports: PrismaModule, TransactionsModule (ödeme → transaction oluştur)
  └── exports: DebtsService

SubscriptionsModule
  ├── imports: PrismaModule, TransactionsModule (yenilenme → transaction oluştur)
  └── exports: SubscriptionsService

ScheduleModule (@nestjs/schedule)
  └── imports: TransactionsModule, DebtsModule, SubscriptionsModule, NotificationsModule, BudgetsModule

NotificationsModule
  ├── imports: FCM config
  └── exports: NotificationService
```

#### 8.4.10 Yeni Sistem Kategorileri (Seed Data)

Borç ve abonelik modülleri otomatik transaction oluştururken belirli sistem kategorilerine ihtiyaç duyar:

```typescript
// prisma/seed.ts — sistem kategorileri

const systemCategories = [
  // Mevcut
  { name: 'Market',      icon: 'shopping_cart', color: '#70D8C8', type: 'EXPENSE' },
  { name: 'Ulaşım',     icon: 'directions_bus', color: '#BAC3FF', type: 'EXPENSE' },
  { name: 'Eğlence',    icon: 'movie',          color: '#FFB68F', type: 'EXPENSE' },
  { name: 'Sağlık',     icon: 'local_hospital', color: '#FF8A80', type: 'EXPENSE' },
  { name: 'Alışveriş',  icon: 'shopping_bag',   color: '#CE93D8', type: 'EXPENSE' },
  { name: 'Faturalar',  icon: 'receipt',         color: '#80CBC4', type: 'EXPENSE' },
  { name: 'Maaş',       icon: 'account_balance', color: '#70D8C8', type: 'INCOME' },
  { name: 'Yatırım',    icon: 'trending_up',    color: '#FFD54F', type: 'INCOME' },

  // YENİ — Borç/Abonelik modülü için
  { name: 'Borç Ödemesi',     icon: 'payments',     color: '#FFB4AB', type: 'EXPENSE', isSystem: true },
  { name: 'Alacak Tahsilatı', icon: 'call_received', color: '#A5D6A7', type: 'INCOME',  isSystem: true },
  { name: 'Abonelik',         icon: 'subscriptions', color: '#BAC3FF', type: 'EXPENSE', isSystem: true },
];
```

---

### 8.5 FİŞ TARAMA MODÜLÜ (Receipt Scanner) — Detaylı Kurgu

#### 8.5.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| OCR Teknolojisi | Hibrit (cihaz + bulut) | Önce ML Kit (cihazda), güvenilirlik düşükse Cloud Vision API (bulut) |
| Ürün Detayı | Satır satır parse | Fişteki her ürün ayrı çıkarılır (Süt ₺45, Ekmek ₺12...) |
| Fiş Görseli | Saklanır | İşleme bağlı olarak fiş fotoğrafı S3/local'de tutulur |
| Mükerrer Kontrol | Var | Tutar + tarih + işyeri kombinasyonuyla çift tarama engellenir |
| Kategori Eşleştirme | Akıllı mapping | İşyeri adına göre otomatik kategori önerisi + kullanıcıdan öğrenme |

#### 8.5.2 Hibrit OCR Mimarisi

```
Kullanıcı fişi tarar (kamera veya galeri)
  │
  ├─ AŞAMA 1 — Cihaz Üzerinde (Google ML Kit)
  │     ├─ google_mlkit_text_recognition ile metin çıkar
  │     ├─ Güvenilirlik skoru hesapla:
  │     │     - Toplam tutar bulundu mu?
  │     │     - Tarih bulundu mu?
  │     │     - En az 3 satır okunabildi mi?
  │     │
  │     ├─ Skor >= %70 → Cihaz sonucunu kullan ✓ (hızlı, ücretsiz)
  │     └─ Skor < %70 → AŞAMA 2'ye geç
  │
  └─ AŞAMA 2 — Bulut (Google Cloud Vision API)
        ├─ Görsel backend'e yüklenir (POST /api/receipts/scan)
        ├─ Backend → Cloud Vision API'ye gönderir
        ├─ Daha yüksek doğrulukta metin döner
        └─ Backend parse eder → sonucu Flutter'a döner

Sonuç: ReceiptParseResult {
  merchantName: "Migros",
  totalAmount: 450.20,
  date: "2026-04-28",
  items: [...],
  confidence: 0.92,
  source: "ON_DEVICE" | "CLOUD"
}
```

#### 8.5.3 Türkçe Fiş Parse Motoru

**Fiş Yapısı Analizi (Tipik Türk fişi):**

```
        MİGROS TİCARET A.Ş.              ← İşyeri adı (üst kısım)
       İSTANBUL / KADIKÖY
      VKN: 1234567890
─────────────────────────────
SÜZME PEYNİR         *1    45,90         ← Ürün satırları
SÜTAŞ SÜZME YOĞ      *1    38,50
BANVIT TAVUK G        *2    89,00
SELPAK MENDIL         *1    32,90
COCA COLA 1LT         *3    59,70
─────────────────────────────
TOPLAM                      266,00       ← Toplam tutar
NAKİT                       300,00       ← Ödeme tipi
PARA ÜSTÜ                    34,00
KDV %1                        1,20       ← KDV bilgisi
KDV %10                      12,40
─────────────────────────────
28/04/2026  14:35  FİŞ NO:4521           ← Tarih + saat
```

**Parse Kuralları:**

```typescript
// receipt-parser.service.ts

interface ParseRule {
  field: string;
  patterns: RegExp[];
  postProcess?: (value: string) => any;
}

const TURKISH_RECEIPT_RULES: ParseRule[] = [
  // 1. TOPLAM TUTAR
  {
    field: 'totalAmount',
    patterns: [
      /(?:GENEL\s*)?TOPLAM\s*[:\s]*\*?(\d+[.,]\d{2})/i,
      /TOP\.?\s*[:\s]*\*?(\d+[.,]\d{2})/i,
      /TUTAR\s*[:\s]*\*?(\d+[.,]\d{2})/i,
    ],
    postProcess: (val) => parseFloat(val.replace(',', '.'))
  },

  // 2. TARİH
  {
    field: 'date',
    patterns: [
      /(\d{2}[\/\.\-]\d{2}[\/\.\-]\d{4})/,           // DD/MM/YYYY veya DD.MM.YYYY
      /(\d{4}[\/\.\-]\d{2}[\/\.\-]\d{2})/,           // YYYY-MM-DD
      /(\d{2}[\/\.\-]\d{2}[\/\.\-]\d{2})\s+\d{2}:/,  // DD/MM/YY HH:
    ],
    postProcess: (val) => parseDate(val)
  },

  // 3. İŞYERİ ADI (ilk anlamlı satır)
  {
    field: 'merchantName',
    patterns: [
      /^([A-ZİŞÇĞÜÖ\s]{3,}(?:A\.Ş\.|LTD|TİC|MARKET|ECZANE|RESTAURANT))/im,
    ],
    postProcess: (val) => val.trim().toLocaleUpperCase('tr')
  },

  // 4. KDV
  {
    field: 'taxAmount',
    patterns: [
      /KDV\s*%?\d*\s*[:\s]*(\d+[.,]\d{2})/i,
      /TOPKDV\s*[:\s]*(\d+[.,]\d{2})/i,
    ]
  },

  // 5. ÖDEME TİPİ
  {
    field: 'paymentMethod',
    patterns: [
      /(NAKİT|KREDI\s*KARTI?|K\.KARTI?|BANKA\s*KARTI?|TEMASSIZ)/i,
    ]
  },

  // 6. ÜRÜN SATIRLARI
  {
    field: 'lineItems',
    patterns: [
      // "ÜRÜN ADI    *adet   tutar" formatı
      /^(.{3,30})\s+\*?(\d+)\s+(\d+[.,]\d{2})$/gm,
      // "ÜRÜN ADI          tutar" formatı (adetsiz)
      /^(.{3,30})\s{2,}(\d+[.,]\d{2})$/gm,
    ]
  }
];
```

**Parse edilen ürün satırı modeli:**

```prisma
model ReceiptItem {
  id          String  @id @default(uuid()) @db.VarChar(36)
  receiptId   String  @map("receipt_id") @db.VarChar(36)
  name        String  @db.VarChar(200)            /// "SÜTAŞ SÜZME YOĞ"
  quantity    Int     @default(1)
  unitPrice   Decimal @map("unit_price") @db.Decimal(15, 2)
  totalPrice  Decimal @map("total_price") @db.Decimal(15, 2)
  sortOrder   Int     @default(0) @map("sort_order")

  // İlişkiler
  receipt Receipt @relation(fields: [receiptId], references: [id], onDelete: Cascade)

  @@map("receipt_items")
}
```

**Güncellenmiş Receipt modeli:**

```prisma
model Receipt {
  id              String        @id @default(uuid()) @db.VarChar(36)
  userId          String        @map("user_id") @db.VarChar(36)
  transactionId   String?       @map("transaction_id") @db.VarChar(36)
  imageUrl        String        @map("image_url") @db.VarChar(500)
  ocrRawText      String?       @map("ocr_raw_text") @db.Text
  ocrSource       String?       @map("ocr_source") @db.VarChar(20)    /// "ON_DEVICE" | "CLOUD"
  confidence      Decimal?      @db.Decimal(3, 2)                      /// 0.00 - 1.00
  parsedAmount    Decimal?      @map("parsed_amount") @db.Decimal(15, 2)
  parsedMerchant  String?       @map("parsed_merchant") @db.VarChar(200)
  parsedDate      DateTime?     @map("parsed_date") @db.Date
  parsedTax       Decimal?      @map("parsed_tax") @db.Decimal(15, 2)  /// KDV tutarı
  paymentMethod   String?       @map("payment_method") @db.VarChar(20) /// NAKİT / KREDİ KARTI
  status          ReceiptStatus @default(PROCESSING)
  createdAt       DateTime      @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user        User          @relation(fields: [userId], references: [id], onDelete: Cascade)
  transaction Transaction?  @relation(fields: [transactionId], references: [id])
  items       ReceiptItem[]

  @@map("receipts")
}
```

#### 8.5.4 Akıllı Kategori Eşleştirme (Merchant Mapping)

```prisma
model MerchantCategoryMap {
  id           String   @id @default(uuid()) @db.VarChar(36)
  userId       String?  @map("user_id") @db.VarChar(36)         /// NULL = global (sistem) mapping
  merchantKey  String   @map("merchant_key") @db.VarChar(100)  /// normalize edilmiş ad: "migros"
  categoryId   String   @map("category_id") @db.VarChar(36)
  hitCount     Int      @default(1) @map("hit_count")     /// kaç kez eşleştirildi
  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt    DateTime @updatedAt @map("updated_at") @db.Timestamp(0)

  user     User?    @relation(fields: [userId], references: [id], onDelete: Cascade)
  category Category @relation(fields: [categoryId], references: [id])

  @@unique([userId, merchantKey])
  @@map("merchant_category_maps")
}
```

**Eşleştirme akışı:**

```
Fiş parse edildi → merchantName: "MİGROS TİC. A.Ş."
  │
  ├─ 1. Normalize et: "migros" (küçük harf, özel karakterler temizle)
  │
  ├─ 2. Kullanıcıya özel mapping ara:
  │     SELECT * FROM merchant_category_maps
  │     WHERE merchantKey = "migros" AND userId = currentUser
  │
  ├─ 3. Bulunamadıysa → global mapping ara:
  │     WHERE merchantKey = "migros" AND userId IS NULL
  │
  ├─ 4. Bulunamadıysa → fuzzy match dene:
  │     "migros" LIKE "%migros%" OR benzer kelimeler
  │
  └─ 5. Hiç bulunamadıysa → kategori önerme, kullanıcı seçsin
        Kullanıcı seçtikten sonra → mapping kaydet (öğrenme)

Sistem seed data (global mapping):
  "migros"     → Market
  "a101"       → Market
  "bim"        → Market
  "şok"        → Market
  "carrefour"  → Market
  "bp"         → Ulaşım
  "shell"      → Ulaşım
  "opet"       → Ulaşım
  "eczane"     → Sağlık
  "hastane"    → Sağlık
  "netflix"    → Eğlence
  "starbucks"  → Yeme-İçme
```

#### 8.5.5 Mükerrer Fiş Kontrolü

```
Yeni fiş parse edildikten sonra:
  │
  ├─ Aynı kullanıcının son 7 gün içindeki fişlerini kontrol et:
  │     WHERE userId = currentUser
  │       AND parsedAmount = newAmount
  │       AND parsedDate = newDate
  │       AND parsedMerchant ILIKE newMerchant
  │       AND createdAt > NOW() - 7 days
  │
  ├─ Eşleşme varsa → kullanıcıya uyarı göster:
  │     "Bu fişe benzer bir kayıt zaten var:
  │      Migros — ₺266,00 — 28 Nis 2026
  │      Yine de kaydetmek istiyor musunuz?"
  │
  └─ Kullanıcı onaylarsa → kaydet
     Kullanıcı vazgeçerse → iptal
```

#### 8.5.6 Tam Kullanıcı Akışı

```
1. TARAMA
   ├─ Dashboard → "Tara" butonuna bas (veya İşlemler → FAB → Fiş Tara)
   ├─ Kamera açılır (ReceiptScannerPage)
   │     ├─ Çerçeve kılavuzu: "Fişi çerçevenin içine yerleştirin"
   │     ├─ Otomatik kenar algılama (opsiyonel — v2)
   │     └─ Alternatif: "Galeri" butonu → galeriden fiş seçme
   └─ Fotoğraf çekimi → görsel yakalandı

2. İŞLENİYOR (Loading ekranı)
   ├─ Shimmer animasyonu: "Fiş okunuyor..."
   ├─ ML Kit ile cihazda OCR çalıştır
   │     ├─ Güvenilirlik >= %70 → sonucu kullan
   │     └─ Güvenilirlik < %70 → backend'e gönder (Cloud Vision)
   └─ Parse motoru çalışır → sonuç hazır

3. ÖNİZLEME (ReceiptPreviewPage)
   ├─ Üst: fiş görseli (küçük thumbnail, tıklanınca büyüt)
   ├─ Parse edilen bilgiler (düzenlenebilir):
   │     ├─ İşyeri: [MİGROS] (text input — düzenlenebilir)
   │     ├─ Toplam: [₺266,00] (düzenlenebilir)
   │     ├─ Tarih: [28/04/2026] (date picker)
   │     ├─ KDV: [₺13,60] (salt okunur)
   │     └─ Ödeme: [NAKİT] (chip seçici)
   │
   ├─ Ürün Listesi (kaydırılabilir):
   │     ├─ ☑ Süzme Peynir    x1    ₺45,90
   │     ├─ ☑ Sütaş Yoğurt    x1    ₺38,50
   │     ├─ ☑ Banvit Tavuk    x2    ₺89,00
   │     ├─ ☑ Selpak Mendil   x1    ₺32,90
   │     └─ ☑ Coca Cola 1Lt   x3    ₺59,70
   │     (her satır düzenlenebilir veya checkbox ile çıkarılabilir)
   │
   ├─ Güvenilirlik göstergesi:
   │     %92 — "Yüksek doğruluk" (yeşil)
   │     %60 — "Bazı bilgiler eksik olabilir" (turuncu)
   │     %30 — "Doğruluk düşük, lütfen kontrol edin" (kırmızı)
   │
   ├─ ⚠ Mükerrer uyarısı (varsa):
   │     "Bu fişe benzer bir kayıt zaten mevcut"
   │
   └─ "İşlem Oluştur" butonu → sonraki adım

4. İŞLEM OLUŞTURMA (AddTransactionPage — ön doldurulmuş)
   ├─ Tip: GİDER (otomatik)
   ├─ Miktar: ₺266,00 (fişten)
   ├─ Kategori: Market (akıllı eşleştirme — "Migros" → Market)
   ├─ Hesap seçici:
   │     ├─ Fişteki ödeme tipi "NAKİT" ise → Nakit hesabı ön seçili
   │     ├─ "KREDİ KARTI" ise → kredi kartı ön seçili
   │     └─ Belirlenemezse → varsayılan hesap
   ├─ Başlık: "Migros — Market Alışverişi" (otomatik oluşturulmuş)
   ├─ Not: (boş, kullanıcı ekleyebilir)
   ├─ Fiş görseli bağlantısı: 📎 (thumbnail)
   └─ "Kaydet" → Transaction oluşturulur (source: MANUAL)
        + Receipt kaydı ile ilişkilendirilir
        + Fiş görseli depolanır

5. BAŞARISIZ TARAMA
   ├─ OCR hiç metin bulamadıysa veya güvenilirlik < %20:
   │     "Fiş okunamadı. Lütfen tekrar deneyin veya
   │      işlemi manuel olarak girin."
   │     [Tekrar Dene] [Manuel Gir]
   │
   └─ "Manuel Gir" → boş AddTransactionPage açılır
        + fiş görseli yine de bağlanır (referans amaçlı)
```

#### 8.5.7 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/receipts/scan` | Fiş görseli yükle + Cloud OCR başlat (multipart) |
| `GET` | `/api/receipts/:id` | OCR sonuç detayı (items dahil) |
| `GET` | `/api/receipts` | Kullanıcının tüm fiş geçmişi |
| `PATCH` | `/api/receipts/:id` | Parse sonucunu düzelt (merchant, amount, date) |
| `DELETE` | `/api/receipts/:id` | Fiş kaydını sil |
| `POST` | `/api/receipts/:id/create-transaction` | Parse sonucundan transaction oluştur |
| `GET` | `/api/receipts/check-duplicate` | Mükerrer kontrol (query: amount, date, merchant) |
| `GET` | `/api/merchant-mappings` | Merchant → kategori eşleştirme listesi |
| `POST` | `/api/merchant-mappings` | Yeni eşleştirme ekle (kullanıcı düzeltmesinden öğren) |

#### 8.5.8 Flutter — Ekran ve Widget Yapısı

```
presentation/receipt_scanner/
├── bloc/
│     ├── receipt_scanner_bloc.dart     # Kamera + OCR yönetimi
│     ├── receipt_scanner_event.dart
│     ├── receipt_scanner_state.dart
│     ├── receipt_preview_bloc.dart     # Önizleme + düzenleme
│     └── receipt_preview_event/state.dart
├── pages/
│     ├── receipt_scanner_page.dart     # Kamera viewfinder
│     └── receipt_preview_page.dart     # Parse sonucu önizleme
└── widgets/
      ├── scanner_overlay.dart          # Çerçeve kılavuzu + animasyon
      ├── confidence_indicator.dart     # %92 yeşil / %60 turuncu
      ├── receipt_item_tile.dart        # Ürün satırı (düzenlenebilir)
      ├── receipt_thumbnail.dart        # Fiş görseli küçük resim
      ├── duplicate_warning.dart        # Mükerrer uyarı banner
      └── ocr_loading_animation.dart    # "Fiş okunuyor..." shimmer
```

#### 8.5.9 Gerekli Flutter Paketleri

| Paket | Kullanım |
|-------|----------|
| `camera` | Kamera erişimi + viewfinder |
| `google_mlkit_text_recognition` | Cihaz üzerinde OCR (Aşama 1) |
| `image_picker` | Galeri'den fiş seçme |
| `image_cropper` | Fiş fotoğrafını kırpma/döndürme |
| `path_provider` | Geçici dosya yolu (kamera çıktısı) |

#### 8.5.10 Backend İşlem Akışı (NestJS)

```typescript
// receipts/receipts.service.ts

@Injectable()
class ReceiptsService {

  async processReceipt(userId: string, imageFile: Express.Multer.File) {
    // 1. Görseli S3/local storage'a yükle
    const imageUrl = await this.storageService.upload(imageFile);

    // 2. Receipt kaydı oluştur (status: PROCESSING)
    const receipt = await this.prisma.receipt.create({
      data: { userId, imageUrl, status: 'PROCESSING' }
    });

    // 3. Cloud Vision API ile OCR
    const ocrResult = await this.cloudVisionService.detectText(imageUrl);

    // 4. Türkçe fiş parse et
    const parsed = this.receiptParser.parse(ocrResult.text);

    // 5. Ürün satırlarını kaydet
    if (parsed.items.length > 0) {
      await this.prisma.receiptItem.createMany({
        data: parsed.items.map((item, i) => ({
          receiptId: receipt.id,
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.totalPrice,
          sortOrder: i,
        }))
      });
    }

    // 6. Merchant mapping ile kategori öner
    const suggestedCategory = await this.merchantMappingService
      .findCategory(userId, parsed.merchantName);

    // 7. Mükerrer kontrol
    const isDuplicate = await this.checkDuplicate(
      userId, parsed.totalAmount, parsed.date, parsed.merchantName
    );

    // 8. Receipt güncelle (status: COMPLETED)
    return this.prisma.receipt.update({
      where: { id: receipt.id },
      data: {
        ocrRawText: ocrResult.text,
        ocrSource: 'CLOUD',
        confidence: parsed.confidence,
        parsedAmount: parsed.totalAmount,
        parsedMerchant: parsed.merchantName,
        parsedDate: parsed.date,
        parsedTax: parsed.taxAmount,
        paymentMethod: parsed.paymentMethod,
        status: 'COMPLETED',
      },
      include: { items: true }
    });

    // Response'a ek bilgi ekle:
    // suggestedCategoryId, suggestedAccountId, isDuplicate
  }
}
```

---
