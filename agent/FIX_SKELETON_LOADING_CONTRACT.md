# Contract — Skeleton Loading'i Güncel Layout'a Hizala

> **Tür:** Frontend-only, görsel/yapısal. Backend YOK, logic YOK, sadece shimmer placeholder widget'ları.
> **Sorun:** Skeleton'lar uygulamanın ESKİ (ilk versiyon) düzenini taklit ediyor. Veri gelince ekran tamamen farklı bir yapıya "sıçrıyor" → kötü algılanan yükleme deneyimi.
> **Dev session:** Flutter (Sonnet), `cd mobile`.

---

## Genel Kural (her ekran için aynı)

Her shimmer widget'ı, karşılık geldiği **gerçek (loaded) sayfanın bölüm sırasını ve kabaca blok ölçülerini** aynalamalı. Skeleton ile gerçek layout arasındaki geçiş "zıplamamalı".

- **Tek doğruluk kaynağı = gerçek sayfa kodu.** Her skeleton'u güncellemeden önce ilgili gerçek sayfayı oku, mevcut bölüm sırasını/yükseklikleri ondan çıkar. Bu dosyadaki açıklamalar yol gösterici; sapma varsa **gerçek koda uy**.
- Mevcut primitive'leri kullan: `lib/core/widgets/shimmer_box.dart` (`ShimmerBox`, `ShimmerCardRow`) ve `lib/presentation/shared/widgets/shimmer_box.dart`. Yeni shimmer altyapısı kurma; `shimmer: ^3.0.0` paketi zaten var.
- Tasarım sistemine uy: `AppSpacing` (page padding 20, xs/sm/md/lg/xl...), `radiusLg=16` kart, `radiusMd=12`, `context.colors`. **1px border yok**, tonal surface kullan. Renkler statik `AppColors` değil `context.colors` üzerinden (tema sistemi aktif).
- Skeleton **scroll edilebilir** içerik için ekranın gerçek scroll yapısıyla aynı padding'i kullanmalı.
- Birebir piksel kopya şart değil; **bölüm sırası + kabaca yükseklik + sayı** tutsun yeter (ör. gerçek ekranda önce balance kartı, sonra yatay hesap carousel'i, sonra borç kısayolu, sonra son işlemler → skeleton da bu sırada).

---

## Öncelik 1 — KÖTÜ uyum (mutlaka düzelt)

### Dashboard
- **Skeleton:** `lib/presentation/dashboard/widgets/dashboard_shimmer.dart`
- **Gerçek:** `lib/presentation/dashboard/pages/dashboard_page.dart` (~153-246)
- **Mevcut gerçek bölüm sırası (koddan teyit et):** BalanceCard (gradient, ~yükseklik) → "Hesaplarım" başlığı (+ opsiyonel ekle butonu) → AccountCarousel (yatay, ~150px) → DebtShortcutCard (tek kart) → InsightsCarousel (yatay kartlar) → RecentTransactionsSection (tarih başlıklı gruplu işlem satırları).
- **Kaldır:** Var olmayan "4 yuvarlak aksiyon ikonu" bloğu. Bu eski düzenden kalma, mevcut dashboard'da yok.
- Skeleton bu yeni sırayı yansıtsın: bir balance kart bloğu, kısa bölüm başlığı çubuğu, 2-3 yatay kart, tek geniş kart (borç kısayolu), 1 insight kartı genişliği, sonra ~4-5 `ShimmerCardRow` (son işlemler).

### Hesap Detayı
- **Skeleton:** `lib/presentation/accounts/widgets/account_detail_shimmer.dart`
- **Gerçek:** `lib/presentation/accounts/pages/account_detail_page.dart` (~373-438)
- **Mevcut gerçek bölüm sırası:** AccountHeaderCard → (kredi kartıysa) CreditCardStatementsSection → ThisMonthSection (gelir/gider) → (veri varsa) MonthlyChartSection → (veri varsa) TopCategoriesSection → AccountTransactionsSection (işlem listesi).
- Skeleton'a ekle: header kartı, bu-ay özet kutuları, grafik placeholder (zaten var), **kategori dağılımı için birkaç satır/çubuk**, ve **işlem listesi için ~3-4 `ShimmerCardRow`** (şu an hiç yok). Kredi kartı ekstresi bölümü opsiyonel — eklemek zorsa atla, ama transactions listesi mutlaka olsun (her hesapta var).

### Insights Carousel
- **Skeleton:** `lib/presentation/home/widgets/insights_carousel.dart` (`_CarouselShimmer`, ~162-179)
- **Gerçek:** aynı dosya (~1-160) — yatay scroll'da birden çok insight kartı (başlık + açıklama + aksiyon).
- **Düzelt:** Tek statik kutu yerine **yatay sırada 2-3 kart genişliği** göster, gerçek kart yüksekliğine yakın. Gerçek `InsightsCarousel`'in kart boyutunu koddan al.

---

## Öncelik 2 — ORTA uyum

### Bütçeler
- **Skeleton:** `lib/presentation/budgets/widgets/budgets_shimmer.dart`
- **Gerçek:** `lib/presentation/budgets/pages/budgets_page.dart` (~177-278)
- **Mevcut sıra:** OverviewCard → _FamilyGroupsSection (aile grupları veya prompt kartı) → _InflationSuggestionsSection (opsiyonel) → BudgetCard listesi (progress bar'lı).
- Skeleton'a **aile grupları bölümü için bir satır/kart** ve overview'dan sonra bölüm başlığı ekle. BudgetCard skeleton'larında progress bar çubuğunu yansıt.

### Abonelikler
- **Skeleton:** `lib/presentation/subscriptions/widgets/subscriptions_shimmer.dart`
- **Gerçek:** `lib/presentation/subscriptions/pages/subscriptions_page.dart` (~70-88)
- **Mevcut sıra:** SummaryCard → UpcomingBanner (yaklaşan yenilemeler) → SubscriptionList.
- Skeleton'a **UpcomingBanner için bir bant/kart bloğu** ekle (summary ile liste arasına).

---

## Öncelik 3 — İYİ (sadece küçük hizalama, gerekirse)

### İşlemler & Borçlar
- `transactions_shimmer.dart` ve `debts_shimmer.dart` yapısal olarak güncel. Sadece gerçek sayfayla karşılaştırıp özet kartı sırası / filtre chip sayısı bariz sapmışsa hizala. Aşırıya kaçma.

---

## Kabul Kriterleri

1. Dashboard, Hesap Detayı ve Insights skeleton'ları artık gerçek loaded layout'un bölüm sırasını/yapısını yansıtıyor; veri gelince belirgin "zıplama" yok.
2. Dashboard skeleton'undan eski "4 yuvarlak aksiyon" bloğu kaldırıldı.
3. Hesap Detayı skeleton'unda işlem listesi (ve mümkünse kategori) bölümü var.
4. Insights skeleton'u tek kutu değil, yatay çoklu kart.
5. Bütçe ve Abonelik skeleton'ları eksik bölümleri (aile grupları / upcoming banner) yansıtıyor.
6. Tema sistemine uyum: renkler `context.colors` üzerinden, light/dark ikisinde de doğru.
7. `flutter analyze` temiz, `flutter test` yeşil.

## Notlar
- Logic/state değişmez — sadece loading state'te gösterilen placeholder widget içerikleri.
- Mevcut shimmer primitive'lerini yeniden kullan; kod tekrarını artırma.
- Commit ETME, working tree'yi inceleme için bırak.
