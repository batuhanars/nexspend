# Contract — Hedefli i18n Boşlukları + İstatistik Başlık Rengi Bug'ı

> **Tür:** Frontend-only. Backend YOK.
> **Dev session:** Flutter (Sonnet), `cd mobile`.
> **Kapsam DAR ve NET:** Kullanıcının dil değiştirince Türkçe kalan olarak bildirdiği 3 ekran + 1 tema bug'ı. **Tüm uygulamayı tarama. Aşağıda listelenmeyen ekranlara dokunma.**

## Yapılmayacaklar (sınırlar)
- Legal sayfalara (Kullanım Şartları / Gizlilik Politikası) **dokunma** — Türkçe kalacak (ürün kararı).
- Bloc hata/başarı mesajlarını (`*_bloc.dart` içindeki Türkçe string'ler) bu iş kapsamında **lokalize etme** — ayrı iş.
- Kullanıcı verisini (üye adı, kategori adı, abonelik adı vb.) çevirme — onlar veri.
- Banka adları, `.replaceAll('İ','I')` normalizasyonu, kod yorumları → dokunma.

---

## AppStrings yapısı (her yeni anahtar 3 yere eklenir)
`lib/core/l10n/app_strings.dart` içinde:
1. Abstract sınıfta getter tanımı (`String get xxx;`)
2. Türkçe implementasyon (`String get xxx => 'Türkçe';`)
3. İngilizce implementasyon (`String get xxx => 'English';`)

**Her yeni anahtarı ÜÇ yere de ekle.** Önce dosyayı açıp mevcut deseni (sınıf adları, sıralama) gör, ona uy. UI'da `AppStrings.of(context).xxx` ile kullan.

---

## İŞ A — Ortak Bütçe Katkı İstatistik Ekranı
**Dosya:** `lib/presentation/family/pages/contribution_report_page.dart`

Hardcoded → AppStrings'e taşı:
| Satır | Metin | Not |
|---|---|---|
| 54 | `'Katkı Raporu'` | AppBar başlığı |
| 60 | `'Dönem Seç'` | IconButton tooltip |
| 79 | `'DÖNEM'` | label |
| 90 | `'Bu dönem için katkı verisi yok.'` | boş durum |
| 121 | `'Tekrar Dene'` | hata retry butonu |
| 167 | `'Dönem Seç'` | bottom sheet başlığı |

> EN karşılıkları (öneri): Contribution Report / Select Period / PERIOD / No contribution data for this period. / Try Again / Select Period.

**Ayrıca:** `lib/presentation/family/pages/family_group_detail_page.dart:192` → `tooltip: 'Katkı Raporu'` da aynı anahtarla lokalize edilsin (bu ekrana giriş butonu).

> `contribution_bar.dart` temiz (sadece kullanıcı verisi + % formatı) — dokunma.

### Başlık rengi bug'ı (aynı dosya — KRİTİK)
**Sorun:** Satır 54-55:
```dart
title: const Text('Katkı Raporu'),
titleTextStyle: AppTypography.headlineSm,   // <-- renk YOK
```
`AppTypography.headlineSm`'de renk yok; AppBar `titleTextStyle`'ı AppBar SEVİYESİNDE override edildiği için Flutter `foregroundColor`'ı bu stile merge etmiyor → light modda başlık beyaz/görünmez.

**Düzeltme:** titleTextStyle'a explicit renk ver:
```dart
title: Text(AppStrings.of(context).contributionReport),
titleTextStyle: AppTypography.headlineSm.copyWith(color: colors.onSurface),
```
(`colors` zaten `context.colors` olarak satır 47'de mevcut.)

**Regresyon kontrolü:** Tüm `lib/presentation/` içinde `titleTextStyle: AppTypography` desenini grep'le. Bir AppBar `titleTextStyle`'ı renksiz bir `AppTypography.*` ile override ediyorsa aynı bug'a sahiptir → ona da `.copyWith(color: colors.onSurface)` ekle. (Stili doğrudan `Text(..., style: AppTypography.*)` olarak verenler güvenli, onlara dokunma.)

---

## İŞ B — Raporlar Ekranı
**Dosya:** `lib/presentation/reports/pages/reports_page.dart`

**Dosyanın tamamını oku** ve ekranda görünen TÜM hardcoded metni lokalize et. DİKKAT: `'Genel'`, `'Enflasyon'`, `'Harcama vs Enflasyon'` gibi metinlerde Türkçe-özel karakter YOK — grep ile değil, gözle tara.

Bilinen yerler (en az bunlar):
| Satır | Metin |
|---|---|
| 73 | `Tab(text: 'Genel')` |
| 74 | `Tab(text: 'Enflasyon')` |
| 244 | `'Enflasyon verisi henüz hazir degil'` (ayrıca yazım hatalı; EN: "Inflation data is not ready yet") |
| 250 | `SectionTitle(title: 'Harcama vs Enflasyon')` |

Genel sekmesinde (`_GeneralReportTab`) ve enflasyon sekmesinde başka görünür hardcoded başlık/etiket varsa onları da taşı. EN: Genel→General, Enflasyon→Inflation, Harcama vs Enflasyon→Spending vs Inflation.

---

## İŞ C — Aboneliği Düzenle Bottom Sheet
**Dosya:** `lib/presentation/subscriptions/pages/subscription_detail_page.dart`

`showModalBottomSheet` (satır ~75 başlıyor) içindeki görünür metinleri lokalize et:
| Satır | Metin |
|---|---|
| 105 | `'Aboneliği Düzenle'` (bottom sheet başlığı) |
| 131 | `'Abonelik adı'` (TextField hintText) |

Bottom sheet builder'ının tamamını oku; içindeki kaydet butonu etiketi vb. başka hardcoded Türkçe varsa onları da taşı. EN: Edit Subscription / Subscription name.

---

## İŞ D — Enflasyon Widget'ları (raporlar enflasyon sekmesi + öneri kartı)
Enflasyon sekmesinde görünen ama ayrı widget dosyalarında olduğu için ilk turda kaçan Türkçe metinler. **DİKKAT:** Bunların çoğunda Türkçe-özel karakter yok ('Mevcut', 'Önerilen', 'Genel TÜFE' vb.) — gözle tara, dosyaların tamamını oku.

### D1. `lib/presentation/inflation/widgets/inflation_comparison_table.dart`
| Satır | Metin | EN önerisi |
|---|---|---|
| 41 | `'Altında'` (_SummaryChip) | Below |
| 43 | `'Dengede'` | On Track |
| 45 | `'Üstünde'` | Above |
| 102 | `'KATEGORİ'` (kolon başlığı) | CATEGORY |
| 107 | `'SENİN %'` | YOURS % |
| 113 | `'TÜFE %'` | CPI % |
| 135-137 | switch: `'Altında'`/`'Üstünde'`/`'Dengede'` | Below/Above/On Track (D1 ile aynı anahtarları kullan) |

### D2. `lib/presentation/inflation/widgets/inflation_trend_chart.dart`
| Satır | Metin | EN önerisi |
|---|---|---|
| 34 | `'Trend verisi henüz hazır değil'` | Trend data is not ready yet |
| 83 | `'Genel TÜFE'` (legend) | General CPI |
| 86 | `'Gıda'` (legend) | Food |
| 15-16 | ay kısaltmaları `'Oca','Şub',...` | Locale-aware yap — İngilizce'de Jan/Feb/... Mevcut bir tarih util'i (intl `DateFormat.MMM`/`DateFormatter`) ile lokale göre üret; mümkün değilse AppStrings'e 12 anahtar. Kod tabanındaki mevcut desene uy. |

### D3. `lib/presentation/inflation/widgets/inflation_suggestion_card.dart`
> Not: Bu kart raporlar sekmesinde DEĞİL, bütçeler ekranında görünür; ama aynı bug. Dahil ediyoruz.

| Satır | Metin | EN önerisi |
|---|---|---|
| 46 | `'ENFLASYON ÖNERİSİ'` | INFLATION SUGGESTION |
| 62 | `'Son N ayda %X kümülatif enflasyon'` (interpolasyon) | parametreli metot: `%X cumulative inflation in last N months` |
| 69 | `'Mevcut'` | Current |
| 78 | `'Önerilen'` | Suggested |
| 122 | `'Bütçeyi Güncelle X'ye'` (interpolasyon + Türkçe ek) | parametreli metot; İngilizce'de "Update Budget to X" — Türkçe `'ye` ekini taşıma, cümleyi yeniden kur |

> İnterpolasyonlu metinler için AppStrings'te parametreli metot kullan (mevcut desen: `String helloName(String name) => 'Merhaba, $name';`). TR + EN + abstract üçüne de ekle.

---

## Kabul Kriterleri
1. Uygulama dili İngilizce yapıldığında: katkı istatistik ekranı, raporlar tab'ları + boş durumları, **enflasyon sekmesi (karşılaştırma tablosu kolon başlıkları + Altında/Dengede/Üstünde + legend + ay kısaltmaları)**, enflasyon öneri kartı, aboneliği düzenle bottom sheet **tamamen İngilizce**.
2. Light modda katkı istatistik ekranı başlığı **koyu/görünür** (artık beyaz değil); dark modda da doğru.
3. Aynı `titleTextStyle: AppTypography` (renksiz, AppBar seviyesi) bug'ı varsa diğer ekranlarda da düzeltildi.
4. Listelenmeyen ekranlara, legal sayfalara, bloc mesajlarına dokunulmadı.
5. `flutter analyze` temiz, `flutter test` yeşil.

## Notlar
- Yeni AppStrings anahtarlarını 3 implementasyona da ekle (abstract + TR + EN), yoksa derleme patlar.
- Commit ETME — working tree'yi inceleme için bırak.
