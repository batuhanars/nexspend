# THEME_SYSTEM_CONTRACT.md — Light/Dark/System Tema Sistemi

> **Durum:** Aktif · Çoklu oturum · Yol A (theme-aware refactor)
> **PM:** Opus · **Dev:** Sonnet frontend session(ları)
> **Hedef:** Ayarlar ekranında **Light / Dark / Sistem** seçici; "Sistem" telefon moduna uyar.

---

## 1. Neden Yol A (mimari karar)

Uygulama renkleri bugün **1576 yerde, 156 dosyada** statik `AppColors.X` sabitlerinden okunuyor (hepsi dark hex). `MaterialApp.themeMode` çevirmek tek başına işe yaramaz — sabit renkler dark kalır, arayüz kırılır.

**Karar:** Renk okuma katmanını tema-duyarlı hale getir. Renkler `ThemeExtension` (`AppPalette`) üzerinden, `context.colors.X` ile okunur. Light + dark iki `AppPalette` instance'ı iki `ThemeData`'ya gömülür; `themeMode` hangisini seçeceğini belirler. Bu, Flutter'ın idiomatik yolu — gelecekte yeni tema (high-contrast, white-label) eklemek bedava olur.

> Transferable kural: **renkleri en baştan Theme'den oku, static const renk sınıfından değil.** Detay: `knowledge/stack/flutter/theme-aware-colors-from-start.md`.

---

## 2. Token Modeli — `AppPalette extends ThemeExtension`

`mobile/lib/core/theme/app_palette.dart` (YENİ):

```dart
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color surface, surfaceDim, surfaceBright;
  final Color surfaceContainerLowest, surfaceContainerLow, surfaceContainer,
      surfaceContainerHigh, surfaceContainerHighest;
  final Color primary, onPrimary, primaryContainer, onPrimaryContainer,
      primaryFixed, inversePrimary;
  final Color secondary, onSecondary, secondaryContainer, onSecondaryContainer;
  final Color tertiary, onTertiary, tertiaryContainer, onTertiaryContainer;
  final Color error, onError, errorContainer, onErrorContainer;
  final Color onSurface, onSurfaceVariant;
  final Color outline, outlineVariant;
  final Color inverseSurface, inverseOnSurface;
  // Semantic aliases
  final Color income, expense, success, warning, danger;

  const AppPalette({ /* hepsi required */ });

  static const AppPalette dark = AppPalette( /* §4 dark sütunu */ );
  static const AppPalette light = AppPalette( /* §4 light sütunu */ );

  @override AppPalette copyWith({ /* tüm alanlar nullable */ }) => ...;
  @override AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => ...;
}

extension AppPaletteX on BuildContext {
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}
```

**Kural:** `income/expense/success/warning/danger` `ColorScheme`'de yok — bu yüzden `AppPalette` ile tüm token'lar **tek namespace**'te toplanır. Migration her yerde aynı: `AppColors.X` → `context.colors.X`.

---

## 3. Migration Stratejisi (çoklu oturum, kontrollü)

**Uyumluluk kalkanı:** `AppColors` (statik dark) migration boyunca **silinmez**, kalır. Her batch bir feature'ın dosyalarını `context.colors`'a geçirir. Yarıda kalsa bile uygulama derlenir/çalışır (henüz geçmemiş dosyalar light modda dark görünür — beklenen geçiş durumu).

**Switcher'ı en sona aç:** Light/Dark/Sistem seçici UI'si kurulur ama **tüm migration bitene kadar kullanıcıya açılmaz** (yarı-geçmiş arayüz utandırıcıdır). Sıralama:

| Oturum | İş | DoD |
|---|---|---|
| **S1 (Altyapı)** | `AppPalette` + `app_palette.dart`, `AppTheme.light`, `context.colors`, `ThemeNotifier`, `SecureStorage` tema, `app.dart` wiring, `AppTypography` renk-sökme, `main.dart` overlay theme-aware. **core/ + shared/ widget'ları** migrate. Switcher kapalı. | `flutter analyze` temiz, `flutter test` yeşil, dark görünüm bire bir korunur |
| **S2..Sn (Batch)** | Feature feature migrate (§6 batch listesi). Her batch sonu light modda görsel QA. | Her batch: analyze temiz + o feature light modda doğru |
| **Sson (Açılış)** | Settings'e Light/Dark/Sistem seçici eklenir, `AppColors` silinir, tam QA. | Üç mod da tüm ekranlarda doğru |

**Her batch kapısı:** `cd mobile && flutter analyze && flutter test` lokal yeşil olmadan batch kapanmaz (root CLAUDE.md zorunluluğu).

---

## 4. Light Palet (marka renklerinden türetilmiş M3)

Dark palet korunur; light, aynı marka tohumlarından M3 tonal mantığıyla türetildi (primary lavanta-indigo, secondary mint=gelir, tertiary şeftali=gider).

| Token | Dark (mevcut) | **Light (yeni)** | Kullanım |
|---|---|---|---|
| **surface** | `#131313` | `#FBF9F9` | Scaffold arka planı (saf beyaz değil) |
| surfaceDim | `#131313` | `#DBD9D9` | |
| surfaceBright | `#393939` | `#FBF9F9` | |
| surfaceContainerLowest | `#0E0E0E` | `#FFFFFF` | En üst yüzey (yalnızca burada saf beyaz) |
| surfaceContainerLow | `#1C1B1B` | `#F5F3F3` | |
| surfaceContainer | `#201F1F` | `#EFEDED` | |
| **surfaceContainerHigh** | `#2A2A2A` | `#E9E7E7` | **Card arka planı** |
| **surfaceContainerHighest** | `#353534` | `#E3E2E2` | **Input field arka planı** |
| **onSurface** | `#E5E2E1` | `#1B1B1B` | Ana metin (saf siyah değil) |
| onSurfaceVariant | `#C6C5D4` | `#45464E` | İkincil metin |
| **primary** | `#BAC3FF` | `#4858AB` | Aktif elementler, butonlar |
| onPrimary | `#15267B` | `#FFFFFF` | Primary üstü metin |
| primaryContainer | `#3C4C9F` | `#DEE0FF` | |
| onPrimaryContainer | `#BAC3FF` | `#001257` | |
| primaryFixed | `#DEE0FF` | `#DEE0FF` | **Fixed — iki modda da aynı** |
| inversePrimary | `#4858AB` | `#BAC3FF` | |
| **secondary** (gelir/mint) | `#70D8C8` | `#00796B` | **Gelir / başarı** |
| onSecondary | `#003731` | `#FFFFFF` | |
| secondaryContainer | `#32A192` | `#9FF2E2` | |
| onSecondaryContainer | `#E5E2E1` | `#00201C` | |
| **tertiary** (gider/şeftali) | `#FFB68F` | `#964900` | **Gider / uyarı** |
| onTertiary | `#542100` | `#FFFFFF` | |
| tertiaryContainer | `#8A3B00` | `#FFDBC8` | |
| onTertiaryContainer | `#E5E2E1` | `#331300` | |
| **error** | `#FFB4AB` | `#BA1A1A` | |
| onError | `#690005` | `#FFFFFF` | |
| errorContainer | `#93000A` | `#FFDAD6` | |
| onErrorContainer | `#E5E2E1` | `#410002` | |
| outline | `#8F8F9E` | `#767680` | |
| outlineVariant | `#454652` | `#C7C6D0` | |
| inverseSurface | `#E5E2E1` | `#303030` | |
| inverseOnSurface | `#313030` | `#F3F0EF` | |
| **income** | =secondary | `#00796B` | Gelir (alias) |
| **expense** | =tertiary | `#964900` | Gider (alias) |
| success | =secondary | `#00796B` | |
| warning | `#FFD54F` | `#8A6100` | Light'ta okunur koyu amber |
| danger | =error | `#BA1A1A` | |

> Bu hex'ler ilk turdur; S1 sonrası light modda gözle görülünce ince ayar yapılabilir (özellikle income/expense doygunluğu).

---

## 5. `AppTheme.light` + `AppTypography` + `main.dart`

**`AppTheme.light`:** `AppTheme.dark`'ın birebir kopyası, fakat:
- `brightness: Brightness.light`
- `colorScheme`: light değerlerden kurulur (§4)
- `scaffoldBackgroundColor: <light surface>`
- `extensions: [AppPalette.light]` (dark'a da `[AppPalette.dark]` eklenir)
- `appBarTheme.systemOverlayStyle`: status bar ikonları **light modda dark** olmalı (`statusBarIconBrightness: Brightness.dark`, `systemNavigationBarIconBrightness: Brightness.dark`).
- TextTheme: `onSurface` light değerinden kurulur (inline textTheme'de hardcoded dark onSurface'i light'ta light onSurface yap).

**`AppTypography` (ZORUNLU değişiklik):** Getter'lar şu an `color: AppColors.onSurface` gömüyor — statik olduğu için tema-duyarlı olamaz. **Renk gömmeyi bırak.** Renksiz `TextStyle` döndür; renk ambient `DefaultTextStyle`/`textTheme`'den (yani aktif temadan) gelsin. İkincil renk isteyen yerler `AppTypography.bodyMd.copyWith(color: context.colors.onSurfaceVariant)` kullanır. (Eskiden `bodySm`/`labelSm`/`labelMd` `onSurfaceVariant` gömüyordu — bu varyant renkler ilgili widget'larda copyWith ile korunur.)

**`main.dart`:** `SystemChrome.setSystemUIOverlayStyle(...)` şu an `Color(0xFF131313)` + light ikon hardcoded. Bu, açılışta tema bilinmeden çalışıyor. İlk frame için dark varsayılan kalabilir; asıl overlay kontrolü `appBarTheme.systemOverlayStyle` üzerinden temaya bağlı yapılır. Tema değişiminde overlay'in güncellenmesi `app.dart`'taki rebuild ile sağlanır.

---

## 6. `ThemeMode` Kalıcılığı + Notifier + Settings UI

Mevcut `LocaleNotifier`/`CurrencyNotifier` pattern'i **birebir** kopyalanır.

**`mobile/lib/core/utils/theme_notifier.dart` (YENİ):**
```dart
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier(ThemeMode mode) : super(mode);
  void setMode(ThemeMode mode) => value = mode;
}
```

**`SecureStorage` (ekle):**
```dart
static const _themeKey = 'theme_mode'; // 'light' | 'dark' | 'system'
Future<void> saveThemeMode(String mode) => _storage.write(key: _themeKey, value: mode);
Future<String> getThemeMode() async => (await _storage.read(key: _themeKey)) ?? 'dark';
// Geriye dönük uyum: kayıt yoksa 'dark' (mevcut davranış korunur).
```

**`main.dart` (kayıt):** `LocaleNotifier`/`CurrencyNotifier` gibi:
```dart
final themeMode = _parseThemeMode(await getIt<SecureStorage>().getThemeMode());
getIt.registerSingleton<ThemeNotifier>(ThemeNotifier(themeMode));
```

**`app.dart` (wiring):** `LocaleNotifier`/`CurrencyNotifier` listener pattern'ine `ThemeNotifier` eklenir; `MaterialApp.router`'a:
```dart
theme: AppTheme.light,
darkTheme: AppTheme.dark,
themeMode: getIt<ThemeNotifier>().value,
```
("Sistem" modunda Flutter platform brightness'a göre `theme`/`darkTheme` arasında otomatik seçer — `AppPalette` her iki `ThemeData`'ya gömülü olduğu için `context.colors` doğru paleti döndürür. Ekstra platform-brightness senkronizasyonu **gerekmez** — Yol A'nın temiz avantajı.)

**Settings UI (Sson'da açılır):** Mevcut dil seçici (`_showLanguagePicker`) birebir model. `SectionPreferences` altına `SettingsTile(icon: Icons.palette_outlined, label: s.theme, subtitle: <seçili mod>, onTap: _showThemePicker)`. Bottom sheet 3 seçenek: Light / Dark / Sistem. Seçimde:
```dart
getIt<ThemeNotifier>().setMode(mode);
getIt<SecureStorage>().saveThemeMode(modeString);
```
**`AppStrings` (tr/en):** `theme`, `themeLight`, `themeDark`, `themeSystem`, `selectTheme` anahtarları eklenir (l10n dosyalarına).

---

## 7. Migration Batch Listesi (feature bazlı)

Her batch = bir Sonnet alt-görevi. Sıra, paylaşılan bağımlılık önce gelecek şekilde:

1. **core + shared** (S1): `core/widgets/*`, `presentation/shared/**`, `app_typography.dart`, `app_theme.dart`. (Bunlar her yerde kullanılıyor — önce.)
2. **auth** (`presentation/auth/**`) — login/register/otp/reset
3. **dashboard + home** (`presentation/dashboard/**`, `presentation/home/**`)
4. **transactions** (`presentation/transactions/**`) — en büyük, ~23+18+... refs
5. **budgets** (`presentation/budgets/**`)
6. **accounts** (`presentation/accounts/**`) + statements
7. **debts** (`presentation/debts/**`)
8. **subscriptions** (`presentation/subscriptions/**`)
9. **family** (`presentation/family/**`)
10. **receipt_scanner** (`presentation/receipt_scanner/**`) — CustomPainter'lara dikkat (§8)
11. **reports + insights + inflation** (`presentation/reports/**`, `insights/**`, `inflation/**`)
12. **settings + legal + onboarding** (`presentation/settings/**`, `legal/**`, `onboarding/**`) — switcher buradadır
13. **data/models** içindeki renk refs (account/debt/subscription model dosyalarındaki ikon/renk eşlemeleri) — context yoksa §8 kuralı

---

## 8. Köşe Durumlar (BOZMA)

- **`const` constructor'lar:** `const Icon(color: AppColors.primary)` → `context.colors.primary` artık `const` değil. İlgili `const`'ı kaldır (widget ağacında yukarı dallanabilir). Mekanik ama dikkat: derleme hatası verir, gizli kalmaz.
- **CustomPainter / context'siz yerler** (`corner_painter.dart`, chart painter'ları): renk **constructor üzerinden** geçilir; painter'ı oluşturan widget `context.colors`'tan alıp verir. Painter içinde `AppColors`/`context` kullanılmaz.
- **`data/models/*` içindeki renkler:** Model dosyalarında BuildContext yoktur. Renk eşlemesi (ör. hesap tipi rengi) ya `IconMapper` gibi context alan bir helper'a taşınır, ya da model sadece "key" döndürür, renk widget tarafında `context.colors` ile çözülür. Modelde renk hardcode etme.
- **Statik tema tanımları** (`app_theme.dart`): Burada zaten `AppColors` yerine ilgili `AppPalette` instance'ının değerleri (light/dark) doğrudan kullanılır — `context` yok, instance var.
- **Semantic income/expense:** Gelir hep `context.colors.income` (mint→teal), gider hep `context.colors.expense` (şeftali→burnt orange). Hardcode renk yasak; raporlardaki grafik renkleri de buradan.

---

## 9. Definition of Done (tüm sistem)

- [ ] `AppColors` tamamen silindi; `grep -rn "AppColors" lib/` → 0 sonuç
- [ ] `context.colors` her yerde; `flutter analyze` temiz
- [ ] `flutter test` yeşil (mevcut testler + tema notifier varsa testi)
- [ ] Ayarlar'da Light / Dark / Sistem seçici çalışıyor, seçim `SecureStorage`'da kalıcı
- [ ] Uygulama yeniden açılınca seçili tema geliyor (default: dark — geriye dönük uyum)
- [ ] "Sistem" modunda telefon temasını takip ediyor (canlı değişim dahil)
- [ ] 3 mod × tüm ana ekranlar görsel QA (özellikle: status bar ikon kontrastı, card/input ayrımı, gelir/gider renkleri, grafik renkleri, snackbar/dialog)
- [ ] Dark görünüm S0'daki haliyle **bire bir** korundu (regresyon yok)

---

## 10. İlgili Dosyalar

| Dosya | Rol |
|---|---|
| `mobile/lib/core/theme/app_palette.dart` | YENİ — ThemeExtension, light+dark instance, context.colors |
| `mobile/lib/core/theme/app_theme.dart` | `AppTheme.light` eklenir, extensions kaydı, textTheme tema-duyarlı |
| `mobile/lib/core/constants/app_colors.dart` | Migration kalkanı; en sonda SİLİNİR |
| `mobile/lib/core/constants/app_typography.dart` | Renk gömme kaldırılır |
| `mobile/lib/core/utils/theme_notifier.dart` | YENİ |
| `mobile/lib/core/storage/secure_storage.dart` | `getThemeMode`/`saveThemeMode` |
| `mobile/lib/main.dart` | ThemeNotifier kaydı + overlay |
| `mobile/lib/app.dart` | MaterialApp theme/darkTheme/themeMode + listener |
| `mobile/lib/presentation/settings/pages/settings_page.dart` | Tema seçici (Sson) |
| `mobile/lib/core/l10n/*` | tema string'leri (tr/en) |
| `mobile/lib/presentation/**` | 156 dosya — batch batch `context.colors` |
