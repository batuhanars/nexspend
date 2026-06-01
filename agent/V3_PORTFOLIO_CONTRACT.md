# Sprint 10 Contract — Altın/Döviz Portföy Takibi

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. Sprint başında PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya sprint sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** `DEVELOPMENT_PLAN_V2.md → Section 8.7` mimarisinin sözleşmeye dökülmüş hali.

---

## 0. Sprint Hedefi

Türk kullanıcıların TL dışında tuttuğu varlıkları (altın, döviz) uygulama içinde takip edebilmesi. Kullanıcı "gram altın aldım, kaç TL değer" görür; canlı kur ile portföy değeri ve kâr/zarar hesaplanır.

**Out of scope:** Transaction Hub entegrasyonu (portföy al/sat Transaction Hub'a düşmüyor, bağımsız tablo), kripto, çoklu hesap para birimi değişikliği (TRY-only kural V1'den devam), Sprint 11 insight motoru.

---

## 1. Veri Modelleri (✅ schema.prisma'da mevcut)

```prisma
enum AssetType {
  USD
  EUR
  GBP
  GOLD_GRAM
  GOLD_QUARTER    // çeyrek altın
  GOLD_HALF       // yarım altın
  GOLD_FULL       // tam altın (cumhuriyet)
}

model PortfolioAsset {
  id           String    @id @default(uuid()) @db.VarChar(36)
  accountId    String    @map("account_id") @db.VarChar(36)
  assetType    AssetType @map("asset_type")
  quantity     Decimal   @db.Decimal(15, 4)              // 3.5 gram, 500 USD
  avgBuyPrice  Decimal   @map("avg_buy_price") @db.Decimal(15, 4)  // ağırlıklı ortalama alış TL
  totalCost    Decimal   @map("total_cost") @db.Decimal(15, 2)     // toplam maliyet TL
  createdAt    DateTime  @default(now()) @map("created_at") @db.DateTime(0)
  updatedAt    DateTime  @updatedAt @map("updated_at") @db.DateTime(0)

  account      Account       @relation(fields: [accountId], references: [id], onDelete: Cascade)
  transactions PortfolioTx[]

  @@unique([accountId, assetType])
  @@map("portfolio_assets")
}

model PortfolioTx {
  id           String    @id @default(uuid()) @db.VarChar(36)
  assetId      String    @map("asset_id") @db.VarChar(36)
  type         String    @db.VarChar(4)                 // "BUY" | "SELL"
  quantity     Decimal   @db.Decimal(15, 4)
  pricePerUnit Decimal   @map("price_per_unit") @db.Decimal(15, 4) // birim fiyat TL
  totalAmount  Decimal   @map("total_amount") @db.Decimal(15, 2)
  txDate       DateTime  @map("tx_date") @db.DateTime(0)
  note         String?   @db.Text
  createdAt    DateTime  @default(now()) @map("created_at") @db.DateTime(0)

  asset PortfolioAsset @relation(fields: [assetId], references: [id], onDelete: Cascade)

  @@map("portfolio_transactions")
}

model ExchangeRate {
  id         String    @id @default(uuid()) @db.VarChar(36)
  assetType  AssetType @map("asset_type")
  buyPrice   Decimal   @map("buy_price") @db.Decimal(15, 4)   // alış TL
  sellPrice  Decimal   @map("sell_price") @db.Decimal(15, 4)  // satış TL
  fetchedAt  DateTime  @default(now()) @map("fetched_at") @db.DateTime(0)

  @@unique([assetType])
  @@map("exchange_rates")
}
```

> **Önemli:** DEVELOPMENT_PLAN_V2.md'deki model tanımlarında `@db.Timestamp(0)` kullanılmış — bu **yanlış**. Tüm datetime alanlar `@db.DateTime(0)` olmalı (Gotcha §8.1). Yukarıdaki tanım düzeltilmiş haldir.
>
> **Account ilişkisi:** `Account` modeline `portfolioAssets PortfolioAsset[]` ilişkisi eklenir (schema.prisma güncellemesi gerekiyor).

**Sprint 10 ilk işi:** `npx prisma migrate dev --name add_portfolio_models`

---

## 2. Sabit Tanımlar

### 2.1 AssetType → Görüntüleme Adı

Backend `api/src/modules/portfolio/portfolio.constants.ts`:

```typescript
export const ASSET_DISPLAY_NAMES: Record<AssetType, string> = {
  USD:          'Amerikan Doları',
  EUR:          'Euro',
  GBP:          'İngiliz Sterlini',
  GOLD_GRAM:    'Gram Altın',
  GOLD_QUARTER: 'Çeyrek Altın',
  GOLD_HALF:    'Yarım Altın',
  GOLD_FULL:    'Tam Altın',
};

export const ASSET_UNITS: Record<AssetType, string> = {
  USD: 'USD', EUR: 'EUR', GBP: 'GBP',
  GOLD_GRAM: 'gram', GOLD_QUARTER: 'adet', GOLD_HALF: 'adet', GOLD_FULL: 'adet',
};
```

Frontend `mobile/lib/core/constants/asset_type.dart`:

```dart
enum AssetType { usd, eur, gbp, goldGram, goldQuarter, goldHalf, goldFull }

extension AssetTypeX on AssetType {
  String get displayName => switch (this) {
    AssetType.usd =>          'Amerikan Doları',
    AssetType.eur =>          'Euro',
    AssetType.gbp =>          'İngiliz Sterlini',
    AssetType.goldGram =>     'Gram Altın',
    AssetType.goldQuarter =>  'Çeyrek Altın',
    AssetType.goldHalf =>     'Yarım Altın',
    AssetType.goldFull =>     'Tam Altın',
  };
}
```

### 2.2 Kur Veri Kaynakları

**Döviz (USD/EUR/GBP):** TCMB Günlük Kur Tablosu XML

```
URL: https://www.tcmb.gov.tr/kurlar/today.xml
Auth: Yok (herkese açık)
Format: XML — <Currency CurrencyCode="USD"><ForexBuying>...</ForexBuying><ForexSelling>...</ForexSelling>
Güncelleme: Günde 1 kez (mesai günü ~15:30 Türkiye saati)
```

**Altın:** TCMB EVDS3 (Sprint 9 ile aynı API key + header auth pattern)

```
Series: TP.MK.F.ALTIN (gram altın alış, TL/gram)
        TP.MK.F.ALTIN.S (gram altın satış, TL/gram)
Base URL: https://evds3.tcmb.gov.tr/igmevdsms-dis/
Auth: key: <EVDS_API_KEY> (HTTP header)
Güncelleme: Mesai günleri, gün içinde birkaç kez
```

> **KRİTİK (External API Smoke Test Kuralı):** Implementasyona başlamadan ÖNCE, bu iki endpoint'i `curl` ile doğrula. TCMB serileri değişmiş olabilir. Doğrulama script'i:
> ```bash
> # Döviz XML
> curl -s "https://www.tcmb.gov.tr/kurlar/today.xml" | head -40
> # Altın (EVDS3)
> curl -s -H "key: $EVDS_API_KEY" "https://evds3.tcmb.gov.tr/igmevdsms-dis/service/evds/series=TP.MK.F.ALTIN-TP.MK.F.ALTIN.S&startDate=01-05-2026&endDate=12-05-2026&type=json&frequency=3" | head -60
> ```

**Çeyrek/yarım/tam altın hesabı:** EVDS3'te ayrı seri yoksa gram fiyatından türetilir:
- Çeyrek = 1.75 gram
- Yarım = 3.5 gram
- Tam = 7.0 gram (22 ayar cumhuriyet altını referans değerleri — güncel darphane değerleriyle karşılaştır)

### 2.3 Environment Variables

```env
# Mevcut (Sprint 9'dan)
EVDS_API_KEY=<TCMB EVDS API key>
EVDS_BASE_URL=https://evds3.tcmb.gov.tr/igmevdsms-dis/

# Yeni ekleme gereksiz — TCMB today.xml key'siz
```

---

## 3. DTOs (TypeScript / Dart isim eşleşmesi)

| Backend (DTO) | Frontend (Model) | Alanlar |
|---|---|---|
| `ExchangeRateDto` | `ExchangeRateModel` | `assetType: string, buyPrice: number, sellPrice: number, fetchedAt: string (ISO 8601)` |
| `PortfolioAssetDto` | `PortfolioAssetModel` | `id: string, accountId: string, assetType: string, quantity: number, avgBuyPrice: number, totalCost: number, currentValue: number, profitLoss: number, profitLossRate: number, updatedAt: string` |
| `PortfolioTxDto` | `PortfolioTxModel` | `id: string, assetId: string, type: 'BUY'\|'SELL', quantity: number, pricePerUnit: number, totalAmount: number, txDate: string, note: string\|null, createdAt: string` |
| `CreatePortfolioTxDto` | — (request) | `assetType: string, type: 'BUY'\|'SELL', quantity: number, pricePerUnit: number, txDate: string (ISO 8601), note?: string` |
| `PortfolioSummaryDto` | `PortfolioSummaryModel` | `totalCostTry: number, totalCurrentValueTry: number, totalProfitLoss: number, totalProfitLossRate: number, assets: PortfolioAssetDto[]` |

**Hesaplama (backend'de yapılır, frontend sadece gösterir):**

```
currentValue    = quantity × ExchangeRate.buyPrice   (o anki alış kuruna göre)
profitLoss      = currentValue - totalCost
profitLossRate  = (profitLoss / totalCost) × 100
```

**JSON serialization kuralı:** Tüm `Decimal` alanlar wire'da `number` döner (`class-transformer` + `@Type(() => Number)`), Dart `num.toDouble()`.

---

## 4. Endpoint Contract

Tüm endpoint'ler `JwtAuthGuard` korumalı, response envelope `{ success, statusCode, data }`.

### 4.1 `GET /api/exchange-rates`

Tüm desteklenen varlıkların güncel kur/fiyat bilgisi.

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": [
    { "assetType": "USD", "buyPrice": 32.10, "sellPrice": 32.45, "fetchedAt": "2026-05-12T15:30:00.000Z" },
    { "assetType": "EUR", "buyPrice": 35.20, "sellPrice": 35.60, "fetchedAt": "2026-05-12T15:30:00.000Z" },
    { "assetType": "GOLD_GRAM", "buyPrice": 3180.50, "sellPrice": 3220.00, "fetchedAt": "2026-05-12T15:30:00.000Z" }
  ]
}
```

**Boş/eski veri:** ExchangeRate tablosu henüz dolmamışsa `data: []`. Frontend "Kur verisi yükleniyor" gösterir. Öneri kartı yenileme butonu ile yeniden çek.

### 4.2 `GET /api/portfolio`

Kullanıcının tüm portföy varlıkları (canlı değer dahil).

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": [
    {
      "id": "uuid",
      "accountId": "uuid",
      "assetType": "GOLD_GRAM",
      "quantity": 5.0,
      "avgBuyPrice": 3100.00,
      "totalCost": 15500.00,
      "currentValue": 15902.50,
      "profitLoss": 402.50,
      "profitLossRate": 2.60,
      "updatedAt": "2026-05-12T12:00:00.000Z"
    }
  ]
}
```

### 4.3 `GET /api/portfolio/summary`

Tüm portföyün özet istatistiği.

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "totalCostTry": 50000.00,
    "totalCurrentValueTry": 52340.00,
    "totalProfitLoss": 2340.00,
    "totalProfitLossRate": 4.68,
    "assets": [ /* PortfolioAssetDto listesi */ ]
  }
}
```

### 4.4 `POST /api/portfolio/buy`

Varlık alım kaydı.

**Body:**
```json
{
  "assetType": "GOLD_GRAM",
  "quantity": 5.0,
  "pricePerUnit": 3100.00,
  "txDate": "2026-05-12T10:00:00.000Z",
  "note": "İş Bankası altın hesabından transfer"
}
```

**Validation:**
- `assetType`: required, geçerli AssetType enum değeri
- `quantity`: required, positive, min 0.0001
- `pricePerUnit`: required, positive, max 9999999.99
- `txDate`: required, ISO 8601, gelecek tarih kabul edilmez (max today + 1h tolerans)
- `note`: optional, max 500 karakter

**Side effect (Prisma $transaction içinde):**
1. `PortfolioTx` kaydı oluştur (type: "BUY")
2. `PortfolioAsset` güncelle (varsa) veya oluştur:
   - `quantity += gelen miktar`
   - `avgBuyPrice = (eskiMiktar × eskiAvg + gelenMiktar × gelenFiyat) / yeniMiktar` (ağırlıklı ortalama)
   - `totalCost += gelenMiktar × gelenFiyat`

**Response 201:** Güncellenmiş `PortfolioAssetDto` döner.

### 4.5 `POST /api/portfolio/sell`

Varlık satım kaydı.

**Body:** Aynı format (type doğrulaması backend'de "SELL" olarak işlenir).

**Validation ek:**
- Satılan miktar > mevcut `quantity` ise `400 Bad Request` (mesaj: "Yetersiz varlık miktarı")

**Side effect (Prisma $transaction içinde):**
1. `PortfolioTx` kaydı oluştur (type: "SELL")
2. `PortfolioAsset.quantity -= satılan miktar`
3. `PortfolioAsset.totalCost = yeniMiktar × avgBuyPrice` (avgBuyPrice değişmez — FIFO değil, ağırlıklı ortalama)
4. `quantity == 0` ise `PortfolioAsset` silinmez, bırakılır (geçmiş görünür olsun)

**Response 201:** Güncellenmiş `PortfolioAssetDto` döner.

### 4.6 `GET /api/portfolio/history`

Alım/satım işlem geçmişi.

**Query:** `assetType?: string, page?: number (default 1), limit?: number (default 20, max 100)`

**Response 200:**
```json
{
  "success": true,
  "statusCode": 200,
  "data": {
    "items": [
      {
        "id": "uuid",
        "assetId": "uuid",
        "type": "BUY",
        "quantity": 5.0,
        "pricePerUnit": 3100.00,
        "totalAmount": 15500.00,
        "txDate": "2026-05-12T10:00:00.000Z",
        "note": "İş Bankası altın hesabından transfer",
        "createdAt": "2026-05-12T10:05:00.000Z"
      }
    ],
    "total": 12,
    "page": 1,
    "limit": 20
  }
}
```

---

## 5. Cron / Scheduled Job

| Cron expr | Job | Etki |
|---|---|---|
| `0 16 * * 1-5` | `ExchangeRateFetchJob.run()` | Mesai günleri 16:00 — TCMB günlük kurun yayınlanmasından sonra (~15:30). XML parse + EVDS3 altın. `ExchangeRate` tablosunu upsert. |
| `0 10 * * 1-5` | `ExchangeRateFetchJob.runMorning()` | Mesai günleri 10:00 — sabah açılış değerleri için ek çekim (altın EVDS3 intraday güncelleniyor olabilir). |

**Manuel tetikleme:**

```bash
cd api && npx ts-node -O '{"module":"CommonJS"}' scripts/trigger-exchange-rate-fetch.ts
```

**Hata yönetimi:**
- TCMB XML 404/timeout → error log, mevcut `ExchangeRate` tablosu korunur (eski kur gösterilir)
- EVDS3 altın serisi null → GOLD_* assetType'ları skip, dövizler güncellenir
- İlk çalıştırma (boş tablo): Script manuel tetiklenir, initial seeding yapılır

---

## 6. UI Yerleşim Sözleşmesi

### 6.1 Navigasyon Kararı

**Portfolio sayfası bir tab değildir.** Mevcut 5 tab (home/transactions/budgets/debts/subscriptions) değişmez. Portföy, Home Dashboard'daki bir kart widget'ından `context.go('/portfolio')` ile açılır. `/portfolio` rotası ShellRoute'un children'ına eklenir (tab'sız, back button ile çıkılır).

### 6.2 Home Dashboard — Portföy Özet Kartı

Konum: `presentation/home/widgets/portfolio_summary_card.dart`  
Tetikleme: `GET /api/portfolio/summary`

```
┌─────────────────────────────────┐
│ PORTFÖY                    >    │
│ Toplam Değer: ₺52.340          │
│ +₺2.340  (+%4,68)  🟢          │
│                                 │
│ 💰 Gram Altın   ₺15.902 +%2,6  │
│ 💵 USD          ₺32.640 +%1,2  │
└─────────────────────────────────┘
```

- Kâr gösterimi: `AppColors.secondary` (mint yeşil), zarar: `AppColors.tertiary` (şeftali)
- Boş portföy durumu: "Portföy ekle" butonu göster
- Kur verisi yoksa: skeleton shimmer (spinner değil)

### 6.3 /portfolio — Portföy Ana Sayfası

`presentation/portfolio/pages/portfolio_page.dart`

- `exchange_rate_ticker.dart` — üst bant: USD ₺32.10 | EUR ₺35.20 | Altın ₺3.180
- `portfolio_pie_chart.dart` — varlık dağılımı pasta grafiği
- Varlık kartları listesi (`asset_card.dart`): her varlık için miktar + değer + kâr/zarar
- "Alım/Satım Ekle" FAB → `/portfolio/add-tx`

### 6.4 /portfolio/add-tx — Alım/Satım Ekleme

`presentation/portfolio/pages/add_portfolio_tx_page.dart`

- Varlık tipi seçici (dropdown)
- Miktar alanı
- Birim fiyat alanı (canlı kur ile ön doldurulan, düzenlenebilir)
- Alım / Satım toggle
- Tarih seçici (default: bugün)
- Not alanı (opsiyonel)

---

## 7. Hata Envelope (referans)

```json
{
  "success": false,
  "statusCode": 400,
  "message": "Yetersiz varlık miktarı",
  "error": "Bad Request",
  "timestamp": "2026-05-12T10:00:00.000Z",
  "path": "/api/portfolio/sell"
}
```

| Endpoint | Olası özel kodlar |
|---|---|
| `GET /api/exchange-rates` | 401 |
| `GET /api/portfolio` | 401 |
| `GET /api/portfolio/summary` | 401 |
| `POST /api/portfolio/buy` | 401, 400 (validation), 404 (accountId geçersiz) |
| `POST /api/portfolio/sell` | 401, 400 (yetersiz miktar, validation) |
| `GET /api/portfolio/history` | 401, 400 (geçersiz assetType) |

---

## 8. Bağımsızlık Sözleşmesi

| Backend yazarken | Frontend yazarken |
|---|---|
| `ExchangeRate` tablosu boşsa `/api/exchange-rates` `data: []` döner — frontend buna hazır olmalı | Kur yokken skeleton göster, "Kur yükleniyor" metni değil |
| `portfolio/buy` + `portfolio/sell` Prisma `$transaction` içinde — BalanceService **kullanılmaz** (portföy TL bakiyesini etkilemez) | `pricePerUnit` backend tarafından doğrulanmıyor (kullanıcı manuel girer), UI'da güncel kuru göster ama değiştirilebilir |
| Cron job bağımsız çalışır — frontend hiçbir zaman kur güncelleme endpoint'i tetiklemez | `GET /api/exchange-rates` sayfa her açıldığında çağrılır (polling yok, BLoC'ta on-demand fetch) |
| `AssetType` enum değerini backend `string` olarak döner (Prisma enum → JSON) | Dart enum JSON deserializer: `AssetType.values.firstWhere((e) => e.name.toUpperCase() == json['assetType'])` |

---

## 9. Tamamlanma Kriterleri (Definition of Done)

### Backend

- [ ] `npx prisma migrate dev --name add_portfolio_models` koşmuş
- [ ] `ExchangeRate` tablosu cron ve manuel script ile doluyor (smoke test)
- [ ] 6 endpoint canlı, tümü `@UseGuards(JwtAuthGuard)`
- [ ] `portfolio.service.spec.ts` (buy/sell weighted avg hesabı, yetersiz miktar senaryosu)
- [ ] `exchange-rate.service.spec.ts` (XML parse, EVDS3 altın parse)
- [ ] `npm run lint && npm test && npm run build` yeşil

### Frontend

- [ ] Home portföy özet kartı render oluyor (boş durum dahil)
- [ ] `/portfolio` sayfası açılıyor: ticker + pie chart + asset card listesi
- [ ] Alım/satım form validasyonu + başarı/hata state'i
- [ ] Kâr/zarar renk kodlaması (yeşil/turuncu)
- [ ] `portfolio_bloc_test.dart` (fetch + buy + sell akışları)
- [ ] `flutter analyze && flutter test` lokal'de yeşil

### PR Gate

- [ ] CI 3/3 yeşil
- [ ] TASK.md Sprint 10 maddeleri `[x]` olarak işaretli

---

## 10. Açık Sorular (Çözüldü)

1. ✅ **Navigasyon:** Portfolio tab değil, Home dashboard kartından açılan `/portfolio` route.
2. ✅ **Altın API:** TCMB EVDS3 (Sprint 9 ile aynı key) — implementasyon öncesi curl smoke test zorunlu.
3. ✅ **Transaction Hub entegrasyonu:** Hayır — PortfolioTx bağımsız. `TransactionSource` enum değişmez.
4. ✅ **Kâr/zarar yöntemi:** Anlık değer farkı (güncel kur × miktar − maliyet). FIFO değil.
5. ✅ **Çeyrek/yarım/tam gram katsayıları:** 1.75 / 3.5 / 7.0 gram (smoke test sırasında TCMB ayrı seri varsa güncellenecek).
