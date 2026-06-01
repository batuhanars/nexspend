# Transactions v2 Contract — İşlem Düzenleme + Gelişmiş Filtre & Arama

> **Bu dosya neden var?** İşlemler modülü CRUD olarak eksik (düzenleme yok) ve backend'in hazır filtre/arama gücü frontend'de açılmamış. Bu sprint iki işi tek pakette toplar: (1) detaydan **düzenleme** akışı, (2) çok-boyutlu **filtre paneli + arama**. Backend ~%90 hazır olduğu için ağırlık **frontend**'tedir.
>
> **PM (Opus) yazar; backend + frontend dev session'ları bu sözleşmeye uyar.** Karar tarihi: 24 May 2026.

---

## 0. Sprint Hedefi

1. İşlem detayından **MANUAL** işlemler düzenlenebilir (`AddTransactionPage` edit modunda yeniden kullanılır, `PATCH` ile kaydedilir).
2. Otomatik işlemler (`source != MANUAL`) salt-okunur — düzenle butonu gizli.
3. Liste ekranında tip chip'lerinin yanına **filtre paneli** (kategori + hesap + tarih aralığı) + **arama** eklenir; hepsi aynı anda çalışır (server-side, sayfa 1'den yeni sorgu).

**Out of scope (bu sprint değil):**
- **Tutar aralığı filtresi** — backend DTO desteklemiyor; istenirse ayrı backend işi olarak sonra.
- **Kaydedilmiş filtreler (saved filters)** — kalıcılık gerektirir, ileriye.
- **Çoklu kategori/hesap seçimi** — backend tek `categoryId`/`accountId` kabul ediyor; tek-seçim.
- **Tag seçici** (Sprint 3'ten ertelenmiş) — bu sprintin konusu değil, ayrı kalsın.
- Otomatik işlemlerin (borç/abonelik/tekrarlayan) düzenlenmesi.

---

## 1. Mevcut Durum Tespiti (dev session: BUNLARI YENİDEN YAZMA)

Kod taraması (24 May 2026) ile doğrulandı:

### Backend — zaten hazır
- `TransactionsService.findAll` query DTO'daki **tüm** filtreleri uyguluyor: `type`, `accountId`, `categoryId`, `startDate`, `endDate`, `search`, `sharedBudgetId` (`transactions.service.ts:29-94`).
  - ⚠️ `search` yalnız `where.title = { contains }` — açıklama/not'a bakmıyor.
- `TransactionsService.update` **tam doğru**: `balanceService.revert(eski)` + `apply(yeni)` + `transaction.updated` event emit (`:238-340`). Bütçe recompute event üzerinden tetikleniyor.
- `INCOME` + `CREDIT_CARD` reddi create + update'te mevcut (Sprint 12.5).

### Frontend — zaten hazır
- `TransactionDetailPage` var, tile tap ile açılıyor (`/transactions/:id`), fiş tarzı kart + **Sil** aksiyonu. **Düzenleme YOK.**
- `TransactionsPage` tip chip'leri (Hepsi/Gelir/Gider/Transfer), infinite scroll, swipe-delete, summary row, pull-to-refresh mevcut.
- `TransactionsBloc` filtreyi **tek `String? filter`** (yalnız type) olarak taşıyor → refactor gerekecek.
- `AddTransactionPage` create akışı tam (tutar, kategori grid, hesap chip, tarih, tekrarlayan toggle, INCOME+CC gizleme).

---

## 2. Backend Değişiklikleri (minimal)

### 2.1 MANUAL-only guard (savunma amaçlı)
`TransactionsService.update` başına: işlem `source != MANUAL` ise reject.

```typescript
if (existing.source !== TransactionSource.MANUAL) {
  throw new BadRequestException(
    'Otomatik oluşturulan işlemler düzenlenemez. Bağlı borç/abonelik kaydından yönetin.',
  );
}
```

> İç akışlar (borç ödeme, abonelik yenileme, tekrarlayan) bu işlemleri **create** ediyor, `update` etmiyor — guard onları kırmaz. Doğrula: `grep -rn "\.update(" src/modules` ile `TransactionsService.update`'in başka servisten çağrılmadığını teyit et.

### 2.2 Arama kapsamını genişlet (opsiyonel, PM kararı: EVET)
`findAll` search dalını başlık + açıklamayı kapsayacak şekilde:

```typescript
if (search) {
  where.OR = [
    { title: { contains: search } },
    { description: { contains: search } },
  ];
}
```

> Not: MySQL default collation case-insensitive (`utf8mb4_..._ci`) — ekstra mode gerekmez.

### 2.3 Testler
- `transactions.service.spec.ts`: `update` → `source != MANUAL` ise 400 (yeni unit test).
- `update` MANUAL'de mevcut davranış (balance revert+apply, event emit) korunur — regresyon assert'i.
- Arama OR genişlemesi için bir test (description'da eşleşme).
- E2E: `PATCH /transactions/:id` MANUAL başarı + otomatik kayıt 400.

---

## 3. Frontend Değişiklikleri (sprintin ağırlığı)

### 3.1 Düzenleme akışı

**Detay sayfası (`TransactionDetailPage`):**
- AppBar'a **Düzenle** ikonu ekle (`Icons.edit_outlined`), yalnız `transaction.source == MANUAL` ise görünür.
- Tıklayınca `AddTransactionPage`'i **edit modunda** aç (mevcut işlemi geçir).

**`AddTransactionPage` edit modu:**
- Opsiyonel `TransactionModel? editing` parametresi. Doluysa:
  - Form alanları prefill (tutar, tip, kategori, hesap, tarih, açıklama, not).
  - Başlık "İşlemi Düzenle", buton "Kaydet".
  - **Tekrarlayan toggle gizli** (mevcut işlem tekrarlayan şablona çevrilemez).
  - Submit → `PATCH /transactions/:id` (create yerine).
- `AddTransactionBloc`: `AddTransactionInitialized`'a editing payload; submit dalı create/update ayrımı.
- Başarı → detay sayfası pop + liste refresh (mevcut `AppEvents` mekanizması).

> **Edit'te tip değişimi** (örn. EXPENSE→INCOME) serbest — backend `update` bakiye yön değişimini revert/apply ile hallediyor. INCOME + kredi kartı seçimi mevcut gizleme kuralıyla zaten engelli.

### 3.2 Filtre paneli

**Bloc refactor — `TransactionFilter` nesnesi:**
```dart
class TransactionFilter {
  final String? type;        // INCOME/EXPENSE/TRANSFER, null=hepsi
  final String? categoryId;
  final String? accountId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? search;
  // copyWith + activeCount getter (type hariç kaç boyut aktif)
}
```
- `TransactionsFilterChanged(String?)` → `TransactionsFilterChanged(TransactionFilter)` olur.
- `TransactionsLoaded.filter` artık `TransactionFilter`.
- Her filtre değişimi → sayfa 1'den yeni `getTransactions(filter)` (mevcut server-side pagination ile).
- `ReportRepository` değil, `TransactionsRepository.getTransactions` query param'ları filtreden map'lenir.

**UI:**
- Tip chip'leri kalır (hızlı erişim → `filter.type`).
- Chip bar'ın yanına **Filtrele** ikonu (`Icons.tune`) + aktif filtre sayısı rozeti (`filter.activeCount > 0`).
- Tıklayınca alttan **bottom sheet**:
  - **Tarih aralığı:** preset chip'ler (Bu Ay / Son 3 Ay / Bu Yıl / Özel) + Özel'de `showDateRangePicker`.
  - **Kategori:** tek-seçim (kategori grid veya dropdown).
  - **Hesap:** tek-seçim (hesap chip'leri).
  - "Temizle" + "Uygula" butonları.
- Aktif filtre varken liste üstünde kaldırılabilir özet chip'leri (örn. "Market ✕", "Bu Ay ✕") — opsiyonel ama UX için önerilir.

### 3.3 Arama
- AppBar'da arama ikonu → açılır `TextField` (veya `SliverAppBar` search mode).
- **Debounce 350ms** → `filter.copyWith(search: q)` → reload.
- Boşaltınca search filtresi kalkar.

### 3.4 l10n (TR + EN)
Yeni anahtarlar: "İşlemi Düzenle"/"Edit Transaction", "Filtrele"/"Filter", "Tarih Aralığı"/"Date Range", "Temizle"/"Clear", "Uygula"/"Apply", "Ara"/"Search", "Bu Yıl"/"This Year" (yoksa), otomatik işlem düzenlenemez uyarısı.

### 3.5 Testler
- BLoC: `TransactionFilter` ile çok-boyutlu filtre → doğru query param map'i; her değişimde page 1 reset.
- BLoC: edit submit → PATCH çağrısı (create değil); başarı/hata state'leri.
- Widget: detay sayfasında MANUAL'de Düzenle görünür, otomatar gizli.
- Widget: filtre bottom sheet render + Uygula → bloc event.

---

## 4. Test Senaryoları (kabul kriterleri)

### Backend
- ✅ `PATCH` MANUAL işlem → başarı, bakiye revert+apply, `transaction.updated` emit
- ✅ `PATCH` `source=DEBT_PAYMENT`/`SUBSCRIPTION`/`RECURRING` → 400
- ✅ `search=...` description'da eşleşeni döndürür (title dışında)
- ✅ Çoklu filtre kombinasyonu (type+categoryId+date) → AND mantığı doğru

### Frontend
- ✅ MANUAL detayında Düzenle butonu, otomatikte yok
- ✅ Düzenle → prefilled form → Kaydet → liste güncellenir, bakiye/bütçe doğru
- ✅ Filtre paneli: kategori+tarih seç → liste daralır, rozet sayısı artar
- ✅ Arama: yazınca debounce'lu daralma, temizleyince geri döner
- ✅ Tip chip + panel filtresi birlikte çalışır (regresyon)

---

## 5. Sıra ve Bağımlılık

1. **Backend dev session (kısa, ~0.25 gün):** MANUAL guard + search OR genişlemesi + spec/e2e. Bağımsız, hemen başlayabilir.
2. **Frontend dev session (ağırlık, ~1.5 gün):**
   - Önce **bloc refactor** (`TransactionFilter`) — diğer her şeyin temeli.
   - Sonra paralel: (a) düzenleme akışı, (b) filtre paneli + arama UI.
   - l10n + testler.
3. **PM:** integration smoke test (düzenle → bütçe/bakiye doğru; filtre kombinasyonları; otomatik işlem salt-okunur) → Railway deploy (backend) + build.

---

## 6. Tahmini Süre
- Backend: ~0.25 iş günü (çoğu hazır)
- Frontend: ~1.5 iş günü
- PM koordinasyon + smoke + deploy: ~0.25 gün
- **Toplam: ~2 iş günü**

---

## 7. Açık Sorular / PM Kararları (24 May 2026)
- (1) Düzenleme kapsamı = **yalnız MANUAL** (otomatik salt-okunur). ✅ karar
- (2) Tek paket "İşlemler v2" (düzenleme + filtre/arama birlikte). ✅ karar
- (3) Arama açıklamayı da kapsasın (title-only değil). ✅ karar
- (4) Kategori/hesap filtresi tek-seçim (backend sınırı). ✅ karar
- (5) Tutar aralığı + kaydedilmiş filtreler + tag seçici → **out of scope**, ileriye. ✅ karar
