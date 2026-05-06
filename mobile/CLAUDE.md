# mobile/CLAUDE.md — Frontend (Flutter)

> Bu dosya `cd mobile` ile açılan session'lar için ek kurallar içerir. Çapraz mimari için proje köküne, root `CLAUDE.md`'ye bak.

---

## Komutlar

```bash
flutter pub get                       # bağımlılıkları yükle
flutter run                           # Android emülatörde çalıştır
flutter run -d chrome                 # web (geliştirme)
flutter analyze                       # statik analiz
flutter test                          # tüm testler
flutter test test/widget_test.dart    # tek test dosyası
dart fix --apply                      # otomatik lint düzeltme
```

Android emülatörde backend'e erişim için `ApiEndpoints.baseUrl = 'http://10.0.2.2:3000'` kullanılır (localhost alias).

---

## State Management — BLoC Pattern

`flutter_bloc` paketi. Her özellik:

```
presentation/<feature>/
  bloc/  <feature>_bloc.dart + <feature>_event.dart + <feature>_state.dart
  pages/ <Feature>Page
  widgets/ (özelliğe özel widget'lar)
data/
  models/ (JSON serialization)
  repositories/ (HTTP çağrıları — Dio üzerinden)
```

**Optimistic update pattern:** `BudgetsBloc._onUpdate` gibi yerlerde state önce optimistic emit, API'den dönüş sonrası refresh/revert. Test yazarken bu **çift emit'i** unutma — `bloc_test`'te `expect: [optimisticState, refreshedState]` olmalı.

**Side-effect kuralı (auth):** `AuthBloc` login/register/googleSignIn akışında `NotificationService.initialize()` **fire-and-forget** olmalı (kendi try/catch'inde). Auth state'ini etkileyemez — aksi halde test ortamında getIt configure olmadığı için `AuthFailure` emit'ine yol açar (PR #1'de yakalanan bug).

---

## Dependency Injection

`GetIt` ile **manuel kayıt** (`injectable_generator` paketi var ama kullanılmıyor). Tüm singleton'lar `core/di/injection.dart`'ta `configureDependencies()` içinde tanımlı. Yeni service eklendiğinde buraya kaydedilmeli.

---

## Navigation — GoRouter + ShellRoute

Yapı:
- **Auth rotaları:** `/login`, `/register`, `/forgot-password`, `/reset-password` — her biri kendi `BlocProvider`'ı ile `AuthBloc` create eder
- **ShellRoute** → `AppShell` (BottomNavBar) → 5 tab: `/home`, `/transactions`, `/budgets`, `/debts`, `/subscriptions`
- **Root navigator modal'lar:** `/transactions/add`, `/budgets/add`, `/reports`, `/receipt-scanner`, `/settings`, `/settings/profile`
- **Redirect:** token yoksa → `/login`, token varsa auth sayfalarından → `/home`

Tüm rota sabitleri `navigation/route_names.dart`'ta. Yeni rota eklendiğinde **hem** `route_names.dart` **hem** `app_router.dart` güncellenir.

---

## HTTP / API

`ApiClient` (Dio) → `AuthInterceptor`:
- Her istekte `Authorization: Bearer <access_token>` header
- 401 → refresh token → orijinal isteği tekrarla
- Refresh başarısızsa token temizle → kullanıcı `/login`'e yönlendirilir

Backend response envelope'undan veri çıkarma:
```dart
final data = response.data['data']; // {success, statusCode, data} dış sarmalı
```

Tüm endpoint sabitleri `core/constants/api_endpoints.dart`'ta.

---

## Token Yönetimi

`SecureStorage` → `FlutterSecureStorage`:
- Android: `encryptedSharedPreferences: true`
- iOS: `KeychainAccessibility.first_unlock`
- Anahtarlar: `access_token`, `refresh_token`

---

## Design System (BOZMA)

### Renk Paleti (`AppColors`)

| Token | Hex | Kullanım |
|-------|-----|---------|
| `surface` | `#131313` | Scaffold arka planı — **#000000 yasak** |
| `primary` | `#BAC3FF` | Lavender-mavi, aktif elementler |
| `secondary` | `#70D8C8` | Mint yeşil = **gelir / başarı** |
| `tertiary` | `#FFB68F` | Şeftali-turuncu = **gider / uyarı** |
| `onSurface` | `#E5E2E1` | Ana metin — **#FFFFFF yasak** |
| `surfaceContainerHighest` | `#353534` | Input field arka planı |
| `surfaceContainerHigh` | `#2A2A2A` | Card arka planı |

Tonal surface geçişleri ile ayır — **1px border kullanma**.

### Spacing (`AppSpacing`)

`xs=4 / sm=8 / md=12 / lg=16 / xl=24 / xxl=32 / xxxl=48`  
Radius: `radiusSm=8 / radiusMd=12 (input) / radiusLg=16 (card) / radiusXl=24 (button)`  
Page padding: `20px`

### Typography (`AppTypography`)

| Stil | Spec | Kullanım |
|---|---|---|
| `displayLg` | 56px / 700 | Bakiye gösterimleri |
| `headlineMd` | 28px / 600 | Sayfa başlıkları |
| `titleSm` | 16px / 600 | Kart başlıkları |
| `bodyMd` | 14px / 400 | Genel metin |
| `labelSm` | 11px / 500, letterSpacing 1.0 | Uppercase overline |

Font: Inter (`google_fonts` paketi).

### UI Kuralları

- **Primary buton:** `radiusXl` (24px) pill shape, min height 56px, full-width
- **Input:** border yok, `surfaceContainerHighest` arka plan, `radiusMd` (12px)
- **Card:** `surfaceContainerHigh` arka plan, `radiusLg` (16px), elevation 0
- **Bakiye gösterimi:** `AppTypography.displayLg` + `CurrencyFormatter.format()`

### Utilities

- `CurrencyFormatter` — `₺1.234,56` formatı (TR locale)
- `DateFormatter` — Türkçe tarih formatları
- `Validators` — form validasyonu (email, password, required, confirmPassword)
- `IconMapper.fromString(iconKey)` — backend'den gelen ikon string'ini `IconData`'ya çevirir

---

## Test Yazma Kuralları

- BLoC test: `test/blocs/<feature>_bloc_test.dart` — `bloc_test` paketi ile
- Widget test: özellik bazlı dosyalarda + `test/widget_test.dart` placeholder
- **Optimistic emit pattern:** test ederken iki state emit beklendiğini unutma
- Yeni package eklendiğinde `flutter pub get` çalıştır + `pubspec.lock` commit et
- Push öncesi `flutter analyze && flutter test` lokal'de yeşil olmalı

---

## Lokal Backend Bağlantısı

- Android emülatör: `http://10.0.2.2:3000` (host loopback)
- iOS simulator: `http://localhost:3000`
- Fiziksel cihaz: bilgisayarın LAN IP'si (`http://192.168.x.x:3000`) + backend `0.0.0.0`'a bind olmalı
- Production: `ApiEndpoints.baseUrl` ortam değişkenine bağlı (Sprint 8'de eklendi)
