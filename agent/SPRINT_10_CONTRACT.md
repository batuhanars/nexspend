# Sprint 10 Contract — Akıllı Harcama Analizi (Insights)

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. Sprint başında PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya sprint sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** `DEVELOPMENT_PLAN_V2.md → Section 8.8` + `wallet-app-master.md §11` mimarisinin sözleşmeye dökülmüş hali.

---

## 0. Sprint Hedefi

7 kural tabanlı insight motoru. Kullanıcı "ne kadar harcadın" değil, "neden harcadın, nasıl azaltabilirsin" sorusuna cevap alır. Her ayın 1'inde cron otomatik üretir; kullanıcı dashboard'da okur, kapat veya aksiyon alır.

**Out of scope:** ML/LLM tabanlı insight (v1 kural tabanlı), Sprint 11 aile bütçesi, portföy insight'ı (V3 Portföy modülü ile karıştırma).

---

## 1. Veri Modeli (✅ schema.prisma'da mevcut)

```prisma
model Insight {
  id          String   @id @default(uuid()) @db.VarChar(36)
  userId      String   @map("user_id") @db.VarChar(36)
  ruleId      String   @map("rule_id") @db.VarChar(50)     // "spending_spike" vb.
  title       String   @db.VarChar(200)
  message     String   @db.Text
  category    String?  @db.VarChar(50)                     // ilgili kategori adı (opsiyonel)
  severity    String   @db.VarChar(10)                     // "info" | "warning" | "success"
  data        String?  @db.Text                            // JSON — grafik verisi için
  isRead      Boolean  @default(false) @map("is_read")
  isDismissed Boolean  @default(false) @map("is_dismissed")
  period      String   @db.VarChar(7)                      // "2026-04" (hangi ay için)
  createdAt   DateTime @default(now()) @map("created_at") @db.DateTime(0)

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, period, isDismissed], map: "idx_insights_user_period")
  @@map("insights")
}
```

> **Önemli:** DEVELOPMENT_PLAN_V2.md'de `@db.Timestamp(0)` var — bu **yanlış**. `@db.DateTime(0)` olmalı (Gotcha §8.1). Yukarıdaki tanım düzeltilmiş haldir.
>
> **User ilişkisi:** `User` modeline `insights Insight[]` ilişkisi eklenir.

**Sprint 10 ilk işi:** `npx prisma migrate dev --name add_insights`

---

## 2. Sabit Tanımlar

### 2.1 Insight Rule ID'leri

Backend `api/src/modules/insights/insight.constants.ts`:

```typescript
export const INSIGHT_RULES = [
  'spending_spike',       // Kategoride geçen aya göre %30+ artış
  'unused_subscription',  // Abonelik var ama son 60 günde ilgili harcama yok
  'category_overrun',     // Bütçenin %70'i ayın ilk 15 gününde bitti
  'recurring_drift',      // Tekrarlanan işlem miktarı son 3 ayda %20+ değişti
  'debt_aging',           // Verilen alacak 30+ gün tahsil edilmedi
  'inflation_gap',        // Kategori harcaması ilgili enflasyonun üstünde (Sprint 9 verisi kullanılır)
  'saving_streak',        // Pozitif net akış (gelir > gider) 3+ ay üst üste
] as const;

export type InsightRuleId = (typeof INSIGHT_RULES)[number];

export const INSIGHT_SEVERITY_MAP: Record<InsightRuleId, 'info' | 'warning' | 'success'> = {
  spending_spike:      'warning',
  unused_subscription: 'warning',
  category_overrun:    'warning',
  recurring_drift:     'info',
  debt_aging:          'warning',
  inflation_gap:       'info',
  saving_streak:       'success',
};
```

Frontend `mobile/lib/core/constants/insight_rules.dart`:

```dart
class InsightRuleId {
  static const spendingSpike      = 'spending_spike';
  static const unusedSubscription = 'unused_subscription';
  static const categoryOverrun    = 'category_overrun';
  static const recurringDrift     = 'recurring_drift';
  static const debtAging          = 'debt_aging';
  static const inflationGap       = 'inflation_gap';
  static const savingStreak       = 'saving_streak';
}

enum InsightSeverity { info, warning, success }
```

### 2.2 Kural Tetikleme Eşikleri

| Rule | Tetikleme koşulu | Mesaj şablonu (Türkçe, samimi ton) |
|---|---|---|
| `spending_spike` | Kategoride geçen ay ortalamasına göre ≥%30 artış | "Market harcaman bu ay %42 arttı. Fark: +₺882" |
| `unused_subscription` | Aktif abonelik var, son 60 günde o kategoride 0 işlem | "Spotify'ı 2 aydır açmamışsın 👀 Yıllık tasarruf: ₺719,88" |
| `category_overrun` | Bütçenin ≥%70'i ayın ilk 15 gününde tüketildiyse | "Market bütçen bu hızla ₺4.200 ile kapanır. Kalan bütçe: ₺900" |
| `recurring_drift` | Tekrarlanan işlem miktarı son 3 ayda ≥%20 değişti | "Elektrik faturan 3 aydır artıyor: ₺320 → ₺440" |
| `debt_aging` | Verilen alacak 30+ gün tahsil edilmedi | "Ahmet'e verilen ₺500 30 gündür tahsil edilmedi" |
| `inflation_gap` | Kategori harcaması ilgili TÜFE oranının >%5 üstünde | "Market harcaman enflasyonun %2,5 üstünde (+₺70)" |
| `saving_streak` | Net akış (gelir−gider) 3+ ay üst üste pozitif | "Tebrikler! 3 ay üst üste tasarruf ettın 🎉 Ortalama: +₺1.250/ay" |

### 2.3 Retention Politikası

- **Retention:** 6 ay — `isDismissed: true` VE `createdAt < 6 ay önce` olan kayıtlar her ayın 1'inde silinir.
- **Periyot benzersizliği:** Aynı `(userId, ruleId, period)` kombinasyonu için sadece 1 insight. Yeniden üretimde upsert.

---

## 3. DTOs (TypeScript / Dart isim eşleşmesi)

| Backend (DTO) | Frontend (Model) | Alanlar |
|---|---|---|
| `InsightDto` | `InsightModel` | `id: string, ruleId: string, title: string, message: string, category: string\|null, severity: 'info'\|'warning'\|'success', data: any\|null, isRead: boolean, isDismissed: boolean, period: string, createdAt: string` |
| `InsightSummaryDto` | `InsightSummaryModel` | `unreadCount: number, totalCount: number, latestInsight: InsightDto\|null` |

**JSON serialization:** `data` alanı `string` (JSON stringified) olarak wire'dan geliyor; frontend `jsonDecode(insight.data)` ile parse eder.

---

## 4. Endpoint Contract

Tüm endpoint'ler `JwtAuthGuard` korumalı.

### 4.1 `GET /api/insights`

**Query:** `period?: string (YYYY-MM, default bu ay), unread?: boolean, page?: number (default 1), limit?: number (default 20, max 100)`

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "items": [
      {
        "id": "uuid",
        "ruleId": "spending_spike",
        "title": "Market harcaman bu ay %42 arttı",
        "message": "Geçen 3 ayın ortalaması ₺2.100, bu ay ₺2.982. Fark: +₺882.",
        "category": "Market",
        "severity": "warning",
        "data": null,
        "isRead": false,
        "isDismissed": false,
        "period": "2026-04",
        "createdAt": "2026-05-01T08:05:00.000Z"
      }
    ],
    "total": 5,
    "page": 1,
    "limit": 20
  }
}
```

### 4.2 `GET /api/insights/summary`

Dashboard badge'i için hızlı özet.

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "unreadCount": 3,
    "totalCount": 5,
    "latestInsight": { /* InsightDto */ }
  }
}
```

### 4.3 `PATCH /api/insights/:id/read`

Okundu olarak işaretle.

**Response 200:** Güncellenmiş `InsightDto` döner.

**Hata:** Insight kullanıcıya ait değilse `404`.

### 4.4 `PATCH /api/insights/:id/dismiss`

Kapat (bir daha gösterme).

**Response 200:** Güncellenmiş `InsightDto` döner. `isDismissed: true` olur.

### 4.5 `POST /api/insights/generate`

Manuel tetikleme (kullanıcı "Analiz Et" butonuna basar veya test için).

**Body:** Yok.

**Side effect:** O anki ay için tüm kuralları çalıştır, insight'ları upsert et.

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "generated": 4,
    "period": "2026-05"
  }
}
```

---

## 5. Cron / Scheduled Job

| Cron expr | Job | Etki |
|---|---|---|
| `0 8 1 * *` | `MonthlyInsightJob.run()` | Her ayın 1'i saat 08:00 — önceki ayın (period = geçen ay) verisiyle tüm kullanıcılar için insight üret. Push notification: "Aylık finansal raporun hazır! 📊" |
| `0 2 1 * *` | `InsightCleanupJob.run()` | Her ayın 1'i saat 02:00 — 6 aydan eski + isDismissed kayıtları sil. |

**Kural işleme sırası:** Her kullanıcı için 7 kural sequential çalışır. Bir kural hata verirse (veri eksikse) o kural skip edilir, diğerleri devam eder.

**inflation_gap kuralı ön koşul:** Bu kural `InflationRate` tablosundan veri okur — Sprint 9 bağımlılığı. `InflationRate` boşsa kural skip edilir ve `insight.data`'ya `"skipped": "no_inflation_data"` yazılır.

**Manuel tetikleme:**

```bash
cd api && npx ts-node -O '{"module":"CommonJS"}' scripts/trigger-insight-generation.ts
```

---

## 6. UI Yerleşim Sözleşmesi

### 6.1 Home Dashboard — Akıllı Öneriler Bölümü

Konum: `presentation/home/widgets/insights_carousel.dart`  
Tetikleme: `GET /api/insights/summary`

```
┌─────────────────────────────────────────────┐
│ AKILLı ÖNERİLER                    [3] →    │
│                                              │
│ ⚠️  Market harcaman %42 arttı               │
│     "Bu ay ₺882 fazla harcadın"    [Kapat]  │
│                                              │
│ ⚠️  Spotify'ı 2 aydır açmadın               │
│     "Yıllık tasarruf: ₺719"        [Kapat]  │
└─────────────────────────────────────────────┘
```

- `[3]` badge: `unreadCount` — `AppColors.tertiary` arka plan (turuncu)
- `→` "Tüm Öneriler" → `/insights`
- Yatay scroll (kaydırılabilir insight kartları)
- İlk açılışta: `GET /api/insights` ile son 3 insight yüklenir

### 6.2 /insights — Tam Insight Listesi

`presentation/insights/pages/insights_page.dart`

- "Bu Ay" / "Geçen Ay" tab filtreleri
- `insight_card.dart` listesi: ikon (warning=turuncu, info=lavender, success=mint), başlık, mesaj, tarih, [Kapat] butonu
- "Tümünü Okundu İşaretle" üst menüsü
- Boş durum: "Harika! Hiç öneriniz yok 🎉"

### 6.3 Severity Renk Kodlaması

- `warning` → `AppColors.tertiary` (#FFB68F şeftali-turuncu)
- `info` → `AppColors.primary` (#BAC3FF lavender)
- `success` → `AppColors.secondary` (#70D8C8 mint)

---

## 7. Hata Envelope (referans)

| Endpoint | Olası özel kodlar |
|---|---|
| `GET /api/insights` | 401, 400 (geçersiz period format: YYYY-MM bekleniyor) |
| `GET /api/insights/summary` | 401 |
| `PATCH /api/insights/:id/read` | 401, 404 |
| `PATCH /api/insights/:id/dismiss` | 401, 404 |
| `POST /api/insights/generate` | 401 |

---

## 8. Bağımsızlık Sözleşmesi

| Backend yazarken | Frontend yazarken |
|---|---|
| Kural mantığı izole unit test edilmeli: her rule function, mock data ile doğrulanabilir | `data` alanı backend değiştirirse UI etkilenebilir — `data` şimdilik null döner, grafik sonraki sprint'te eklenebilir |
| `inflation_gap` kuralı Sprint 9 tablosuna bağlı — tablo boşsa kural skip, hata değil | `isDismissed: true` olan insight'ı listede gösterme (backend zaten filter ediyor, frontend de double-check) |
| Push notification: FCM tek mesaj, "Aylık finansal raporun hazır! 📊" — kişiselleştirilmiş değil (Sprint 11 kapsamı bu) | Dismiss animasyonu: kart sağa/sola swipe ile dismiss edilebilir (BLoC dismiss event'i tetikler) |

---

## 9. Tamamlanma Kriterleri (Definition of Done)

### Backend

- [ ] `npx prisma migrate dev --name add_insights` koşmuş
- [ ] 7 kural implementasyonu — her kural için en az 2 unit test (triggered + not triggered senaryosu)
- [ ] Cron job manuel tetiklenince `Insight` tablosuna kayıtlar düşüyor (smoke test)
- [ ] Cleanup job eski kayıtları temizliyor
- [ ] 5 endpoint canlı, tümü `@UseGuards(JwtAuthGuard)`
- [ ] `npm run lint && npm test && npm run build` yeşil

### Frontend

- [ ] Home dashboard `insights_carousel.dart` render oluyor (boş + 1+ insight senaryoları)
- [ ] `/insights` sayfası: kart listesi + dismiss + okundu işareti
- [ ] Badge sayısı doğru güncelleniyor (dismiss sonrası azalıyor)
- [ ] `insights_bloc_test.dart` (fetch + dismiss + read akışları)
- [ ] `flutter analyze && flutter test` lokal'de yeşil

### PR Gate

- [ ] CI 3/3 yeşil
- [ ] TASK.md Sprint 11 maddeleri `[x]` olarak işaretli

---

## 10. Açık Sorular (Çözüldü)

1. ✅ **7 kural seti:** `wallet-app-master.md §11` listesi kullanıldı (DEVELOPMENT_PLAN_V2'deki listeden farklı ama daha proje-spesifik ve Sprint 9 enflasyon verisini kullanıyor).
2. ✅ **Navigasyon:** `/insights` full page — Home carousel'dan erişim, ayrı tab yok.
3. ✅ **Periyot benzersizliği:** `(userId, ruleId, period)` unique — upsert ile yeniden üretimde mevcut override edilir.
4. ✅ **`data` alanı:** Şimdilik null, grafik entegrasyonu ilerleyen sprint'lere ertelendi.
