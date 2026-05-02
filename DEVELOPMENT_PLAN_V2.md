# Stitch Wallet App — Geliştirme Planı V2 (İleri Özellikler)

> **Proje:** Kişisel Finans Yönetim Uygulaması  
> **Teknoloji:** NestJS + MySQL (Backend) | Flutter (Frontend)  
> **Kapsam:** Sprint 9-12 — Enflasyon Bütçeleme, Portföy Takibi, Akıllı Öneriler, Aile Bütçe  
> **Ön Koşul:** V1 tamamlanmış olmalı (Sprint 0-8)
> 
> **İlişkili dosyalar:**
> - `SCHEMA.md` — Veritabanı şeması (V2 modelleri dahil: InflationRate, PortfolioAsset, Insight, FamilyGroup vb.)
> - `DEVELOPMENT_PLAN_V1.md` — Temel özellikler (Sprint 0-8)
> - `TASK.md` — Görev takibi
> - `STITCH_PROMPTS.md` — Tasarım promptları

---

### 8.6 ENFLASYON-DUYARLI BÜTÇELEME — Detaylı Kurgu

> **Rakiplerden ayrışma noktası #1:** Türkiye'de yüksek enflasyon ortamında "sabit bütçe" anlamsız.
> Bu modül bütçeyi canlı tutar — kullanıcı aynı hayatı yaşarken parasının neden yetmediğini anlar.

#### 8.6.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Veri Kaynağı | TÜİK EVDS API | Resmi enflasyon verileri (kategori bazlı TÜFE) |
| Güncelleme Sıklığı | Aylık | TÜİK verileri aylık yayınlanır |
| Enflasyon Eşleştirme | Kategori bazlı | Market → Gıda TÜFE, Ulaşım → Ulaştırma TÜFE, vb. |
| Kullanıcıya Gösterim | Karşılaştırmalı | "Senin artışın vs enflasyon" — kişisel performans |
| Bütçe Ayarlama | Öneri + onay | Sistem önerir, kullanıcı onaylarsa bütçe güncellenir |

#### 8.6.2 TÜİK Kategori Eşleştirmesi

```
Uygulama Kategorisi    →    TÜİK TÜFE Alt Grubu
─────────────────────────────────────────────────
Market                 →    Gıda ve alkolsüz içecekler
Ulaşım                →    Ulaştırma
Eğlence                →    Eğlence ve kültür
Sağlık                 →    Sağlık
Alışveriş              →    Giyim ve ayakkabı
Faturalar              →    Konut, su, elektrik, gaz
Konut/Kira             →    Konut (kira alt grubu)
Eğitim                 →    Eğitim
Yeme-İçme (Dışarıda)   →    Lokanta ve oteller
Genel                  →    Genel TÜFE (tüm kategoriler)
```

#### 8.6.3 Yeni Prisma Modelleri

```prisma
/// Aylık enflasyon verileri (TÜİK'ten çekilir)
model InflationRate {
  id           String   @id @default(uuid()) @db.VarChar(36)
  categoryKey  String   @map("category_key") @db.VarChar(50)   /// "gida", "ulasim", "genel"
  year         Int
  month        Int                                               /// 1-12
  monthlyRate  Decimal  @map("monthly_rate") @db.Decimal(6, 2)  /// aylık % değişim (örn: 3.45)
  yearlyRate   Decimal  @map("yearly_rate") @db.Decimal(6, 2)   /// yıllık % değişim (örn: 48.21)
  fetchedAt    DateTime @default(now()) @map("fetched_at") @db.Timestamp(0)

  @@unique([categoryKey, year, month])
  @@map("inflation_rates")
}

/// Kategori → TÜİK eşleştirme tablosu
model CategoryInflationMap {
  id           String @id @default(uuid()) @db.VarChar(36)
  categoryId   String @map("category_id") @db.VarChar(36)
  inflationKey String @map("inflation_key") @db.VarChar(50)    /// InflationRate.categoryKey ile eşleşir

  category Category @relation(fields: [categoryId], references: [id])

  @@unique([categoryId])
  @@map("category_inflation_maps")
}
```

> **Not:** `Category` modeline `inflationMap CategoryInflationMap?` ilişkisi eklenir.

#### 8.6.4 EVDS API Teknik Detayları

**API Bilgileri:**
- **Base URL:** `https://evds2.tcmb.gov.tr/service/evds/`
- **Auth:** API Key (query param `key=xxx`) — https://evds2.tcmb.gov.tr'dan ücretsiz alınır
- **Format:** JSON (`type=json`)
- **Rate Limit:** Yok (pratik olarak sınırsız)
- **Veri Yayın Takvimi:** Her ayın 3-5'inde önceki ayın verileri yayınlanır

**TÜFE Seri Kodları (EVDS):**

| categoryKey | EVDS Seri Kodu | TÜİK Alt Grubu |
|---|---|---|
| `genel` | `TP.FG.J0` | Genel TÜFE (tüm ürün ve hizmetler) |
| `gida` | `TP.FG.J01` | Gıda ve alkolsüz içecekler |
| `alkol_tutun` | `TP.FG.J02` | Alkollü içecekler ve tütün |
| `giyim` | `TP.FG.J03` | Giyim ve ayakkabı |
| `konut` | `TP.FG.J04` | Konut, su, elektrik, gaz |
| `mobilya` | `TP.FG.J05` | Ev eşyası |
| `saglik` | `TP.FG.J06` | Sağlık |
| `ulasim` | `TP.FG.J07` | Ulaştırma |
| `haberlesme` | `TP.FG.J08` | Haberleşme |
| `eglence` | `TP.FG.J09` | Eğlence ve kültür |
| `egitim` | `TP.FG.J10` | Eğitim |
| `lokanta` | `TP.FG.J11` | Lokanta ve oteller |
| `diger` | `TP.FG.J12` | Çeşitli mal ve hizmetler |

**Örnek API Çağrısı:**

```
GET https://evds2.tcmb.gov.tr/service/evds/series=TP.FG.J0-TP.FG.J01-TP.FG.J07&startDate=01-01-2026&endDate=30-04-2026&type=json&key=YOUR_API_KEY&frequency=5
```

**Örnek API Yanıtı:**

```json
{
  "totalCount": 4,
  "items": [
    {
      "Tarih": "01-2026",
      "TP_FG_J0": "2145.67",
      "TP_FG_J01": "2387.12",
      "TP_FG_J07": "1956.34"
    },
    {
      "Tarih": "02-2026",
      "TP_FG_J0": "2198.45",
      "TP_FG_J01": "2456.89",
      "TP_FG_J07": "2001.78"
    }
  ]
}
```

> **ÖNEMLİ:** EVDS değerleri **endeks** (index number) olarak döner, doğrudan yüzde değil.
> Yüzdelik değişimi kendimiz hesaplıyoruz.

**Endeksten Enflasyon Hesaplama Formülleri:**

```
Aylık Enflasyon (%) = ((buAyEndeks - geçenAyEndeks) / geçenAyEndeks) × 100
Yıllık Enflasyon (%) = ((buAyEndeks - 12AyÖnceEndeks) / 12AyÖnceEndeks) × 100
Kümülatif (3 aylık) = ((buAyEndeks - 3AyÖnceEndeks) / 3AyÖnceEndeks) × 100
```

**Örnek:**
- Ocak 2026 Gıda endeksi: 2387.12
- Şubat 2026 Gıda endeksi: 2456.89
- Aylık enflasyon: ((2456.89 - 2387.12) / 2387.12) × 100 = **+%2.92**

#### 8.6.5 NestJS Implementasyon

```typescript
// src/inflation/inflation.constants.ts

export const EVDS_BASE_URL = 'https://evds2.tcmb.gov.tr/service/evds/';

export const EVDS_SERIES_MAP: Record<string, string> = {
  genel: 'TP.FG.J0',
  gida: 'TP.FG.J01',
  giyim: 'TP.FG.J03',
  konut: 'TP.FG.J04',
  saglik: 'TP.FG.J06',
  ulasim: 'TP.FG.J07',
  eglence: 'TP.FG.J09',
  egitim: 'TP.FG.J10',
  lokanta: 'TP.FG.J11',
  diger: 'TP.FG.J12',
};
```

```typescript
// src/inflation/inflation-fetch.service.ts

@Injectable()
export class InflationFetchService {
  constructor(
    private readonly httpService: HttpService,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Her ayın 5'inde çalışır — önceki 13 ayın endeks verilerini çeker,
   * aylık ve yıllık değişimleri hesaplar, veritabanına kaydeder.
   */
  @Cron('0 10 5 * *') // Her ayın 5'i, saat 10:00
  async fetchMonthlyInflation(): Promise<void> {
    const apiKey = this.configService.get('EVDS_API_KEY');
    const seriesKeys = Object.values(EVDS_SERIES_MAP).join('-');

    // Son 13 ay çek (yıllık hesaplama için 12 ay öncesi lazım)
    const endDate = this.formatEvdsDate(new Date());
    const startDate = this.formatEvdsDate(subMonths(new Date(), 13));

    const url = `${EVDS_BASE_URL}series=${seriesKeys}&startDate=${startDate}&endDate=${endDate}&type=json&key=${apiKey}&frequency=5`;

    try {
      const { data } = await firstValueFrom(
        this.httpService.get(url).pipe(
          retry({ count: 3, delay: 5000 }), // 3 deneme, 5sn arayla
        ),
      );

      if (!data?.items?.length) {
        this.logger.warn('EVDS boş yanıt döndü — veri henüz yayınlanmamış olabilir');
        return;
      }

      // Her kategori için aylık + yıllık hesapla
      for (const [categoryKey, seriesCode] of Object.entries(EVDS_SERIES_MAP)) {
        const fieldName = seriesCode.replace(/\./g, '_'); // TP.FG.J01 → TP_FG_J01
        await this.processSeriesData(categoryKey, fieldName, data.items);
      }

      this.logger.log(`Enflasyon verileri güncellendi (${data.items.length} ay)`);
    } catch (error) {
      this.logger.error('EVDS API hatası', error.message);
      // Hata durumunda son başarılı veriyi koru — veritabanında mevcut kayıtlar kalır
    }
  }

  private async processSeriesData(
    categoryKey: string,
    fieldName: string,
    items: any[],
  ): Promise<void> {
    // Endeks değerlerini sırala (eskiden yeniye)
    const sorted = items
      .filter(item => item[fieldName] != null)
      .sort((a, b) => this.parseEvdsDate(a.Tarih) - this.parseEvdsDate(b.Tarih));

    for (let i = 1; i < sorted.length; i++) {
      const current = parseFloat(sorted[i][fieldName]);
      const previous = parseFloat(sorted[i - 1][fieldName]);
      const twelveMonthsAgo = i >= 12 ? parseFloat(sorted[i - 12][fieldName]) : null;

      const { year, month } = this.extractYearMonth(sorted[i].Tarih);
      const monthlyRate = ((current - previous) / previous) * 100;
      const yearlyRate = twelveMonthsAgo
        ? ((current - twelveMonthsAgo) / twelveMonthsAgo) * 100
        : null;

      await this.prisma.inflationRate.upsert({
        where: { categoryKey_year_month: { categoryKey, year, month } },
        update: { monthlyRate, yearlyRate, fetchedAt: new Date() },
        create: { categoryKey, year, month, monthlyRate, yearlyRate },
      });
    }
  }

  private formatEvdsDate(date: Date): string {
    // EVDS format: "DD-MM-YYYY"
    return format(date, 'dd-MM-yyyy');
  }

  private parseEvdsDate(tarih: string): number {
    // "01-2026" → timestamp for sorting
    const [month, year] = tarih.split('-').map(Number);
    return new Date(year, month - 1).getTime();
  }

  private extractYearMonth(tarih: string): { year: number; month: number } {
    const [month, year] = tarih.split('-').map(Number);
    return { year, month };
  }
}
```

**Hata Yönetimi ve Fallback:**

| Durum | Davranış |
|---|---|
| EVDS geçici çökmesi | 3 retry (5sn arayla), başarısız olursa log yaz, mevcut veriyi koru |
| Veri henüz yayınlanmamış | Boş yanıt → warn log, ayın 10'unda tekrar dene (ikinci cron) |
| API key geçersiz | 401 hatası → error log + admin bildirim |
| Endeks değeri null/NaN | O kategoriyi atla, diğerlerini işle |
| İlk çalıştırma (boş DB) | Manuel seed: son 12 ayın verisi bir kerelik çekilir |

**Environment Değişkenleri (.env):**

```env
EVDS_API_KEY=your_api_key_here
EVDS_BASE_URL=https://evds2.tcmb.gov.tr/service/evds/
INFLATION_CRON_ENABLED=true
```

#### 8.6.6 İş Akışları

**A) Enflasyon Verisi Güncelleme (Cron Job — Her ayın 5'i, 10:00)**

```
Cron Job: InflationFetchJob
  │
  ├─ EVDS API'den son 13 ayın TÜFE endeks verilerini çek
  │   (Tüm seriler tek istekte: TP.FG.J0-TP.FG.J01-...-TP.FG.J12)
  │
  ├─ Her seri için endeksten aylık + yıllık % değişim hesapla
  │     monthlyRate = ((current - previous) / previous) × 100
  │     yearlyRate = ((current - 12monthsAgo) / 12monthsAgo) × 100
  │
  ├─ InflationRate tablosuna upsert (categoryKey + year + month unique)
  │
  ├─ Başarısız olursa → 3 retry → hâlâ başarısızsa mevcut veriyi koru
  │
  └─ İkinci deneme: Her ayın 10'u (TÜİK gecikmeli yayınlarsa)
```

**B) Bütçe Ayarlama Önerisi**

```
Kullanıcı Bütçeler sayfasını açtığında:
  │
  ├─ Her aktif bütçe için:
  │     ├─ Bütçenin kategorisinin inflationKey'ini bul
  │     ├─ Son 3 ayın enflasyon oranlarını al
  │     ├─ Bütçe ne zaman oluşturuldu / son ne zaman güncellendi?
  │     │
  │     ├─ Hesapla: önerilen yeni bütçe =
  │     │     mevcutBütçe × (1 + kümülatifEnflasyon/100)
  │     │
  │     ├─ Fark anlamlı mı? (≥ %5 veya ≥ ₺100)
  │     │     Evet → öneri kartı göster
  │     │     Hayır → sessiz kal
  │     │
  │     └─ Öneri kartı:
  │           "📊 Market bütçeniz 3 aydır güncellenmedi.
  │            Bu sürede gıda enflasyonu %12,4 arttı.
  │            Önerilen yeni bütçe: ₺3.000 → ₺3.372
  │            [Güncelle] [Şimdilik Geçj]"
  │
  └─ Kullanıcı "Güncelle" derse → Budget.amount güncellenir
```

**C) Harcama vs Enflasyon Karşılaştırması (Raporlar)**

```
Raporlar sayfasında yeni bölüm: "Enflasyon Karşılaştırması"
  │
  ├─ Kategori bazlı tablo:
  │     | Kategori  | Geçen Ay | Bu Ay  | Senin Artışın | Enflasyon | Durum    |
  │     |-----------|----------|--------|---------------|-----------|----------|
  │     | Market    | ₺2.800   | ₺3.100 | +%10,7        | +%8,2     | 🔴 Üstü |
  │     | Ulaşım   | ₺650     | ₺680   | +%4,6         | +%6,1     | 🟢 Altı |
  │     | Eğlence  | ₺400     | ₺350   | -%12,5        | +%3,0     | 🟢 Altı |
  │
  ├─ Özet metni:
  │     "Bu ay 3 kategoride enflasyonun altında harcadın 👏
  │      Market harcaman enflasyonun %2,5 üstünde — 
  │      fark ₺70, yani enflasyon etkisi dışında ₺70 fazla harcadın."
  │
  └─ Aylık trend grafiği: senin harcaman vs enflasyon çizgisi (son 6 ay)
```

#### 8.6.7 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/inflation/current` | Güncel enflasyon oranları (tüm kategoriler) |
| `GET` | `/api/inflation/history` | Geçmiş enflasyon verileri (?months=6) |
| `GET` | `/api/budgets/:id/inflation-suggestion` | Bu bütçe için enflasyon ayarlama önerisi |
| `POST` | `/api/budgets/:id/apply-inflation` | Enflasyon önerisini uygula (bütçeyi güncelle) |
| `GET` | `/api/reports/inflation-comparison` | Harcama vs enflasyon karşılaştırma raporu |

#### 8.6.8 Flutter — Ekran ve Widget Yapısı

```
presentation/inflation/
├── widgets/
│     ├── inflation_suggestion_card.dart    # "Bütçeni güncelle" öneri kartı
│     ├── inflation_comparison_table.dart   # Kategori bazlı karşılaştırma tablo
│     └── inflation_trend_chart.dart        # Harcama vs enflasyon çizgi grafik

(BudgetsPage'e entegre — ayrı sayfa yok)
(ReportsPage'e yeni bölüm eklenir)
```

---

### 8.7 ALTIN / DÖVİZ PORTFÖY TAKİBİ — Detaylı Kurgu

> **Rakiplerden ayrışma noktası #2:** Türk kullanıcılar TL dışında varlık tutar.
> Gram altın, çeyrek altın, dolar, euro takibi — canlı kur ile net varlık hesabı.

#### 8.7.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Desteklenen Varlıklar | Döviz (USD, EUR, GBP) + Altın (gram, çeyrek, yarım, tam) | Türkiye'de en yaygın yatırım araçları |
| Kur Kaynağı | TCMB Döviz Kurları + Altın API | Resmi ve güvenilir |
| Güncelleme | Saatlik (kur) + anlık (sayfa açılınca) | Performans/maliyet dengesi |
| Çoklu Para Birimi | TL + USD bazlı net varlık | Kullanıcı her iki perspektifi görebilir |
| Alım/Satım Kaydı | Manuel giriş | Kullanıcı "₺X'e Y gram altın aldım" kaydeder |

#### 8.7.2 Yeni Prisma Modelleri

```prisma
enum AssetType {
  USD
  EUR
  GBP
  GOLD_GRAM        // gram altın
  GOLD_QUARTER      // çeyrek altın
  GOLD_HALF         // yarım altın
  GOLD_FULL         // tam altın
}

/// Yatırım hesabındaki varlık kalemleri
model PortfolioAsset {
  id            String    @id @default(uuid()) @db.VarChar(36)
  accountId     String    @map("account_id") @db.VarChar(36)       /// INVESTMENT tipindeki hesap
  assetType     AssetType @map("asset_type")
  quantity      Decimal   @db.Decimal(15, 4)                       /// 3.5 gram altın, 500 USD
  avgBuyPrice   Decimal   @map("avg_buy_price") @db.Decimal(15, 4) /// ortalama alış fiyatı (TL)
  totalCost     Decimal   @map("total_cost") @db.Decimal(15, 2)    /// toplam maliyet (TL)
  createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime  @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  account      Account           @relation(fields: [accountId], references: [id], onDelete: Cascade)
  transactions PortfolioTx[]

  @@unique([accountId, assetType])
  @@map("portfolio_assets")
}

/// Alım/satım işlem geçmişi
model PortfolioTx {
  id            String    @id @default(uuid()) @db.VarChar(36)
  assetId       String    @map("asset_id") @db.VarChar(36)
  type          String    @db.VarChar(4)                           /// "BUY" | "SELL"
  quantity      Decimal   @db.Decimal(15, 4)
  pricePerUnit  Decimal   @map("price_per_unit") @db.Decimal(15, 4) /// birim fiyat (TL)
  totalAmount   Decimal   @map("total_amount") @db.Decimal(15, 2)
  txDate        DateTime  @map("tx_date") @db.Timestamp(0)
  note          String?   @db.Text
  createdAt     DateTime  @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  asset PortfolioAsset @relation(fields: [assetId], references: [id], onDelete: Cascade)

  @@map("portfolio_transactions")
}

/// Kur/fiyat cache tablosu (saatlik güncelleme)
model ExchangeRate {
  id          String   @id @default(uuid()) @db.VarChar(36)
  assetType   AssetType @map("asset_type")
  buyPrice    Decimal  @map("buy_price") @db.Decimal(15, 4)    /// alış fiyatı (TL)
  sellPrice   Decimal  @map("sell_price") @db.Decimal(15, 4)   /// satış fiyatı (TL)
  fetchedAt   DateTime @default(now()) @map("fetched_at") @db.Timestamp(0)

  @@unique([assetType])
  @@map("exchange_rates")
}
```

> **Not:** `Account` modeline `portfolioAssets PortfolioAsset[]` ilişkisi eklenir.

#### 8.7.3 İş Akışları

**A) Kur Güncelleme (Cron Job — Her saat başı)**

```
Cron Job: ExchangeRateFetchJob (her 1 saatte bir, 08:00-22:00 arası)
  │
  ├─ TCMB Döviz Kurları API → USD, EUR, GBP alış/satış
  ├─ Altın API (bigpara/doviz.com/altinkaynak) → gram/çeyrek/yarım/tam altın
  │
  └─ ExchangeRate tablosunu güncelle (upsert)
```

**B) Varlık Alımı**

```
Kullanıcı Portföy ekranında "Alım Ekle":
  ├─ Varlık seçer: Gram Altın
  ├─ Miktar: 5 gram
  ├─ Birim fiyat: ₺3.200 (güncel kur ön doldurulur, düzenlenebilir)
  ├─ Toplam: ₺16.000
  │
  └─ Kaydet → Prisma $transaction:
        ├─ PortfolioTx oluştur (BUY, 5 gram, ₺3.200/gram)
        ├─ PortfolioAsset güncelle:
        │     quantity += 5
        │     avgBuyPrice yeniden hesapla (ağırlıklı ortalama)
        │     totalCost += 16.000
        └─ Account.balance güncelle (canlı değer × miktar)
```

**C) Dashboard Net Varlık (Çoklu Para Birimi)**

```
Dashboard BalanceCard — genişletilmiş:
  │
  ├─ TOPLAM VARLIK (TL):
  │     Nakit + Banka + Yatırım (canlı değer) = ₺145.600
  │
  ├─ TOPLAM VARLIK (USD karşılığı):
  │     ₺145.600 / güncelKur = $4.243
  │
  ├─ Portföy Özeti (mini):
  │     💰 5g Altın: ₺16.400 (+₺400, +%2,5)
  │     💵 $2.000: ₺68.600 (+₺1.200)
  │
  └─ Kâr/Zarar: toplam güncel değer - toplam maliyet
```

#### 8.7.4 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/exchange-rates` | Güncel tüm kurlar |
| `GET` | `/api/portfolio` | Kullanıcının tüm varlıkları (canlı değer dahil) |
| `GET` | `/api/portfolio/summary` | Toplam değer, kâr/zarar, TL + USD bazlı |
| `POST` | `/api/portfolio/buy` | Varlık alım kaydı |
| `POST` | `/api/portfolio/sell` | Varlık satım kaydı |
| `GET` | `/api/portfolio/history` | Alım/satım geçmişi |
| `GET` | `/api/portfolio/performance` | Varlık bazlı performans (son 1/3/6/12 ay) |

#### 8.7.5 Flutter — Ekran ve Widget Yapısı

```
presentation/portfolio/
├── bloc/
│     ├── portfolio_bloc.dart
│     └── exchange_rate_bloc.dart
├── pages/
│     ├── portfolio_page.dart            # Ana portföy ekranı
│     └── add_portfolio_tx_page.dart     # Alım/Satım ekleme
└── widgets/
      ├── asset_card.dart                # Varlık kartı (miktar, değer, kâr/zarar)
      ├── exchange_rate_ticker.dart      # Canlı kur bandı
      ├── portfolio_pie_chart.dart       # Varlık dağılım pasta grafiği
      └── profit_loss_indicator.dart     # Kâr/zarar göstergesi (+%2,5 yeşil)
```

---

### 8.8 AKILLI HARCAMA ANALİZİ (Insights) — Detaylı Kurgu

> **Rakiplerden ayrışma noktası #3:** Sadece "ne kadar harcadın" değil,
> "neden harcadın, nasıl azaltabilirsin" diyen bir akıllı asistan.

#### 8.8.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Analiz Tipi | Kural tabanlı (v1) | İlk sürümde ML yerine iş kuralları ile insight üret |
| Tetikleme | Otomatik + istek üzerine | Her ay sonu otomatik + kullanıcı istediğinde |
| Dil | Türkçe, samimi ton | "Spotify'ı 2 aydır açmamışsın 👀" gibi |
| Kapsam | Harcama pattern + abonelik + trend | 3 ana insight alanı |

#### 8.8.2 Insight Kuralları (v1 — Kural Tabanlı)

```typescript
// insights/insight-rules.ts

interface InsightRule {
  id: string;
  name: string;
  check: (data: UserFinancialData) => Insight | null;
}

const INSIGHT_RULES: InsightRule[] = [

  // 1. HARCAMA ARTIŞ TESPİTİ
  {
    id: 'spending_spike',
    name: 'Kategori harcama artışı',
    // Bir kategoride harcama son 3 aya göre %30+ arttıysa
    // → "Market harcaman bu ay %42 arttı. Geçen 3 ayın ortalaması ₺2.100,
    //    bu ay ₺2.982. Fark: +₺882"
  },

  // 2. ABONELİK KULLANIM ANALİZİ
  {
    id: 'unused_subscription',
    name: 'Kullanılmayan abonelik tespiti',
    // Abonelik var ama ilgili kategoride 60 gündür harcama yoksa
    // → "Spotify aboneliğin ₺59,99/ay ama Eğlence kategorisinde
    //    2 aydır başka harcama yok. İptal etmeyi düşünür müsün?
    //    Yıllık tasarruf: ₺719,88"
  },

  // 3. TEKRAR EDEN GEREKSIZ HARCAMA
  {
    id: 'recurring_small_expense',
    name: 'Küçük ama birikimli harcamalar',
    // Aynı merchant'ta ayda 10+ işlem, toplam anlamlı tutar
    // → "Bu ay Starbucks'a 14 kez gittin, toplam ₺1.260.
    //    Yıllık projeksyon: ₺15.120 — bu bir tatil parası! ☀️"
  },

  // 4. HAFTA SONU vs HAFTA İÇİ
  {
    id: 'weekend_spending',
    name: 'Hafta sonu harcama paterni',
    // Hafta sonu harcaması hafta içinin 2 katından fazlaysa
    // → "Hafta sonları haftanın %28'i ama harcamanın %55'i.
    //    Hafta sonu ortalaması: ₺420/gün vs hafta içi: ₺180/gün"
  },

  // 5. BÜTÇE TAHMİNİ
  {
    id: 'budget_forecast',
    name: 'Ay sonu bütçe projeksyonu',
    // Ayın 15'inde bütçenin %70'i harcandıysa
    // → "Market bütçen ₺3.000, henüz ayın 15'i ama ₺2.100 harcadın.
    //    Bu hızla ayı ₺4.200'de kapatırsın. Günlük ₺60 hedefi koy."
  },

  // 6. TASARRUF FIRSATI
  {
    id: 'saving_opportunity',
    name: 'Tasarruf potansiyeli',
    // Geçen aya göre harcama azaldıysa teşvik et
    // → "Tebrikler! 🎉 Ulaşım harcaman geçen aya göre ₺340 azaldı.
    //    Bu tempoda yılda ₺4.080 tasarruf edersin."
  },

  // 7. GELİR-GİDER DENGESİ
  {
    id: 'income_expense_ratio',
    name: 'Aylık gelir-gider oranı',
    // Gider > Gelirin %90'ı ise uyar
    // → "Bu ay gelirinin %94'ünü harcadın. Tasarruf oranın sadece %6.
    //    Sağlıklı hedef: en az %20 tasarruf."
  },
];
```

#### 8.8.3 Yeni Prisma Modeli

```prisma
/// Üretilen insight'lar (kullanıcıya gösterilmek üzere)
model Insight {
  id          String   @id @default(uuid()) @db.VarChar(36)
  userId      String   @map("user_id") @db.VarChar(36)
  ruleId      String   @map("rule_id") @db.VarChar(50)       /// "spending_spike", "unused_subscription"
  title       String   @db.VarChar(200)                       /// Insight başlığı
  message     String   @db.Text                                /// Detaylı mesaj
  category    String?  @db.VarChar(50)                         /// İlgili kategori (opsiyonel)
  severity    String   @db.VarChar(10)                         /// "info" | "warning" | "success"
  data        String?  @db.Text                                /// JSON — ek veri (grafikler için)
  isRead      Boolean  @default(false) @map("is_read")
  isDismissed Boolean  @default(false) @map("is_dismissed")
  period      String   @db.VarChar(7)                          /// "2026-04" (hangi ay için)
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, period, isDismissed], map: "idx_insights_user_period")
  @@map("insights")
}
```

> **Not:** `User` modeline `insights Insight[]` ilişkisi eklenir.

#### 8.8.4 İş Akışları

**A) Aylık Insight Üretimi (Cron Job — Her ayın 1'i, 08:00)**

```
Cron Job: MonthlyInsightJob
  │
  ├─ Her kullanıcı için:
  │     ├─ Son 3 ayın harcama verilerini çek
  │     ├─ Abonelik listesini çek
  │     ├─ Tüm INSIGHT_RULES'u sırasıyla çalıştır
  │     ├─ Her rule'dan dönen Insight'ı kaydet
  │     └─ Push notification: "Aylık finansal raporun hazır! 📊"
  │
  └─ Eski insight'ları temizle (6 aydan eski + dismissed)
```

**B) Kullanıcı Insight Akışı**

```
Dashboard'da "Akıllı Öneriler" bölümü:
  │
  ├─ Okunmamış insight sayısı badge (🔴 3)
  │
  ├─ Insight kartları (kaydırılabilir):
  │     ├── 🔴 "Market harcaman %42 arttı" [Detay] [Kapat]
  │     ├── 🟡 "Spotify'ı 2 aydır kullanmıyorsun" [İptal Et] [Kapat]
  │     └── 🟢 "Ulaşım'da ₺340 tasarruf ettin!" [Kapat]
  │
  └─ "Tüm Önerileri Gör" → InsightsPage (tam liste)
```

#### 8.8.5 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `GET` | `/api/insights` | Kullanıcının insight'ları (?period=2026-04&unread=true) |
| `GET` | `/api/insights/summary` | Okunmamış sayısı + son insight |
| `PATCH` | `/api/insights/:id/read` | Okundu olarak işaretle |
| `PATCH` | `/api/insights/:id/dismiss` | Kapat (bir daha gösterme) |
| `POST` | `/api/insights/generate` | Manuel tetikleme (istek üzerine analiz) |

#### 8.8.6 Flutter — Ekran ve Widget Yapısı

```
presentation/insights/
├── bloc/
│     └── insights_bloc.dart
├── pages/
│     └── insights_page.dart             # Tüm insight'lar listesi
└── widgets/
      ├── insight_card.dart              # Tek insight kartı (ikon, mesaj, aksiyon)
      ├── insight_badge.dart             # Okunmamış sayı badge
      └── insights_carousel.dart         # Dashboard'daki kaydırılabilir alan
```

---

### 8.9 AİLE / ORTAK BÜTÇE — Detaylı Kurgu

> **Rakiplerden ayrışma noktası #4:** Ev bütçesini birlikte yöneten çiftler/aileler için.
> v2 özelliği olarak planlandı — temel altyapısı Sprint 9'da kurulur.

#### 8.9.1 Temel Kararlar

| Karar | Seçim | Açıklama |
|-------|-------|----------|
| Davet Sistemi | E-posta ile davet | Kullanıcı partner'ını e-posta ile davet eder |
| Veri Paylaşımı | Sadece ortak bütçe | Kişisel hesaplar/işlemler gizli kalır |
| Üye Limiti | 2-5 kişi | Çift veya küçük aile |
| Katkı Takibi | Otomatik | Kim ne kadar harcadı/katkı verdi izlenir |
| Bildirimler | Ortak | Bütçe aşımında tüm üyeler bilgilendirilir |

#### 8.9.2 Yeni Prisma Modelleri

```prisma
enum FamilyRole {
  OWNER    // grubu oluşturan
  MEMBER   // davet edilen
}

enum InviteStatus {
  PENDING
  ACCEPTED
  REJECTED
  EXPIRED
}

/// Aile / ortak bütçe grubu
model FamilyGroup {
  id        String   @id @default(uuid()) @db.VarChar(36)
  name      String   @db.VarChar(100)                        /// "Ev Bütçesi", "Aile"
  icon      String?  @db.VarChar(50)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  members        FamilyMember[]
  sharedBudgets  SharedBudget[]
  invites        FamilyInvite[]

  @@map("family_groups")
}

/// Grup üyeleri
model FamilyMember {
  id        String     @id @default(uuid()) @db.VarChar(36)
  groupId   String     @map("group_id") @db.VarChar(36)
  userId    String     @map("user_id") @db.VarChar(36)
  role      FamilyRole @default(MEMBER)
  joinedAt  DateTime   @default(now()) @map("joined_at") @db.Timestamp(0)

  // İlişkiler
  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  user  User        @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([groupId, userId])
  @@map("family_members")
}

/// Davet sistemi
model FamilyInvite {
  id        String       @id @default(uuid()) @db.VarChar(36)
  groupId   String       @map("group_id") @db.VarChar(36)
  invitedBy String       @map("invited_by") @db.VarChar(36)   /// davet eden userId
  email     String       @db.VarChar(255)                      /// davet edilen e-posta
  token     String       @unique @db.VarChar(255)
  status    InviteStatus @default(PENDING)
  expiresAt DateTime     @map("expires_at") @db.Timestamp(0)
  createdAt DateTime     @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  group FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)

  @@map("family_invites")
}

/// Ortak bütçe
model SharedBudget {
  id            String       @id @default(uuid()) @db.VarChar(36)
  groupId       String       @map("group_id") @db.VarChar(36)
  categoryId    String       @map("category_id") @db.VarChar(36)
  name          String       @db.VarChar(100)                    /// "Ev Market Bütçesi"
  amount        Decimal      @db.Decimal(15, 2)
  spent         Decimal      @default(0.00) @db.Decimal(15, 2)
  period        BudgetPeriod @default(MONTHLY)
  startDate     DateTime     @map("start_date") @db.Date
  endDate       DateTime?    @map("end_date") @db.Date
  isActive      Boolean      @default(true) @map("is_active")
  createdAt     DateTime     @default(now()) @map("created_at") @db.Timestamp(0)
  updatedAt     DateTime     @updatedAt @map("updated_at") @db.Timestamp(0)

  // İlişkiler
  group    FamilyGroup @relation(fields: [groupId], references: [id], onDelete: Cascade)
  category Category    @relation(fields: [categoryId], references: [id])
  expenses SharedExpense[]

  @@map("shared_budgets")
}

/// Ortak bütçeye düşen harcamalar
model SharedExpense {
  id             String   @id @default(uuid()) @db.VarChar(36)
  sharedBudgetId String   @map("shared_budget_id") @db.VarChar(36)
  transactionId  String   @map("transaction_id") @db.VarChar(36)
  userId         String   @map("user_id") @db.VarChar(36)          /// harcamayı yapan üye
  amount         Decimal  @db.Decimal(15, 2)
  createdAt      DateTime @default(now()) @map("created_at") @db.Timestamp(0)

  // İlişkiler
  sharedBudget SharedBudget @relation(fields: [sharedBudgetId], references: [id], onDelete: Cascade)

  @@map("shared_expenses")
}
```

> **Not:** `User` modeline `familyMembers FamilyMember[]` ilişkisi eklenir.
> `Category` modeline `sharedBudgets SharedBudget[]` ilişkisi eklenir.

#### 8.9.3 İş Akışları

**A) Grup Oluşturma + Davet**

```
Kullanıcı Ayarlar → "Aile Bütçesi" → "Grup Oluştur":
  ├─ Grup adı: "Ev Bütçesi"
  ├─ Partner'ın e-postası: ayse@mail.com
  │
  └─ Kaydet:
        ├─ FamilyGroup oluştur
        ├─ FamilyMember oluştur (role: OWNER)
        ├─ FamilyInvite oluştur (token + 7 gün geçerli)
        └─ E-posta gönder: "Batuhan seni Ev Bütçesi grubuna davet etti"
              Davet linki → uygulama açılır → kabul/ret
```

**B) Ortak Bütçeye Harcama Ekleme**

```
Üye "İşlem Ekle" → kategori: Market → normal kaydeder
  │
  ├─ Transaction oluşturulur (kişisel — her zamanki akış)
  │
  ├─ Event: "transaction.created" →
  │     SharedBudgetListener kontrol eder:
  │     "Bu kullanıcının grubu var mı?
  │      Bu kategoride ortak bütçe var mı?"
  │
  ├─ Varsa → SharedExpense oluştur:
  │     sharedBudgetId, transactionId, userId, amount
  │
  ├─ SharedBudget.spent yeniden hesapla
  │
  └─ Tüm grup üyelerine bildirim:
        "Batuhan marketten ₺450 harcadı.
         Ev Market Bütçesi: ₺2.850/₺5.000 (%57)"
```

**C) Katkı Raporu**

```
Aile Bütçesi sayfasında "Katkı Dağılımı":
  │
  ├── Batuhan: ₺3.200 (%64)  ████████░░
  ├── Ayşe:    ₺1.800 (%36)  █████░░░░░
  │
  ├── Kategoriler:
  │     Market:    Batuhan ₺2.100 / Ayşe ₺900
  │     Faturalar: Batuhan ₺600 / Ayşe ₺500
  │     Ulaşım:   Batuhan ₺500 / Ayşe ₺400
  │
  └── "Bu ay Batuhan %28 daha fazla harcamış"
```

#### 8.9.4 API Endpoint'leri

| Method | Endpoint | Açıklama |
|--------|----------|----------|
| `POST` | `/api/family/groups` | Yeni grup oluştur |
| `GET` | `/api/family/groups` | Kullanıcının grupları |
| `GET` | `/api/family/groups/:id` | Grup detayı (üyeler + bütçeler) |
| `POST` | `/api/family/groups/:id/invite` | Üye davet et |
| `POST` | `/api/family/invites/:token/accept` | Daveti kabul et |
| `POST` | `/api/family/invites/:token/reject` | Daveti reddet |
| `POST` | `/api/family/groups/:id/budgets` | Ortak bütçe oluştur |
| `GET` | `/api/family/groups/:id/budgets` | Ortak bütçe listesi |
| `GET` | `/api/family/groups/:id/contributions` | Katkı dağılımı raporu |
| `DELETE` | `/api/family/groups/:id/members/:userId` | Üyeyi çıkar |

#### 8.9.5 Flutter — Ekran ve Widget Yapısı

```
presentation/family/
├── bloc/
│     ├── family_bloc.dart
│     └── shared_budget_bloc.dart
├── pages/
│     ├── family_group_page.dart         # Grup yönetimi
│     ├── shared_budgets_page.dart       # Ortak bütçeler
│     ├── invite_page.dart               # Üye davet
│     └── contribution_report_page.dart  # Katkı raporu
└── widgets/
      ├── member_avatar_row.dart         # Üye avatarları
      ├── contribution_bar.dart          # Katkı çubuğu (Batuhan %64)
      ├── shared_budget_card.dart        # Ortak bütçe kartı
      └── invite_status_badge.dart       # Davet durumu
```

---

### 8.10 Yeni Özellikler — Sprint Takvimi

| Sprint | Özellik | Bağımlılık | Tahmini Süre |
|--------|---------|------------|--------------|
| Sprint 9 | Enflasyon-Duyarlı Bütçeleme | Sprint 4 (Bütçeler) + Sprint 6 (Raporlar) | 4 gün |
| Sprint 10 | Altın/Döviz Portföy Takibi | Sprint 2 (Hesaplar) | 5 gün |
| Sprint 11 | Akıllı Harcama Analizi | Sprint 3 (İşlemler) + Sprint 5 (Abonelikler) | 4 gün |
| Sprint 12 | Aile/Ortak Bütçe (v2) | Sprint 4 (Bütçeler) + Sprint 1 (Auth) | 5 gün |

> **Toplam ek süre:** ~18 iş günü (~3.5 hafta)  
> **Yeni proje toplamı:** ~59 iş günü (~12 hafta)

---

## Genel Notlar

- V2 modülleri V1'deki temel yapıya bağımlıdır (Transaction Hub, Budget modülü, Auth sistemi)
- Yeni Prisma modelleri `SCHEMA.md`'de tanımlıdır — Sprint 9 başlamadan önce migration oluşturulmalı
- Tüm V2 endpoint'leri JWT auth gerektirir (`@UseGuards(JwtAuthGuard)`)
- Environment değişkenleri: `EVDS_API_KEY`, `TCMB_API_URL` (.env'ye eklenmeli)
