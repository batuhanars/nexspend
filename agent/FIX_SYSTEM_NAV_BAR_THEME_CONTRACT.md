# Contract — Sistem Navigasyon Çubuğu Temaya Uymuyor

> **Tür:** Frontend-only. Backend YOK.
> **Dev session:** Flutter (Sonnet), `cd mobile`.

## Sorun
Android sistem navigasyon çubuğu (alttaki tuş/jest barı) uygulamanın seçili temasına göre renklenmiyor, telefonun sistem temasına göre davranıyor. Kullanıcı: telefon teması **light**, uygulama teması **dark** iken 3-tuşlu navigasyonda bar **beyaz** kalıyor ve tuşlar görünmüyor. Jest navigasyonunda alan küçük olduğu için daha az belli ama aynı sorun.

## Kök Neden
1. `lib/core/theme/app_theme.dart` — **dark tema** AppBar `systemOverlayStyle`'ında `systemNavigationBarColor: Colors.transparent` (light temada `p.surface`). Transparent nav bar, OS'in sistem temasına göre beyaz bar çizmesine sebep oluyor; `systemNavigationBarIconBrightness: light` isteği transparent ile tutmuyor → beyaz bar + beyaz (görünmez) tuşlar.
2. `lib/main.dart` (satır ~28-35) — başlangıçta tek seferlik **sabit dark** `SystemUiOverlayStyle` set ediliyor; tema değişince hiç güncellenmiyor, light temada yanlış.
3. Sistem UI overlay stili hiçbir yerde uygulamanın **resolve edilmiş temasına** göre reaktif sürülmüyor.

## Hedef Davranış
Sistem nav bar + status bar, **telefonun değil uygulamanın** aktif temasını izlesin:
- Uygulama **dark** → nav bar `AppPalette.dark.surface` (#131313), nav ikon parlaklığı `Brightness.light`, status bar ikon `Brightness.light`.
- Uygulama **light** → nav bar `AppPalette.light.surface`, nav ikon parlaklığı `Brightness.dark`, status bar ikon `Brightness.dark`.
- `ThemeMode.system` seçiliyse telefon temasına göre resolve edilen tema baz alınır (Flutter zaten `Theme.of(context).brightness` ile çözüyor).
- Tema ayardan değiştirilince anında güncellenmeli.

## Yapılacaklar

### 1. Reaktif global overlay — `lib/app.dart`
`MaterialApp.router`'a `builder` ekle ve child'ı resolve edilmiş temaya göre `AnnotatedRegion<SystemUiOverlayStyle>` ile sarmala:
```dart
builder: (context, child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;
  final overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // iOS
    systemNavigationBarColor: palette.surface,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarDividerColor: palette.surface,
  );
  return AnnotatedRegion<SystemUiOverlayStyle>(
    value: overlay,
    child: child ?? const SizedBox.shrink(),
  );
},
```
- `AppPalette` import'u gerekir; `AppPalette.dark` / `AppPalette.light` const instance'lar ve `.surface` alanı mevcut.
- Bu, **AppBar'sız** ekranlarda (onboarding, auth vb.) nav bar'ı doğru yapar. `Theme.of(context).brightness` MaterialApp içinde resolve edilmiş temayı verir; `ThemeMode.system`'de telefon teması değişince MaterialApp rebuild olup overlay güncellenir.

### 2. AppBar overlay'lerini tutarlı yap — `lib/core/theme/app_theme.dart`
Scaffold + AppBar olan ekranlarda AppBar'ın `systemOverlayStyle`'ı üstteki AnnotatedRegion'ı ezer; bu yüzden iki temada da **doğru ve tutarlı** olmalı:
- **Dark tema** (satır ~76-81): `systemNavigationBarColor: Colors.transparent` → **`p.surface`** yap. `systemNavigationBarIconBrightness: Brightness.light` kalsın. `statusBarIconBrightness: Brightness.light` kalsın.
- **Light tema** (satır ~268-272): zaten `systemNavigationBarColor: p.surface`, `...IconBrightness: Brightness.dark` — doğru, dokunma (gerekirse `statusBarColor: Colors.transparent` tutarlılığını kontrol et).
- İki blokta da `statusBarColor: Colors.transparent` olsun.

### 3. `lib/main.dart` ilk-frame default'u
Satır ~28-35'teki sabit `SystemUiOverlayStyle`'ı kaldırma ZORUNLU değil (ilk frame için zararsız), ama reaktif stil hemen devralır. İstersen tema bilgisini henüz okumadan önce çağrıldığı için olduğu gibi bırak; sadece reaktif olanın (madde 1) onu anında ezdiğinden emin ol. (Tercih: bırak, sadeleştirme şart değil.)

## Kabul Kriterleri
1. Telefon light + uygulama dark → nav bar koyu (#131313), tuşlar/ikonlar açık ve **görünür**.
2. Telefon dark + uygulama light → nav bar açık, ikonlar koyu ve görünür.
3. `ThemeMode.system` seçiliyken telefon temasını değiştirince nav bar uygulamayla birlikte güncellenir.
4. Ayarlardan tema değiştirilince nav bar anında değişir (uygulama yeniden başlatmaya gerek yok).
5. Hem 3-tuşlu hem jest navigasyonunda doğru görünür. AppBar'lı ve AppBar'sız ekranlarda tutarlı.
6. `flutter analyze` temiz, `flutter test` yeşil.

## Notlar
- Fiziksel cihazda (Xiaomi/MIUI) test gerekiyor; emülatörde nav bar davranışı farklı olabilir. PM cihaz testini kullanıcıya bırakacak — sen mantığı standart Flutter pattern'iyle kur.
- Receipt scanner gibi tam-ekran kamera sayfası kendi koyu overlay'ini gerektirebilir; bu iş kapsamında DEĞİL, dokunma.
- Commit ETME — working tree'yi inceleme için bırak.
