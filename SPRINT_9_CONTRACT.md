# Sprint 9 Contract — Enflasyon-Duyarlı Bütçeleme

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. Bir taraf "endpoint adı ne?" diye sormasın, diğer taraf "DTO neydi?" demesin. Sprint başında PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya sprint sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** `DEVELOPMENT_PLAN_V2.md → Section 8.6` mimarisinin sözleşmeye dökülmüş hali.

---

## 0. Sprint Hedefi

Türkiye'de yüksek enflasyon ortamında "sabit bütçe" anlamsız. Bu sprint kullanıcının bütçesini canlı tutar — TÜİK EVDS API'sinden aylık TÜFE verilerini çeker, kategoriye göre eşleştirir, ve **(a)** kullanıcıya "bütçeni şu kadar artır" önerisi gösterir, **(b)** "senin harcaman vs enflasyon" karşılaştırma raporu sunar.

**Out of scope:** Multiple para birimi (Sprint 10), insight üretimi (Sprint 11), aile bütçesi (Sprint 12).

---

## 1. Veri Modelleri (✅ schema.prisma'da mevcut)

```prisma
model InflationRate {
  id          String   @id @default(uuid()) @db.VarChar(36)
  categoryKey String   @map("category_key") @db.VarChar(50)   // "genel", "gida", "ulasim", vb.
  year        Int
  month       Int                                              // 1-12
  monthlyRate Decimal  @map("monthly_rate") @db.Decimal(6, 2) // % aylık değişim
  yearlyRate  Decimal? @map("yearly_rate") @db.Decimal(6, 2)  // % yıllık değişim (12 ay öncesi yoksa null)
  fetchedAt   DateTime @default(now()) @map("fetched_at") @db.DateTime(0)

  @@unique([categoryKey, year, month])
  @@map("inflation_rates")
}

model CategoryInflationMap {
  id           String @id @default(uuid()) @db.VarChar(36)
  categoryId   String @map("category_id") @db.VarChar(36)
  inflationKey String @map("inflation_key") @db.VarChar(50)   // InflationRate.categoryKey ile join

  category Category @relation(fields: [categoryId], references: [id])

  @@unique([categoryId])
  @@map("category_inflation_maps")
}
```

**Sprint 9 ilk işi:** `npx prisma migrate dev --name add_inflation_models` (model schema'da, migration eksik).

---

## 2. Sabit Tanımlar

### 2.1 InflationCategoryKey (TÜİK seri kodu eşleşmesi)

Backend'de `api/src/modules/inflation/inflation.constants.ts` altında:

```typescript
export const EVDS_SERIES_MAP = {
  genel:        'TP.FG.J0',   // Genel TÜFE
  gida:         'TP.FG.J01',  // Gıda
  alkol_tutun:  'TP.FG.J02',
  giyim:        'TP.FG.J03',
  konut:        'TP.FG.J04',
  mobilya:      'TP.FG.J05',
  saglik:       'TP.FG.J06',
  ulasim:       'TP.FG.J07',
  haberlesme:   'TP.FG.J08',
  eglence:      'TP.FG.J09',
  egitim:       'TP.FG.J10',
  lokanta:      'TP.FG.J11',
  diger:        'TP.FG.J12',
} as const;

export type InflationCategoryKey = keyof typeof EVDS_SERIES_MAP;
```

Frontend `mobile/lib/core/constants/inflation_keys.dart`:

```dart
class InflationCategoryKey {
  static const genel = 'genel';
  static const gida = 'gida';
  // ... aynı liste
  static const all = [genel, gida, /* ... */ diger];
}
```

### 2.2 EVDS API yapılandırması

```env
EVDS_API_KEY=<TCMB EVDS API key — kullanıcı sağlayacak>
EVDS_BASE_URL=https://evds2.tcmb.gov.tr/service/evds/
```

`.env.example`'a eklenmeli (zaten Sprint 9 için yer ayrılmış).

---

## 3. DTOs (TypeScript / Dart isim eşleşmesi)

| Backend (DTO) | Frontend (Model) | Alanlar |
|---|---|---|
| `InflationRateDto` | `InflationRateModel` | `categoryKey: string, year: number, month: number, monthlyRate: number, yearlyRate: number \| null, fetchedAt: string (ISO 8601)` |
| `InflationSuggestionDto` | `InflationSuggestionModel` | `budgetId: string, currentAmount: number, suggestedAmount: number, cumulativeRate: number, monthsSinceUpdate: number, categoryKey: string` |
| `InflationComparisonRowDto` | `InflationComparisonRowModel` | `categoryId: string, categoryName: string, lastPeriodSpent: number, currentPeriodSpent: number, userChangeRate: number, inflationRate: number, status: 'BELOW' \| 'EQUAL' \| 'ABOVE'` |
| `ApplyInflationDto` (request body) | — | `newAmount: number` (validation: positive, min 1, max 9999999.99) |

**JSON serialization kuralı:** Tüm `Decimal` alanlar wire'da `number` olarak gider (backend `class-transformer` `@Type(() => Number)`, Dart `num.toDouble()`).

---

## 4. Endpoint Contract

Tüm endpoint'ler `JwtAuthGuard` korumalı, response envelope `{ success, statusCode, data }`.

### 4.1 `GET /api/inflation/current`

Güncel ay için tüm kategorilerin enflasyon oranları.

**Request:** Query parametre yok.

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": [
    { "categoryKey": "genel", "year": 2026, "month": 4, "monthlyRate": 2.45, "yearlyRate": 38.12, "fetchedAt": "2026-05-05T10:00:00.000Z" },
    { "categoryKey": "gida",  "year": 2026, "month": 4, "monthlyRate": 3.12, "yearlyRate": 45.67, "fetchedAt": "2026-05-05T10:00:00.000Z" }
  ]
}
```

**Boş veri durumu (henüz hiç çekilmemiş):** `data: []` döner, hata değildir. Frontend bu durumda "Enflasyon verisi henüz hazır değil" mesajı gösterir.

### 4.2 `GET /api/inflation/history?months=N`

**Query:** `months` (number, default 6, min 1, max 24).

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "genel":  [{ "year": 2026, "month": 4, "monthlyRate": 2.45, "yearlyRate": 38.12 }, ...],
    "gida":   [{ "year": 2026, "month": 4, "monthlyRate": 3.12, "yearlyRate": 45.67 }, ...]
  }
}
```

> Map yapısı dikkat: key `categoryKey`, value chronological ascending array (eskiden yeniye).

### 4.3 `GET /api/budgets/:id/inflation-suggestion`

Belirtilen bütçe için ayarlama önerisi hesapla.

**Path:** `:id` = budget UUID. `404` döner: bütçe yoksa veya kullanıcıya ait değilse.

**Hesaplama mantığı (backend):**
1. `Budget` → `Category` → `CategoryInflationMap.inflationKey` ile TÜİK key'i bul. Map yoksa **422 Unprocessable Entity** dön (mesaj: "Bu kategori için enflasyon eşleştirmesi tanımlı değil").
2. `Budget.updatedAt`'ten bu yana kaç ay geçti hesapla (`monthsSinceUpdate`, en az 1).
3. Geçen aylardaki `monthlyRate`'leri kümülatif çarp: `cumulativeRate = ((1 + r1/100) × (1 + r2/100) × ... × (1 + rN/100) − 1) × 100`.
4. `suggestedAmount = currentAmount × (1 + cumulativeRate / 100)`, 2 decimal'a yuvarla.

**Anlamlılık eşiği:** `cumulativeRate < 5%` VE `(suggestedAmount − currentAmount) < 100 TL` ise **204 No Content** dön (öneri vermeye değmez, frontend kart göstermez).

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "budgetId": "uuid",
    "currentAmount": 3000.00,
    "suggestedAmount": 3372.00,
    "cumulativeRate": 12.40,
    "monthsSinceUpdate": 3,
    "categoryKey": "gida"
  }
}
```

### 4.4 `POST /api/budgets/:id/apply-inflation`

Önerilen tutarı uygula (kullanıcı "Güncelle" butonuna bastığında).

**Body:**
```json
{ "newAmount": 3372.00 }
```

**Validation:**
- `newAmount`: required, positive, max 9999999.99.
- `newAmount`'un `inflation-suggestion` ile dönen değerin **±%10'u** içinde olduğunu doğrula (manipülasyon koruması). Aksi halde 400.

**Side effect:** `BudgetService.update()` standart akış üzerinden çalışsın — yani mevcut `BudgetUpdatedEvent` emit edilsin, listener'lar (varsa) tetiklensin.

**Response 200:** Güncellenmiş `BudgetDto` döner (mevcut formatın aynısı).

### 4.5 `GET /api/reports/inflation-comparison?period=2026-04`

**Query:** `period` (string, format `YYYY-MM`, default mevcut ay).

**Hesaplama:**
- Her aktif bütçe için (period ayında):
  - `lastPeriodSpent` = bir önceki ay aynı kategoride harcama
  - `currentPeriodSpent` = period ayında aynı kategoride harcama
  - `userChangeRate` = `((current − last) / last) × 100` (last 0 ise null)
  - `inflationRate` = period ayının `monthlyRate` değeri (kategori → CategoryInflationMap → InflationRate)
  - `status` = `userChangeRate > inflationRate + 1` → `'ABOVE'`, `userChangeRate < inflationRate − 1` → `'BELOW'`, else `'EQUAL'`

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "period": "2026-04",
    "rows": [
      {
        "categoryId": "uuid",
        "categoryName": "Market",
        "lastPeriodSpent": 2800.00,
        "currentPeriodSpent": 3100.00,
        "userChangeRate": 10.71,
        "inflationRate": 8.20,
        "status": "ABOVE"
      }
    ],
    "summary": {
      "categoriesBelow": 2,
      "categoriesAbove": 1,
      "categoriesEqual": 0
    }
  }
}
```

---

## 5. Cron / Scheduled Job

| Cron expr | Job | Etki |
|---|---|---|
| `0 10 5 * *` | `InflationFetchJob` | EVDS API'den son 13 ayın endeksini çeker, aylık + yıllık % hesaplar, `InflationRate` tablosuna upsert. **Frontend'e direkt etki yok**, ama `/api/inflation/current` sonucu güncellenmiş olur. |
| `0 10 10 * *` | (Aynı job, fallback) | TÜİK 5'inde yayınlamadıysa 10'unda tekrar dene. Aynı upsert idempotent çalışır. |

**EVDS API hata yönetimi (backend):**
- 3 retry, 5sn arayla
- Boş response → warn log, mevcut DB verisi korunur
- Network/401/500 → error log, mevcut DB verisi korunur (production'da kullanıcı eski enflasyonu görür, bu kabul edilebilir)

---

## 6. UI Yerleşim Sözleşmesi

| Widget | Konum | Tetikleme |
|---|---|---|
| `InflationSuggestionCard` | `BudgetsPage` üst bölümü, sayfa açılınca gösterilir | Her aktif bütçe için `GET /api/budgets/:id/inflation-suggestion` çağrısı, **204 dönerse kart gösterme** |
| `InflationComparisonTable` | `ReportsPage` yeni tab "Enflasyon" | `GET /api/reports/inflation-comparison?period=...` |
| `InflationTrendChart` | `ReportsPage` aynı tab, tablonun altı | `GET /api/inflation/history?months=6` + kullanıcının harcama trendini overlay |

**Tasarım kuralı:** `BELOW` → mint yeşil (`AppColors.secondary`), `ABOVE` → şeftali turuncu (`AppColors.tertiary`), `EQUAL` → on-surface gri.

---

## 7. Hata Envelope (referans)

Standart `GlobalExceptionFilter` formatına uyar:

```json
{
  "success": false,
  "statusCode": 422,
  "message": "Bu kategori için enflasyon eşleştirmesi tanımlı değil",
  "error": "Unprocessable Entity",
  "timestamp": "2026-05-06T14:30:00.000Z",
  "path": "/api/budgets/abc-123/inflation-suggestion"
}
```

| Endpoint | Olası özel kodlar |
|---|---|
| `GET /api/inflation/*` | 401 (auth eksik) |
| `GET /api/budgets/:id/inflation-suggestion` | 401, 404 (bütçe yok), 422 (kategori map yok), 204 (anlamlı öneri yok) |
| `POST /api/budgets/:id/apply-inflation` | 401, 404, 400 (newAmount validation veya öneri ±%10 dışı) |
| `GET /api/reports/inflation-comparison` | 401, 400 (geçersiz period format) |

---

## 8. Bağımsızlık Sözleşmesi

| Backend yazarken | Frontend yazarken |
|---|---|
| Mock veri lazımsa: `prisma/seed.ts`'e geçici `InflationRate` satırları ekle (Sprint 9 sonunda kaldırılacak), commit etme | Backend ayağa kalkmadan önce: repository'lerde mock JSON döndür, BLoC'u izole test et |
| EVDS API key yoksa: `InflationFetchJob`'u `if (!apiKey) return` ile atla, log warn at | `204` durumunu mutlaka handle et (kart gösterme) — boş state'i tasarımla doğrula |
| Yeni endpoint eklemeden ÖNCE bu dosyayı güncelle, PR mesajına ekle | DTO'da olmayan alan kullanma — backend'e sor |

---

## 9. Tamamlanma Kriterleri (Definition of Done)

### Backend
- [ ] `npx prisma migrate dev --name add_inflation_models` koşmuş, migration commit'lenmiş
- [ ] 5 endpoint canlı, hepsi `@UseGuards(JwtAuthGuard)`
- [ ] Cron job test ortamında (`@Cron`) tetiklenebilir, mock EVDS yanıtıyla doğrulanmış
- [ ] Birim testler: `inflation.service.spec.ts` (kümülatif rate hesaplaması), `budgets.service.spec.ts` ek (suggestion mantığı)
- [ ] `npm run lint && npm test && npm run build` lokal'de yeşil **(push öncesi şart)**

### Frontend
- [ ] 3 widget render olur, BLoC entegre
- [ ] `InflationSuggestionCard` 204 → null döndürür, görünmez
- [ ] BudgetsPage + ReportsPage entegrasyonu manuel test edildi (en az 1 öneri kartı + tablo görünümü ile)
- [ ] `inflation_bloc_test.dart` (suggestion fetch + apply flow)
- [ ] `flutter analyze && flutter test` lokal'de yeşil **(push öncesi şart)**

### PR Gate
- [ ] CI 3/3 yeşil
- [ ] Bu dosya değişti mi → PR description'da diff özeti
- [ ] TASK.md Sprint 9 maddeleri `[x]` olarak işaretli

---

## 10. Açık Sorular (PM çözecek)

> Sprint başlamadan önce kullanıcıya sorulacak / kullanıcı karar verecek noktalar:

1. ~~**EVDS API key:** Kullanıcı `https://evds2.tcmb.gov.tr` üzerinden alıp `.env`'e yazacak.~~ ✅ `.env`'de mevcut (kullanıcı 2026-05-06).
2. **Suggestion eşiği:** "%5 veya 100 TL" eşiği muhafazakâr mı agresif mi? V1'de muhafazakâr başlayıp telemetri ile ayarlayabiliriz.
3. **`InflationRate` retention:** Geçmiş ne kadar saklanacak? Şimdilik sınırsız öneririm, 10 yıllık veri bile <2MB.
