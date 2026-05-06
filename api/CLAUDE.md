# api/CLAUDE.md — Backend (NestJS)

> Bu dosya `cd api` ile açılan session'lar için ek kurallar içerir. Çapraz mimari için proje köküne, root `CLAUDE.md`'ye bak.

---

## Komutlar

```bash
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
npm run db:reset        # migrate reset (DİKKAT: tüm veriyi siler)

# Proje kökünden:
docker compose up -d    # MySQL 8.0 başlat
```

Backend `http://localhost:3000/api` adresinde çalışır.

---

## Modül Yapısı

Her özellik `src/modules/<feature>/` altında:

```
<feature>.module.ts / <feature>.controller.ts / <feature>.service.ts / dto/ / strategies/
```

Yeni modül `AppModule.imports`'a eklenir.

---

## Global Altyapı

- **Prefix:** tüm endpoint'ler `/api/` ile başlar (`app.setGlobalPrefix('api')`)
- **Response envelope:** `TransformInterceptor` tüm başarılı yanıtları `{ success, statusCode, data }` formatına sarar — controller'dan direkt return et, sarmalama otomatik
- **Exception filter:** `GlobalExceptionFilter` tüm hataları envelope'ler — `throw new BadRequestException(...)` yeterli
- **Validation:** `ValidationPipe` ile DTO'lar `class-validator` ile doğrulanır; `whitelist: true` — DTO'da olmayan alanlar otomatik atılır
- **Guards:** `JwtAuthGuard` korumalı endpoint'ler için, `RefreshTokenGuard` token yenileme için
- **Decorator:** `@CurrentUser()` JWT payload'dan user bilgisini alır
- **Event bus:** `@nestjs/event-emitter` global olarak kurulu (Sprint 3+ kullanıyor)
- **Cron:** `@nestjs/schedule` global olarak kurulu (Sprint 5+ kullanıyor)

---

## Prisma Önemli Notlar (BOZMA)

- `provider = "prisma-client-js"` + `@prisma/adapter-mariadb` kullanılıyor
- Client `@prisma/client`'tan import edilir, **custom output yok**
- `tsconfig.json`: `"module": "CommonJS"`, `"moduleResolution": "node"` — değiştirme
- `prisma.config.ts` ile datasource URL yönetiliyor (schema.prisma'da `url` alanı yok)
- Seed: `tsx prisma/seed.ts` (ts-node değil)
- `@db.Timestamp(0)` **KULLANMA** → `@db.DateTime(0)` kullan (MySQL 8.0 uyumu)
- Migration adı: `npx prisma migrate dev --name <snake_case_isim>`

---

## BalanceService Kuralı

Hesap bakiyesi her zaman `BalanceService` üzerinden değişir, Prisma `$transaction` içinde:

```typescript
await this.prisma.$transaction(async (tx) => {
  const transaction = await tx.transaction.create({ ... });
  await this.balanceService.apply(tx, accountId, type, amount);
});

// Geri alma:
await this.balanceService.revert(tx, accountId, type, amount);
```

`account.update({ balance: ... })` ile doğrudan değişiklik **yasak**.

**Spec dosyalarında mock zorunlu:**
```typescript
const mockBalanceService = { apply: jest.fn(), revert: jest.fn() };
{ provide: BalanceService, useValue: mockBalanceService }
```

Mock eksikse `TypeError: this.balanceService.apply is not a function` patlar (PR #1'de 4 testin patlamasının nedeni buydu).

---

## Auth Akışı

- JWT access token: 15 dakika, refresh token: 7 gün
- Google OAuth web flow: `GET /api/auth/google/callback` → Flutter deep link
- Google OAuth mobile: `POST /api/auth/google/mobile` (ID token + `aud` claim doğrulaması)

---

## Test Yazma Kuralları

- Unit test: `<feature>.service.spec.ts` — her servis için
- E2E test: `test/<feature>.e2e-spec.ts` — kritik akışlar için
- **Yeni dependency injekte ettiğinde** mock'ı **tüm** ilgili spec dosyalarına ekle — refactoring'de en sık atlanan adım
- Service metodu yeniden adlandırınca `grep -r "oldName" src/**/*.spec.ts` ile mock'ları da güncelle
- Push öncesi `npm run lint && npm test && npm run build` lokal'de yeşil olmalı (CI bunu kontrol eder ama lokal hız önemli)
