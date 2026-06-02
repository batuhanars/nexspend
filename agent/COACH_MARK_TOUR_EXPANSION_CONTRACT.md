# Contract — Rehber (Coach Mark) Turunu Genişlet

> **REVİZYON (2 Haz 2026):** Cihaz testinden sonra karar değişti. 10 adımlık tur fazla uzun + tab'lar zaten kendini-açıklayan (etiketli ikonlar); asıl değer keşfedilmesi zor elemanlarda (özellikle Borçlar — bottom nav'da YOK). Tur **odaklı 5 adıma** indiriliyor: **[+] Hızlı Ekle → Raporlar & Enflasyon → Hesaplarım → Borçlar → Kaydırarak Sil**. Tab adımları (navHome/navTransactions/navBudgets/navSubscriptions) ve Ayarlar adımı KALDIRILIYOR. Aşağıdaki 10-adım spec'i tarihsel referans; uygulanan = bu revizyon. Detay: revizyonun sonundaki "REVİZYON DETAYI" bölümü.

---


> **Tür:** Frontend-only feature. Backend YOK.
> **Dev session:** Flutter (Sonnet), `cd mobile`.
> **Paket:** `tutorial_coach_mark: ^1.3.3` (mevcut). Yeni paket EKLEME.

## Amaç
Ana ekrandaki ilk-açılış rehber turunu detaylandır. Mevcut 3 adım (FAB → Ayarlar → Kaydırarak Sil) korunacak; aralarına yeni adımlar eklenip **10 adımlık** bütünlüklü bir tur olacak. Tüm metinler **lokalize** edilecek (TR + EN).

## Mevcut Durum (referans)
- Tur tanımı: `lib/presentation/shared/bottom_nav_bar.dart` → `_showCoachMark()` (satır ~261), tetikleme `_checkCoachMark()` (satır ~253, initState'ten, 900ms gecikme, `SecureStorage.isCoachMarkSeen()` ile gate).
- Key'ler: `lib/core/utils/coach_mark_keys.dart` — şu an sadece `fab`, `settings`.
- Coach içerik widget'ı: `_CoachContent` (bottom_nav_bar.dart ~706).
- Metinler **hardcoded Türkçe** ('Hızlı Ekle', 'Ayarlar', 'Atla', 'Tamam' vb.).
- Bottom nav yapısı (`_BottomNavBar`, ~549): soldan sağa **Ana Ekran(0), İşlemler(1), [+]FAB(orta), Bütçeler(3), Abonelikler(4)**. Borçlar nav'da DEĞİL.
- Dashboard app bar (`dashboard_page.dart` ~138): Raporlar IconButton (key YOK) + Ayarlar IconButton (`key: CoachMarkKeys.settings`).
- Dashboard gövde (`DashboardLoaded`): "Hesaplarım" başlığı (~179, her zaman var) → `EmptyAccountsCard`(boşsa ~206) / `AccountCarousel`(doluysa ~214) → `DebtShortcutCard`(~228). Yüklenirken `DashboardShimmer`.

---

## Yeni Tur — 10 Adım (sıra önemli)

| # | Hedef | Key | Başlık (TR / EN) | Gövde (TR / EN) |
|---|---|---|---|---|
| 1 | Ana Ekran tab | `navHome` | Ana Ekran / Home | Bakiyenin, hesaplarının ve son işlemlerinin özeti burada. / An overview of your balance, accounts, and recent activity. |
| 2 | İşlemler tab | `navTransactions` | İşlemler / Transactions | Tüm gelir, gider ve transferlerini görüntüle ve filtrele. / View and filter all your income, expenses, and transfers. |
| 3 | [+] FAB *(mevcut)* | `fab` | Hızlı Ekle / Quick Add | Gelir, gider, transfer ekle veya fiş tara. / Add income, expenses, transfers, or scan a receipt. |
| 4 | Bütçeler tab | `navBudgets` | Bütçeler / Budgets | Kategori bütçeleri oluştur, harcamanı limitlerle takip et. / Create category budgets and track spending against limits. |
| 5 | Abonelikler tab | `navSubscriptions` | Abonelikler / Subscriptions | Düzenli ödemelerini takip et, yaklaşan yenilemeleri gör. / Track recurring payments and see upcoming renewals. |
| 6 | Raporlar ikonu | `reports` | Raporlar & Enflasyon / Reports & Inflation | Harcama raporlarını gör, harcamanı TÜFE enflasyonuyla karşılaştır. / View spending reports and compare your spending with CPI inflation. |
| 7 | Ayarlar ikonu *(mevcut)* | `settings` | Ayarlar / Settings | Profilini düzenle, Ortak Bütçe oluştur, dil/tema ve bildirimleri ayarla. / Edit your profile, create a Shared Budget, set language/theme and notifications. |
| 8 | Hesaplarım | `accounts` | Hesaplarım / My Accounts | Nakit, banka ve kredi kartı hesaplarını buradan yönet. / Manage your cash, bank, and credit card accounts here. |
| 9 | Borçlar | `debts` | Borçlar / Debts | Verdiğin ve aldığın borçları takip et, ödemeleri kaydet. / Track money you've lent and borrowed, and record payments. |
| 10 | Kaydırarak Sil *(mevcut)* | (spotlight yok, mevcut off-screen hedef) | Kaydırarak Sil / Swipe to Delete | Bir listede kartı sola kaydırarak silebilirsin. / Swipe any card left in a list to delete it. |

- Adım 10 sondaki "Tamam/Done" butonuyla biter (mevcut yapı korunur).
- Spotlight şekilleri: tab'lar ve app bar ikonları için uygun (`Circle` ikonlara, `RRect` tab/kart bölümlerine). Nav bar altta → içerik `ContentAlign.top`. App bar ikonları üstte → `ContentAlign.bottom`. Hesaplarım/Borçlar gövdede → konumuna göre top/bottom seç (ekranda taşma olmasın).

---

## Key'ler ve Wiring

### `lib/core/utils/coach_mark_keys.dart` — yeni key'ler ekle
`navHome`, `navTransactions`, `navBudgets`, `navSubscriptions`, `reports`, `accounts`, `debts` (mevcut `fab`, `settings` kalır).

### Bottom nav tab'ları — `bottom_nav_bar.dart`
`_TabItem` / `_buildTabItem` her tab'a opsiyonel bir `GlobalKey` taşımalı. `leftTabs`/`rightTabs` tanımında ilgili key'i ver (Home→navHome, Transactions→navTransactions, Budgets→navBudgets, Subscriptions→navSubscriptions) ve `_buildTabItem` bu key'i tab'ın kök widget'ına bağlasın.

### Dashboard — `dashboard_page.dart`
- Raporlar IconButton (~138): `key: CoachMarkKeys.reports` ekle.
- Hesaplarım bölümü: spotlight hem boş (`EmptyAccountsCard`) hem dolu (`AccountCarousel`) durumda çalışmalı. **Başlık + içeriği saran** bir `Column`/`Container`'a `key: CoachMarkKeys.accounts` koy (veya en stabil şekilde "Hesaplarım" başlık Row'una). Boş hesap durumunda da hedef mevcut olmalı.
- `DebtShortcutCard` (~228): `key: CoachMarkKeys.debts` ekle.

---

## Tetikleme / Zamanlama (KRİTİK)
`tutorial_coach_mark`, `keyTarget.currentContext == null` iken **patlar**. Hesaplar/borçlar hedefleri yalnızca `DashboardLoaded` durumunda mount olur; dashboard ilk açılışta `DashboardShimmer` gösterir. Bu yüzden:

- Turu, **dashboard içeriği render edildikten sonra** göster. `_checkCoachMark` içinde sabit 900ms yerine, hedeflerin hazır olmasını bekle: gösterimden önce kritik key'lerin (`accounts`, `debts`, `reports`) `currentContext`'inin non-null olduğunu doğrula; değilse kısa aralıklarla (ör. 200ms) birkaç saniye boyunca tekrar dene, makul timeout sonrası vazgeç (sessizce).
- Alternatif (tercih edilebilir): tetiklemeyi dashboard'ın ilk `DashboardLoaded`'ına bağla (o anda app bar ikonları + gövde + nav bar mount). Hangi yaklaşımı seçersen seç, **mount garantisi** sağla. Tüm key'ler global olduğundan tetikleme yeri erişimi etkilemez.

---

## Yeniden Gösterim — Versiyon Anahtarlı Bayrak
Şu an markette gerçek kullanıcı yok; ama coach 'seen' bayrağı dolu olan kapalı-test/geliştirme cihazının yeni turu görebilmesi için bayrağı **versiyonla**:
- `SecureStorage`'daki boolean `isCoachMarkSeen`/`saveCoachMarkSeen` yerine **int sürüm** sakla (ör. `getCoachMarkVersion()` / `saveCoachMarkVersion(int)`).
- Kod tarafında `kCoachMarkVersion = 2` sabiti tanımla (eski 3-adımlı tur = 1).
- Tur, **saklı sürüm < kCoachMarkVersion** iken gösterilir. `onFinish`/`onSkip`'te `kCoachMarkVersion` kaydedilir.
- Gerçek kullanıcı olmadığı için eski boolean'ı geriye-uyumlu tutmak zorunda değilsin; temizce int sürüme geçebilirsin.
- Ayarlara "rehberi tekrar göster" butonu bu işte KAPSAM DIŞI (eklenmeyecek).

---

## Lokalizasyon
Tüm coach metinleri (10 başlık + 10 gövde + "Atla"/"Skip" + "Tamam"/"Done") `AppStrings`'e taşınır — abstract + TR + EN üçü de. Mevcut hardcoded 3 adım da dahil. `_CoachContent`'e ve `_showCoachMark`'a `AppStrings.of(context)` ile geçilir. Yukarıdaki tablodaki TR/EN metinler öneridir; doğal düşür.

> Not: Tema uyumu — coach içeriği/skip/done renkleri `context.colors` üzerinden olsun (mevcut kodda `Colors.white`/`Colors.black` kullanımı var; coach overlay karanlık scrim üzerinde olduğundan beyaz metin kabul edilebilir, ama buton/metin renklerini mümkünse `context.colors` ile ver — overlay scrim `Colors.black` kalabilir).

---

## Kabul Kriterleri
1. İlk açılışta 10 adımlık tur sırasıyla akıyor: Ana Ekran → İşlemler → [+] → Bütçeler → Abonelikler → Raporlar → Ayarlar → Hesaplarım → Borçlar → Kaydırarak Sil.
2. Her tab, app bar ikonu ve gövde bölümü doğru spotlight'lanıyor; içerik ekran dışına taşmıyor.
3. Dashboard yüklenmeden tur açılmıyor; hedefler hazır olunca açılıyor (currentContext null hatası YOK). Hesap listesi boşken de "Hesaplarım" adımı çalışıyor.
4. Dil İngilizce iken tüm tur İngilizce; TR iken Türkçe.
5. Sürüm anahtarı sayesinde, daha önce eski turu görmüş (seen) cihaz yeni turu bir kez görüyor.
6. Atla / Tamam çalışıyor; tur bitince/atlanınca sürüm kaydediliyor ve tekrar açılmıyor.
7. `flutter analyze` temiz, `flutter test` yeşil.

## Notlar
- Yeni AppStrings anahtarlarını 3 yere de ekle (abstract + TR + EN), yoksa derleme patlar.
- Tetikleme tek seferlik kalmalı; aynı oturumda iki kez açılmamalı.
- Commit ETME — working tree'yi inceleme için bırak.

---

## REVİZYON DETAYI — Odaklı 5 Adım (uygulanan hal)

Mevcut 10-adımlık implementasyondan şu adımlara indir (sıra aynen):

| # | Hedef key | Başlık | Gövde |
|---|---|---|---|
| 1 | `fab` | Hızlı Ekle / Quick Add | (mevcut metin) |
| 2 | `reports` | Raporlar & Enflasyon / Reports & Inflation | (mevcut metin) |
| 3 | `accounts` | Hesaplarım / My Accounts | (mevcut metin) |
| 4 | `debts` | Borçlar / Debts | (mevcut metin) |
| 5 | (off-screen) | Kaydırarak Sil / Swipe to Delete | (mevcut metin) |

Yapılacaklar:
- `_showCoachMark`'tan **navHome, navTransactions, navBudgets, navSubscriptions ve settings** TargetFocus'larını çıkar; yalnızca yukarıdaki 5 adım kalsın, bu sırada.
- `coach_mark_keys.dart`'tan artık kullanılmayan `navHome/navTransactions/navBudgets/navSubscriptions` key'lerini sil. `bottom_nav_bar.dart`'taki `_TabItem.coachKey` alanı + `_buildTabItem` key bağlama ve `leftTabs/rightTabs`'taki `coachKey:` atamalarını geri al (tab'lar artık keylenmez). `settings` key'i dashboard'daki IconButton'da bu özellikten önce de vardı — bağlı kalabilir, dokunma.
- `app_strings.dart`'tan artık kullanılmayan coach metinlerini (nav tab başlık/gövdeleri + settings başlık/gövde) **3 yerden de** (abstract + TR + EN) sil. Kalan coach key'lerine dokunma.
- Zamanlama koruması `accounts/debts/reports` currentContext'ini yokluyor — bu 3'ü turda kaldığı için **aynen kalsın**, doğru çalışır.
- **`kCoachMarkVersion`'ı 3 yap** (turun içeriği değiştiği için; daha önce v2'yi görmüş kapalı-test/geliştirme cihazı yeni 5-adımlık turu bir kez görsün).
- `flutter analyze` temiz + `flutter test` yeşil olmalı. Commit ETME.
