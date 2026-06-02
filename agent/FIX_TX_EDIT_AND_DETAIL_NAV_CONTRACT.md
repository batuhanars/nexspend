# Contract — İşlem Güncelleme Bug'ı + Her Yerden İşlem Detayı

> **Tür:** Frontend-only fix + UX iyileştirme. Backend değişikliği YOK.
> **Karar (2 Haz 2026):** Güncelleme özelliği KORUNUR, bug düzeltilir (kullanıcı onayı).
> **Dev session:** Flutter (Sonnet), `cd mobile`.

---

## Arka Plan / Kök Neden

İşlem detayındaki "Güncelle" butonu her denemede **"Geçersiz işlem bilgileri" (400)** veriyordu.

- Frontend güncelleme payload'u (`add_transaction_page.dart`, edit branch) `accountId` ve `transferToAccountId` gönderiyor.
- Backend `UpdateTransactionDto`'da bu iki alan **yok**.
- `api/src/main.ts` → `ValidationPipe({ whitelist: true, forbidNonWhitelisted: true })` → DTO'da olmayan alan gelince istek **direkt reddediliyor**.
- Ayrıca backend `update()` zaten `existing.accountId` kullanıyor; **hesap değişimi sunucuda desteklenmiyor**. Yani bu iki alan tamamen gereksiz.

**Ek risk (mutlaka uygula):** `transactions.service.ts:285` → "TRANSFER güncelleme desteklenmez". `revert` transferi iki hesaptan geri alır, `apply` sadece kaynak hesaba uygular → bir TRANSFER düzenlenirse hedef hesap bakiyesi bozulur. Whitelist düzelince bu aktifleşir. Bu yüzden **transfer işlemlerinde düzenleme kapatılmalı.**

---

## İş 1 — Güncelleme bug'ı düzelt

### 1a. Edit payload'undan yasak alanları çıkar
**Dosya:** `mobile/lib/presentation/transactions/pages/add_transaction_page.dart` (edit branch, ~satır 154-166)

`if (_isEditMode)` payload'undan **`accountId` ve `transferToAccountId`'yi kaldır.** Kalan alanlar:
```dart
final data = <String, dynamic>{
  'type': _type,
  'amount': amount,
  'title': title,
  'transactionDate': submitDate.toUtc().toIso8601String(),
  if (_selectedCategory != null) 'categoryId': _selectedCategory!.id,
  if (_noteController.text.trim().isNotEmpty) 'note': _noteController.text.trim(),
};
```
> Bu alanların hepsi `UpdateTransactionDto` tarafından kabul ediliyor (`type/amount/title/note/categoryId/transactionDate`). `create` branch'ine DOKUNMA.

### 1b. Edit modunda hesap seçici read-only
Backend hesap değişimini yok saydığı için, edit modunda hesap alanı **değiştirilemez** gösterilmeli (mevcut hesabı gösterir, dokunulamaz/disabled). Kullanıcıyı yanıltma. Type seçici sadece EXPENSE/INCOME arasında kalsın (transfer edit zaten kapatılıyor — bkz. 1c).

### 1c. Transfer işlemlerinde düzenlemeyi kapat
**Dosya:** `mobile/lib/presentation/transactions/pages/transaction_detail_page.dart` (~satır 78)

Edit butonu koşulunu güncelle — sadece MANUAL **ve transfer olmayan** işlemlerde göster:
```dart
if (transaction.source == TransactionSource.MANUAL &&
    transaction.type != TransactionType.TRANSFER)
  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _openEdit(context)),
```
Silme butonu MANUAL için olduğu gibi kalır (transfer silme bakiye geri-alımı `revert` ile doğru çalışıyor).

---

## İş 2 — Her listede işlem detayına gidebilme

**Hedef:** Ana ekran (son işlemler), Bütçe detayı, Hesap detayı listelerindeki işlemlere dokununca detay ekranı açılsın. Şu an sadece İşlemler ekranı tıklanabilir.

### 2a. Detay route'unda `bloc`'u opsiyonel yap
**Dosya:** `mobile/lib/navigation/app_router.dart` (~satır 252-258)

```dart
final extra = state.extra as Map<String, dynamic>;
final transaction = extra['transaction'] as TransactionModel;
final bloc = extra['bloc'] as TransactionsBloc?;     // nullable
if (bloc != null) {
  return BlocProvider.value(
    value: bloc,
    child: TransactionDetailPage(transaction: transaction, listBloc: bloc),
  );
}
return TransactionDetailPage(transaction: transaction); // bloc'suz
```

### 2b. `TransactionDetailPage`'i bloc'a bağımlı olmaktan çıkar
**Dosya:** `transaction_detail_page.dart`

- Constructor'a opsiyonel `final TransactionsBloc? listBloc;` ekle.
- `_confirmDelete` içindeki `context.read<TransactionsBloc>()` çağrısını kaldır. Yerine:
  - `listBloc != null` ise → `listBloc!.add(TransactionDeleteRequested(transaction.id))` (mevcut optimistic davranış korunur).
  - `listBloc == null` ise → `getIt<TransactionRepository>().deleteTransaction(transaction.id)` ile doğrudan sil (await), hata olursa snackbar.
  - Her iki durumda da `context.pop(true)` döndür ki açan ekran kendini tazelesin.
- İşlemler ekranından açılışta `listBloc` dolu gelir → davranış aynen korunur. Regresyon olmamalı.

### 2c. Üç özel tile'a onTap ekle + dönüşte tazele
Her birinde işlem satırını `InkWell`/`onTap` ile sarmala ve **bloc'suz** push et:
```dart
onTap: () async {
  final changed = await context.push<bool>(
    RouteNames.transactionDetail(t.id),
    extra: {'transaction': t},
  );
  if (changed == true && context.mounted) {
    // bu ekranın mevcut refresh mekanizmasını tetikle (aşağı bak)
  }
},
```

| Dosya | Widget | Dönüşte tazeleme |
|---|---|---|
| `dashboard/widgets/recent_transactions_section.dart` | `_TransactionTile` | DashboardBloc refresh event'i (sayfanın mevcut yükleme event'i) |
| `budgets/pages/budget_detail_page.dart` | `_BudgetTransactionTile` | BudgetsBloc / budget detay yeniden yükleme |
| `accounts/widgets/account_transactions_section.dart` | `AccountTransactionTile` | Hesap detayı işlem listesi yeniden yükleme |

> Dev: Her ekranın halihazırda kullandığı yükleme/refresh event'ini bul ve `changed == true` olduğunda onu tetikle. Yeni bloc kurma — mevcut olanı kullan. Widget'ın bloc'a erişimi yoksa callback parametresi (`VoidCallback? onChanged`) ile parent sayfaya kaldır.

- Otomatik kaynaklı (RECURRING/DEBT/SUBSCRIPTION) işlemler de tıklanabilir olsun — detay ekranı zaten edit/delete'i `source == MANUAL` ile gizliyor, sadece makbuz görünür. Sorun yok.
- Görsel: dokunma feedback'i için `InkWell` + uygun `borderRadius`; tasarım sistemini bozma (1px border yok, mevcut padding/renkler korunur).

---

## Kabul Kriterleri

1. Manuel (transfer olmayan) bir işlem detayından tutar/kategori/tarih/not/başlık güncellenebiliyor; "geçersiz" hatası YOK.
2. Transfer işlemlerinde düzenle butonu görünmüyor (silme var).
3. Ana ekran, bütçe detayı, hesap detayı listelerindeki her işleme dokununca detay açılıyor.
4. Detaydan silince/güncelleyince geri dönülen ekran güncel veriyi gösteriyor (stale liste yok).
5. İşlemler ekranından açılan detayda eski davranış (optimistic delete) korunuyor — regresyon yok.
6. `flutter analyze` temiz, `flutter test` yeşil.

## Test Notu
- Mümkünse `transaction_detail_page` için bloc'lu ve bloc'suz iki yol da derleniyor/çalışıyor diye kontrol et.
- Backend testine gerek yok (değişiklik yok).
