# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

"The Digital Private Vault" — kişisel finans yönetim uygulaması.
- `api/` — NestJS backend (port 3000)
- `mobile/` — Flutter frontend (Android/iOS)
- Sprint planı ve görev takibi: `TASK.md`, `DEVELOPMENT_PLAN_V1.md`, `DEVELOPMENT_PLAN_V2.md`
- UI tasarım referansı: `STITCH_PROMPTS.md`, Stitch project ID `projects/5496994793442531801`

---

## Backend (api/) Commands

```bash
cd api

npm run start:dev       # watch mode geliştirme
npm run build           # production build
npm run lint            # eslint --fix
npm run test            # unit testler
npm run test:e2e        # e2e testler
npm run test:cov        # coverage

npm run db:generate     # prisma generate (schema değişince)
npm run db:migrate      # prisma migrate dev (yeni migration)
npm run db:seed         # tsx prisma/seed.ts
npm run db:studio       # Prisma Studio (GUI)
npm run db:reset        # migrate reset (dikkat: veri siler)

docker compose up -d    # MySQL 8.0 başlat (proje kökünden)
```

Backend `http://localhost:3000/api` adresinde çalışır.

## Frontend (mobile/) Commands

```bash
cd mobile

flutter pub get         # bağımlılıkları yükle
flutter run             # Android emülatörde çalıştır
flutter run -d chrome   # web (geliştirme)
flutter analyze         # statik analiz
flutter test            # tüm testler
flutter test test/widget_test.dart  # tek test dosyası
```

Android emülatörde backend'e erişim için `ApiEndpoints.baseUrl = 'http://10.0.2.2:3000'` kullanılır (localhost alias).

---

## Backend Architecture

### Modül Yapısı

Her özellik `api/src/modules/<feature>/` altında kendi modülünde yaşar:
```
auth.module.ts / auth.controller.ts / auth.service.ts / dto/ / strategies/
```

`AppModule` şu an sadece `AuthModule`'ü import ediyor. Yeni modüller buraya eklenir.

### Global Altyapı

- **Prefix:** tüm endpoint'ler `/api/` ile başlar (`app.setGlobalPrefix('api')`)
- **Response envelope:** `TransformInterceptor` tüm başarılı yanıtları `{ success: true, statusCode, data: ... }` formatına sarar
- **Exception filter:** `GlobalExceptionFilter` tüm hataları aynı envelope formatında döner
- **Validation:** `ValidationPipe` ile DTO'lar `class-validator` ile doğrulanır; `whitelist: true` — DTO'da olmayan alanlar otomatik atılır
- **Guards:** `JwtAuthGuard` korumalı endpoint'ler için, `RefreshTokenGuard` token yenileme için
- **Decorator:** `@CurrentUser()` JWT payload'dan user bilgisini alır
- **Event bus:** `@nestjs/event-emitter` global olarak kurulu (Sprint 3+'dan kullanılacak)
- **Cron:** `@nestjs/schedule` global olarak kurulu (Sprint 5+'dan kullanılacak)

### Prisma Önemli Notlar

- `provider = "prisma-client-js"` + `@prisma/adapter-mariadb` kullanılıyor
- Client `@prisma/client`'tan import edilir, custom output yok
- `tsconfig.json`: `"module": "CommonJS"`, `"moduleResolution": "node"` — değiştirme
- `prisma.config.ts` ile datasource URL yönetiliyor (schema.prisma'da `url` alanı yok)
- Seed: `tsx prisma/seed.ts` (ts-node değil)
- `@db.Timestamp(0)` kullanma → `@db.DateTime(0)` kullan (MySQL 8.0 uyumu)
- Migration adı için: `npx prisma migrate dev --name <snake_case_isim>`

### Auth Akışı

- JWT access token: 15 dakika, refresh token: 7 gün
- Google OAuth: redirect flow → `GET /api/auth/google/callback` → Flutter deep link'e token'ları aktarır
- Token yenileme: `AuthInterceptor` 401 alınca otomatik refresh dener, başarısızsa token'ları siler

---

## Flutter Architecture

### State Management

BLoC pattern (`flutter_bloc`). Her özellik:
```
presentation/<feature>/
  bloc/  <feature>_bloc.dart + <feature>_event.dart + <feature>_state.dart
  pages/ <Feature>Page
  widgets/ (özelliğe özel widget'lar)
data/
  models/ (JSON serialization)
  repositories/ (HTTP çağrıları — Dio üzerinden)
```

### Dependency Injection

`GetIt` ile manuel kayıt (`injectable_generator` kullanılmıyor). Tüm singleton'lar `core/di/injection.dart`'ta `configureDependencies()` içinde tanımlı.

### Navigation

`GoRouter` + `ShellRoute`. Yapı:
- Auth rotaları (`/login`, `/register`, `/forgot-password`, `/reset-password`) — her biri kendi `BlocProvider`'ı ile `AuthBloc` create eder
- `ShellRoute` → `AppShell` (BottomNavBar) → 5 tab: `/home`, `/transactions`, `/budgets`, `/debts`, `/subscriptions`
- Root navigator üzerinde full-screen modal'lar: `/transactions/add`, `/budgets/add`, `/reports`, `/receipt-scanner`, `/settings`, `/settings/profile`
- Redirect: token yoksa → `/login`, token varsa auth sayfalarından → `/home`

Tüm rota sabitleri `navigation/route_names.dart`'ta. Yeni rota eklenirken hem `route_names.dart` hem `app_router.dart` güncellenir.

### HTTP / API

`ApiClient` (Dio) → `AuthInterceptor`:
- Her istekte `Authorization: Bearer <access_token>` header'ı ekler
- 401 alınca refresh token ile yeni token alır, orijinal isteği tekrarlar
- Refresh başarısızsa token'ları temizler (kullanıcı login'e yönlendirilir)

Backend response'u `{ success, statusCode, data }` envelope'undadır. Repository'lerde `response.data['data']` kullanılır.

Tüm endpoint sabitleri `core/constants/api_endpoints.dart`'ta.

### Token Yönetimi

`SecureStorage` → `FlutterSecureStorage`:
- Android: `encryptedSharedPreferences: true`
- iOS: `KeychainAccessibility.first_unlock`
- Anahtarlar: `access_token`, `refresh_token`

---

## Design System

### Renk Paleti (AppColors)

| Token | Hex | Kullanım |
|-------|-----|---------|
| `surface` | `#131313` | Scaffold arka planı — **#000000 yasak** |
| `primary` | `#BAC3FF` | Lavender-mavi, aktif elementler |
| `secondary` | `#70D8C8` | Mint yeşil = **gelir** |
| `tertiary` | `#FFB68F` | Şeftali-turuncu = **gider** |
| `onSurface` | `#E5E2E1` | Ana metin — **#FFFFFF yasak** |
| `surfaceContainerHighest` | `#353534` | Input field arka planı |
| `surfaceContainerHigh` | `#2A2A2A` | Card arka planı |

Tonal surface geçişleri ile ayır — **1px border kullanma**.

### Spacing (AppSpacing)

`xs=4 / sm=8 / md=12 / lg=16 / xl=24 / xxl=32 / xxxl=48`
Radius: `radiusSm=8 / radiusMd=12(input) / radiusLg=16(card) / radiusXl=24(button)`
Page padding: `20px`

### Typography (AppTypography)

`displayLg` (56px/700) — bakiyeler | `headlineMd` (28px/600) — sayfa başlıkları | `titleSm` (16px/600) — kart başlıkları | `bodyMd` (14px/400) | `labelSm` (11px/500, letterSpacing:1.0) — uppercase overline'lar

Font: Inter (`google_fonts` paketi ile).

### UI Kuralları

- Primary buton: `radiusXl` (24px) pill shape, minimum height 56px, full-width
- Input: border yok, `surfaceContainerHighest` arka plan, `radiusMd` (12px)
- Card: `surfaceContainerHigh` arka plan, `radiusLg` (16px), elevation 0
- Bakiye gösterimi için `AppTypography.displayLg`, `CurrencyFormatter.format()` kullan

### Utilities

- `CurrencyFormatter` — `₺1.234,56` formatı
- `DateFormatter` — Türkçe tarih formatları
- `Validators` — form validasyonu (email, password, required, confirmPassword)
- `IconMapper.fromString(iconKey)` — backend'den gelen ikon string'ini `IconData`'ya çevirir
