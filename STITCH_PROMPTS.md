# Stitch Tasarım Promptları — Yeni Özellikler

> Bu promptları Stitch AI'da kullanarak yeni ekranların tasarımını oluştur.
> Her prompt, mevcut tasarım sistemine ("The Digital Private Vault") uygun olacak şekilde yazılmıştır.
> 
> **Mevcut tasarım kuralları (tüm promptlara uygulanır):**
> - Arka plan: #131313 (asla #000000 kullanma)
> - Primary: #BAC3FF, Secondary (gelir/yeşil): #70D8C8, Tertiary (gider/turuncu): #FFB68F
> - Metin: #E5E2E1 (asla #FFFFFF kullanma)
> - Font: Inter, 1px border yasak, tonal surface geçişleri ile ayır
> - Kartlar: #2A2A2A arka plan, 16px radius, gölge yok
> - Butonlar: pill shape (24px radius)

---

## PROMPT 1 — Enflasyon Bütçe Öneri Kartı (BudgetsPage İçin)

```
Design a mobile finance app card component for "Inflation Budget Suggestion" in Turkish language.

Context: This is a notification-style card that appears on the Budgets page when a user's budget hasn't been updated for a while and inflation has significantly changed prices.

Design specifications:
- Dark premium theme: background #131313, card background #2A2A2A, 16px radius, no borders
- Card contains:
  - Top: Small 📊 chart icon + "Enflasyon Uyarısı" label in #BAC3FF, uppercase, 11px, Inter 500
  - Title: "Market bütçeniz 3 aydır güncellenmedi" in #E5E2E1, 16px, Inter 600
  - Body text: "Bu sürede gıda enflasyonu %12,4 arttı." in #9A9A9A, 14px, Inter 400
  - Visual: A small horizontal bar showing old budget (₺3.000) → suggested budget (₺3.372) with an arrow, old value in #9A9A9A, new value in #70D8C8
  - Two buttons at bottom:
    - Primary: "Güncelle" — pill shape, #BAC3FF background, #1A1A2E text, 24px radius
    - Secondary: "Şimdilik Geç" — ghost style, #BAC3FF text, transparent background with #3A3A3A border at 20% opacity
- No 1px solid borders anywhere. Use tonal surface shifts only.
- Mobile width: 375px viewport

Style: Premium dark mode, editorial finance aesthetic. Clean, spacious, no gradients on the card itself.
```

---

## PROMPT 2 — Enflasyon Karşılaştırma Raporu (ReportsPage İçin)

```
Design a mobile finance app report screen section called "Enflasyon Karşılaştırması" (Inflation Comparison) in Turkish.

Context: This is a section within the Reports page that compares the user's spending increases against official inflation rates per category.

Design specifications:
- Dark premium theme: background #131313, section background #1A1A1A
- Section header: "Enflasyon Karşılaştırması" in #E5E2E1, 28px, Inter 600
- A line chart showing two lines over 6 months:
  - User's spending trend: #BAC3FF line
  - Inflation rate: #FFB68F dashed line
  - Chart background: #1A1A1A, grid lines in #2A2A2A (very subtle)
  - X-axis: months in Turkish (Kas, Ara, Oca, Şub, Mar, Nis)
  - Legend: two small circles + labels

- Below chart: Category comparison cards (vertical list, no divider lines, 16px spacing):
  Each card (#2A2A2A background, 16px radius):
  - Left: Category icon in circular container (10% opacity semantic color background)
  - Middle: Category name + "Senin artışın: +%10,7" + "Enflasyon: +%8,2"
  - Right: Status indicator — 🔴 "Üstünde" (red-ish #FFB4AB) or 🟢 "Altında" (green #70D8C8)

- Summary text at bottom in #9A9A9A, 14px:
  "Bu ay 3 kategoride enflasyonun altında harcadın 👏"

- No 1px borders. Typography hierarchy: large title → medium values → small labels.
- Mobile width: 375px viewport
```

---

## PROMPT 3 — Portföy Ana Ekranı

```
Design a mobile finance app screen called "Portföy" (Portfolio) for tracking gold and currency investments, in Turkish.

Context: Turkish users commonly invest in gold (gram/quarter/half/full) and foreign currency (USD, EUR). This screen shows their portfolio with live values.

Design specifications:
- Dark premium theme: background #131313
- Top section: Exchange rate ticker bar — horizontal scrollable chips showing live rates:
  "USD ₺34,28 ↑" "EUR ₺37,15 ↓" "Gram Altın ₺3.245 ↑"
  Each chip: #2A2A2A background, 12px radius, rate color: green #70D8C8 for up, #FFB4AB for down

- Hero card (gradient: #BAC3FF → #3C4C9F at 135°, 24px radius):
  - "Toplam Portföy Değeri" label, uppercase, 11px, Inter 500
  - "₺145.600" large display, 56px, Inter 700
  - Below: "Toplam Kâr/Zarar: +₺8.400 (+%6,1)" in #70D8C8, 14px
  - Second line: "≈ $4.243" in #9A9A9A (USD equivalent)

- Portfolio pie chart: small donut chart showing asset distribution
  Colors: Gold=#FFD54F, USD=#70D8C8, EUR=#BAC3FF

- Asset list (no divider lines, 16px spacing between items):
  Each asset card (#2A2A2A, 16px radius):
  - Left: Asset icon (gold bar icon for gold, $ icon for USD) in circular 40px container
  - Middle: "Gram Altın" title + "5 gram" subtitle in #9A9A9A
  - Right column: "₺16.225" current value + "+₺225 (+%1,4)" profit in #70D8C8

- FAB button bottom right: "+" for adding new buy/sell

- No 1px borders. Inter font throughout. Mobile width: 375px viewport.
```

---

## PROMPT 4 — Varlık Alım/Satım Ekleme Ekranı

```
Design a mobile finance app screen for adding a portfolio buy/sell transaction called "Alım Ekle" (Add Purchase), in Turkish.

Context: User is recording a gold or currency purchase with quantity and price.

Design specifications:
- Dark premium theme: background #131313
- Top: Back arrow + "Alım Ekle" title, 28px Inter 600
- Toggle segment control: "Alım" (Buy) / "Satım" (Sell) — active tab #BAC3FF background
- Asset type selector: Horizontal scrollable chips
  "Gram Altın" "Çeyrek Altın" "Yarım Altın" "Tam Altın" "USD" "EUR" "GBP"
  Active chip: #BAC3FF background, #1A1A2E text. Inactive: #2A2A2A, #E5E2E1 text

- Input fields (no border, #353535 background, 12px radius):
  - "Miktar" (Quantity): large number input, e.g. "5" with unit label "gram"
  - "Birim Fiyat" (Unit Price): "₺3.245,00" — pre-filled with current rate, editable
  - "Toplam Tutar" (Total): "₺16.225,00" — auto-calculated, displayed prominently in #BAC3FF, 28px

- Current rate info card (#2A2A2A):
  "Güncel Kur: ₺3.245 / gram" with a small live indicator dot (green pulsing)

- Optional note text area
- "Kaydet" button: full width, #BAC3FF background, pill shape, 24px radius

- No borders, no gradients on inputs. Clean spacing. Mobile width: 375px.
```

---

## PROMPT 5 — Akıllı Öneriler / Insights Ekranı

```
Design a mobile finance app screen called "Akıllı Öneriler" (Smart Insights) in Turkish.

Context: AI-powered spending analysis that gives personalized financial advice. Cards have different severity levels (info, warning, success).

Design specifications:
- Dark premium theme: background #131313
- Top: "Akıllı Öneriler" title, 28px, Inter 600 + badge showing unread count "3" in small #BAC3FF circle

- Filter chips: "Tümü" / "Uyarılar" / "Başarılar" / "Bilgiler" — horizontal

- Insight cards list (16px spacing, no dividers):

  Card 1 — Warning type (#2A2A2A background, 16px radius):
  - Left accent: 3px left border effect using #FFB68F at 30% opacity (tonal, not line)
  - Icon: ⚠️ in circular container with 10% #FFB68F background
  - Title: "Market harcaman %42 arttı" — 16px, Inter 600, #E5E2E1
  - Body: "Geçen 3 ayın ortalaması ₺2.100, bu ay ₺2.982. Fark: +₺882" — 14px, #9A9A9A
  - Action: "Detayları Gör" text button in #BAC3FF
  - Dismiss: Small X icon top-right, #9A9A9A

  Card 2 — Warning type:
  - Icon: 💳 subscription icon
  - Title: "Spotify'ı 2 aydır kullanmıyor olabilirsin"
  - Body: "Aylık ₺59,99, yıllık ₺719,88 tasarruf potansiyeli"
  - Action button: "İptal Etmeyi Düşün" in ghost style

  Card 3 — Success type (#2A2A2A background):
  - Left accent: tonal #70D8C8
  - Icon: 🎉 in circular container with 10% #70D8C8 background
  - Title: "Ulaşım'da ₺340 tasarruf ettin!"
  - Body: "Geçen aya göre %18 azalma. Bu tempoda yılda ₺4.080 biriktirirsin."

  Card 4 — Info type:
  - Left accent: tonal #BAC3FF
  - Icon: ☕ coffee cup
  - Title: "Starbucks'a bu ay 14 kez gittin"
  - Body: "Toplam ₺1.260 — yıllık projeksyon: ₺15.120"

- No 1px borders. Severity differentiated by icon background color tint only.
- Mobile width: 375px viewport.
```

---

## PROMPT 6 — Dashboard'a Eklenen Insight Carousel + Portföy Mini

```
Design an updated mobile finance app dashboard (home screen) called "Anasayfa" in Turkish that includes two new sections integrated with the existing layout.

Context: The existing dashboard already has: balance card, quick action buttons, account carousel, recent transactions. We're adding: (1) a smart insights carousel and (2) a mini portfolio summary.

Design specifications:
- Dark premium theme: background #131313

- EXISTING (keep as-is): 
  - Top greeting: "Merhaba, Batuhan 👋"
  - Balance card with gradient (#BAC3FF → #3C4C9F)
  - Quick action buttons row (Gelir/Gider/Transfer/Tara)

- NEW SECTION 1 — Mini Portfolio Summary (below balance card):
  - Small horizontal card (#2A2A2A, 16px radius):
    Left: "Portföy" label + total "₺145.600"
    Right: "+₺8.400 (+%6.1)" in #70D8C8
    Small asset icons: gold circle, $ circle, € circle
    Tappable → navigates to Portfolio page

- NEW SECTION 2 — Akıllı Öneriler Carousel (below accounts):
  - Section header: "Akıllı Öneriler" + unread badge "3" + "Tümünü Gör >" link in #BAC3FF
  - Horizontally scrollable mini insight cards (width: ~280px each):
    Card 1: ⚠️ "Market harcaman %42 arttı" — 2 lines max, #FFB68F tint
    Card 2: 🎉 "Ulaşım'da ₺340 tasarruf!" — #70D8C8 tint
    Card 3: 📊 "Enflasyon bütçe önerisi" — #BAC3FF tint

- EXISTING (keep as-is):
  - Recent transactions list

- No borders. Tonal surface layering only. Mobile width: 375px.
```

---

## PROMPT 7 — Aile Bütçesi Grup Ekranı

```
Design a mobile finance app screen called "Aile Bütçesi" (Family Budget) in Turkish.

Context: A shared budget feature where couples/families can track joint expenses. Shows group members, shared budgets, and who contributed how much.

Design specifications:
- Dark premium theme: background #131313

- Top section:
  - Group name: "Ev Bütçesi" — 28px, Inter 600
  - Member avatars row: 2 circular avatars (40px) with names below
    "Batuhan" (with a small 👑 crown for owner) + "Ayşe"
  - "Üye Davet Et" text button in #BAC3FF

- Shared budgets section:
  Header: "Ortak Bütçeler" — 20px, Inter 600

  Budget card 1 (#2A2A2A, 16px radius):
  - "Ev Market Bütçesi" title
  - Progress bar: ₺3.200/₺5.000 (%64) — gradient bar #BAC3FF → #3C4C9F
  - Below progress: two small contribution indicators
    "Batuhan: ₺2.100 (%66)" and "Ayşe: ₺1.100 (%34)"
    Each with a small colored segment matching their contribution

  Budget card 2:
  - "Faturalar" — ₺1.800/₺3.000 (%60)
  - Contribution split shown similarly

- Contribution summary section:
  Header: "Bu Ay Katkı Dağılımı"
  Horizontal stacked bar chart:
  - Full width bar, Batuhan portion in #BAC3FF (64%), Ayşe portion in #70D8C8 (36%)
  - Labels below: "Batuhan ₺3.200 (%64)" | "Ayşe ₺1.800 (%36)"

- Recent shared expenses:
  - "Batuhan — Migros ₺450" with timestamp
  - "Ayşe — Elektrik Faturası ₺380" with timestamp

- FAB: "+" to add new shared budget

- No borders, no divider lines. 16px spacing. Mobile width: 375px.
```

---

## PROMPT 8 — Aile Davet Ekranı

```
Design a mobile finance app screen for inviting a family member called "Üye Davet Et" (Invite Member) in Turkish.

Context: Simple invite flow where user enters partner's email to invite them to the shared family budget group.

Design specifications:
- Dark premium theme: background #131313
- Top: Back arrow + "Üye Davet Et" title

- Illustration area: A simple, minimal illustration of two people with a shared wallet/budget icon between them. Use only #BAC3FF and #2A2A2A colors. Flat, no gradients.

- Description text: 
  "Aile bütçenizi birlikte yönetin. Davet ettiğiniz kişi sadece ortak bütçeleri görebilir, kişisel hesaplarınız gizli kalır."
  #9A9A9A, 14px, centered

- Email input field:
  - Label: "E-posta Adresi" floating label in #9A9A9A
  - Input: #353535 background, no border, 12px radius
  - Placeholder: "ornek@email.com"

- Info card (#2A2A2A, 16px radius):
  - 🔒 icon + "Gizlilik Notu" title
  - "Davet edilen kişi sadece ortak bütçeleri ve ortak harcamaları görür. Kişisel hesap bakiyeleriniz, bireysel işlemleriniz ve özel bütçeleriniz tamamen gizli kalır."
  - Small text, #9A9A9A

- "Davet Gönder" button: full width, #BAC3FF, pill shape
- Below: "Davet 7 gün geçerlidir" small text in #9A9A9A

- No borders. Clean, trustworthy feel. Mobile width: 375px.
```

---

## PROMPT 9 — Kategori Yönetim Ekranı (Ayarlar)

```
Design a mobile finance app screen called "Kategoriler" (Categories) for managing expense and income categories with a 2-level hierarchy, in Turkish.

Context: Users can view system categories (locked), their subcategories, and add custom categories. The screen is accessed from Settings.

Design specifications:
- Dark premium theme: background #131313

- Top: Back arrow + "Kategoriler" title, 28px Inter 600
- Segment toggle: "Gider" (Expense) / "Gelir" (Income) — active tab #BAC3FF background, #1A1A2E text

- Category list (vertical, 16px spacing between groups):
  Each PARENT category is a collapsible group:
  - Row: 40px circular icon container (10% category color bg) + Category name "Market" in #E5E2E1, 16px Inter 500 + right side: chevron ▼ to expand + 🔒 lock icon for system categories (in #9A9A9A, very subtle)
  
  When expanded, subcategories appear indented (left padding 56px):
  - Each subcategory row: smaller 28px icon circle + name "Migros" in #9A9A9A, 14px Inter 400
  - System subcategories have subtle lock icon
  - User-created subcategories have a small delete X icon (appears on long press or swipe)
  
  Example expanded group:
  🛒 Market ▲ 🔒
     ├─ Migros 🔒
     ├─ BİM 🔒
     ├─ A101 🔒
     ├─ Şok 🔒
     └─ + Alt Kategori Ekle (text button in #BAC3FF, 13px)

- At the bottom of the full list:
  "+ Yeni Kategori Ekle" button: ghost style, full width, #BAC3FF text, dashed border effect at 15% opacity

- Visual hints:
  - System (locked) items: slightly dimmer, lock icon visible
  - Custom (user) items: full brightness, swipeable to delete
  - Each category color shown as left accent on the icon circle

- No 1px borders. Use tonal surface shifts between parent/child rows.
- Mobile width: 375px viewport
```

---

## PROMPT 10 — Kategori Ekle / Düzenle Bottom Sheet

```
Design a mobile finance app bottom sheet modal for adding a new category called "Kategori Ekle" (Add Category) in Turkish.

Context: This appears as a slide-up bottom sheet when user taps "+ Yeni Kategori Ekle" or "+ Alt Kategori Ekle". User can create a custom category with name, icon, color, and optionally assign it under a parent.

Design specifications:
- Dark premium theme: bottom sheet background #1A1A1A, scrim overlay 60% black
- Sheet: 24px top radius, drag handle bar at top (40px wide, 4px height, #3A3A3A)

- Title: "Yeni Kategori" — 20px, Inter 600, #E5E2E1
- Subtitle: "Gider kategorisi" or "Gelir kategorisi" — 13px, #9A9A9A (inherited from parent screen toggle)

- Form fields (vertical stack, 16px spacing):
  
  1. "Kategori Adı" — text input (#353535 bg, no border, 12px radius)
     Placeholder: "örn: Ev Eşyası"

  2. "Üst Kategori (Opsiyonel)" — dropdown/select field (#353535 bg)
     Shows "Bağımsız (Ana Kategori)" by default
     When tapped: shows list of existing parent categories to nest under
     If accessed via "+ Alt Kategori Ekle", pre-filled and locked to that parent

  3. "İkon Seç" — horizontal scrollable icon grid (5 columns visible):
     Common finance icons in circular 44px containers (#2A2A2A bg)
     Selected icon: #BAC3FF background with scale animation
     Icons: 🛒🍽️🚗💡🏠💊🎬🛍️📚💻🏋️💈🛡️🎁👶💰💼📈🏛️💵☕🎮✈️🐾💇🎨🔧📱🎶

  4. "Renk Seç" — horizontal row of 12 color circles (28px each):
     #4CAF50, #2196F3, #FF9800, #9C27B0, #795548, #F44336, #E91E63, #00BCD4, #3F51B5, #607D8B, #8BC34A, #FFD54F
     Selected color: white check mark + slightly larger (32px)

- Preview section (#2A2A2A card, 12px radius, 12px padding):
  Shows how the category will look: [icon in color circle] + "Ev Eşyası" + type badge
  Label above: "Önizleme" in #9A9A9A, 11px uppercase

- "Kaydet" button: full width, #BAC3FF background, #1A1A2E text, pill shape, 24px radius
  Disabled state: 40% opacity if name is empty

- No borders on inputs. Smooth transitions. Mobile width: 375px.
```

---

## PROMPT 11 — İşlem Ekle'de 2 Seviyeli Kategori Seçici

```
Design a mobile finance app category picker component for the "Add Transaction" screen, showing a 2-level hierarchy, in Turkish.

Context: When adding a new transaction, user taps the category field and this full-screen picker slides up. Shows parent categories as a grid, tapping one reveals its subcategories.

Design specifications:
- Dark premium theme: background #131313
- Top: "Kategori Seç" title + close X button, 20px Inter 600

- STATE 1 — Parent Category Grid (initial view):
  - 3-column grid layout, 12px gap
  - Each cell (#2A2A2A, 16px radius, 80px height):
    - Center: 36px circular icon container (10% category color background)
    - Below icon: Category name, 12px Inter 500, #E5E2E1
    - If has subcategories: tiny "›" indicator at top-right corner
  
  - Grid shows: Market, Ulaşım, Yeme-İçme, Faturalar, Kira/Konut, Sağlık, Eğlence, Alışveriş, Eğitim, Teknoloji, Spor, Kişisel Bakım, Sigorta, Hediye/Bağış, Çocuk, Diğer
  
  - Last cell: "+ Ekle" in dashed border style (#BAC3FF text) — opens Add Category sheet

- STATE 2 — Subcategory View (after tapping a parent):
  - Top: back arrow + parent name "Market" + parent icon, 18px Inter 600
  - "Bu kategoriyi seç" row: selects the parent directly (#2A2A2A card, #BAC3FF accent left bar)
  
  - Subcategory list (vertical, 12px spacing):
    Each item: 36px icon circle + name, tappable full-width row (#2A2A2A on tap)
    - Migros
    - BİM
    - A101
    - Şok
    - Diğer Market
    - "+ Alt Kategori Ekle" text button in #BAC3FF

- Selection feedback: Tapped category gets #BAC3FF border glow (2px, 20% opacity) + checkmark overlay

- Transition: Parent grid → subcategory list with smooth slide-left animation

- No 1px borders. Tonal layering only. Mobile width: 375px viewport.
```
