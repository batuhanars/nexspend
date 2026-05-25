# Transactions Bulk Delete Contract — İşlemlerde Toplu Silme

> **Bu dosya neden var?** İşlem listesinde silme şu an yalnız tekli (swipe + detay sayfası). Kullanıcı birden çok işlemi tek tek silmek zorunda. Bu küçük sprint, **çoklu seçim + toplu silme** ekler. İşlemler v2'nin (düzenleme + filtre/arama) takip işidir.
>
> **PM (Opus) yazar; backend + frontend dev session'ları bu sözleşmeye uyar.** Karar tarihi: 24 May 2026.

---

## 0. Sprint Hedefi

1. Liste ekranında **seçim modu**: long-press ile gir, tile'lara dokunarak çoklu seç.
2. Contextual AppBar: seçili sayı + **Sil** + seçimi kapat.
3. **Atomik toplu silme** backend endpoint'i: tüm seçilenleri tek `$transaction`'da sil + bakiyeleri geri al + her biri için `transaction.deleted` event (bütçe recompute).
4. **Yalnız MANUAL seçilebilir** — otomatik kayıtlar (borç/abonelik/tekrarlayan/tahsilat) seçim dışı.

**Out of scope:**
- "Tümünü seç" (select-all) — ileriye; bu sprint manuel çoklu seçim.
- Mevcut **tekli** silmenin source-agnostic davranışını değiştirmek (aşağıda §7 not).
- Silinen otomatik işlemin bağlı borç/abonelik `paidAmount`'ını geri sarması (ayrı, daha büyük iş — §7).

---

## 1. Kavramsal Karar (PM, 24 May 2026)

**Toplu silme yalnız `source == MANUAL` işlemlerde.** Otomatik kayıtlar seçilemez (checkbox disabled/yok).

> **Gerekçe:** Düzenleme kararıyla (yalnız MANUAL) tutarlı. Bir `DEBT_PAYMENT`/`SUBSCRIPTION` işlemini silmek bağlı borcun/aboneliğin durumunu desenkronize eder; toplu silme bunu kitlesel hale getirir. Footgun'ı büyütmemek için seçim dışı bırakılır.

---

## 2. Backend Değişiklikleri

### 2.1 Endpoint
`POST /api/transactions/bulk-delete`

```
Body: { "ids": string[] }   // BulkDeleteTransactionDto
Yanıt: { "deleted": number }
```

DTO (`dto/bulk-delete-transaction.dto.ts`):
```typescript
export class BulkDeleteTransactionDto {
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(100)        // kötüye kullanım/performans sınırı
  @IsString({ each: true })
  ids!: string[];
}
```

### 2.2 `TransactionsService.bulkDelete(userId, ids)`
- İşlemleri çek: `findMany({ where: { id: { in: ids }, userId } })`.
- **Doğrulama:**
  - Bulunan sayısı `ids` sayısından azsa (başkasına ait / yok) → 400 "Bazı işlemler bulunamadı."
  - İçlerinden biri `source !== MANUAL` ise → 400 "Yalnızca manuel işlemler toplu silinebilir." (frontend zaten engelliyor; bu defense-in-depth).
- **Atomik silme** — tek `$transaction`:
  - Her işlem için `balanceService.revert(tx, accountId, type, amount)` (TRANSFER ise mevcut `remove()` ile aynı çift-hesap mantığı korunur).
  - `transactionTag.deleteMany` (varsa) + `transaction.delete`.
- Commit sonrası her silinen için `eventEmitter.emit('transaction.deleted', new TransactionDeletedEvent(...))` → BudgetService spent yeniden hesaplar.
- `{ deleted: count }` döndür.

> Mevcut `remove()` metodundaki bakiye-revert + event mantığını referans al; bulkDelete onu döngüde değil, **tek transaction** içinde toplulaştırarak yapsın (atomiklik).

### 2.3 Controller
`@Post('bulk-delete')` → `bulkDelete(@CurrentUser() user, @Body() dto)`. JwtAuthGuard zaten controller seviyesinde.

### 2.4 Testler
- `transactions.service.spec.ts`:
  - bulkDelete başarı: 3 MANUAL → 3 silinir, revert 3 kez, `transaction.deleted` 3 kez emit.
  - non-MANUAL içeren liste → 400, hiçbir şey silinmez (rollback).
  - eksik/başkasına ait id → 400.
- e2e (`test/transactions.e2e-spec.ts`): `POST /bulk-delete` MANUAL başarı (200, deleted sayısı), non-MANUAL 400, boş ids 400, token yok 401.

---

## 3. Frontend Değişiklikleri

### 3.1 Repository
`TransactionsRepository.bulkDelete(List<String> ids) → Future<int>` — `POST /transactions/bulk-delete`, `data['data']['deleted']` döner.

### 3.2 Bloc (`TransactionsBloc`)
Seçim modu state alanları → `TransactionsLoaded`'a ekle:
- `bool selectionMode`
- `Set<String> selectedIds`

Yeni event'ler:
- `SelectionModeEntered(String? initialId)` — long-press; initialId varsa seçili başlar.
- `SelectionToggled(String id)` — tile dokunuşu (yalnız MANUAL; bloc yine de guard'lasın).
- `SelectionCleared` — modtan çık, seçim sıfırla.
- `BulkDeleteRequested` — seçilenleri sil.

`BulkDeleteRequested` davranışı (optimistic pattern — `mobile/CLAUDE.md`):
- Optimistic: seçilenleri listeden çıkar + selectionMode kapat (emit).
- `repo.bulkDelete(ids)` → başarı: özet/summary refresh; hata: eski listeyi geri yükle (revert) + hata state/snackbar.
- `bloc_test`'te **çift emit**'i unutma.

### 3.3 UI (`transactions_page.dart` + `transaction_tile.dart`)
- **Seçim moduna giriş:** tile **long-press** → `SelectionModeEntered(tile.id)`.
- **Seçim modunda:**
  - `SliverAppBar` contextual hale gelir: başlık "{n} seçili", sol `close` ikonu (`SelectionCleared`), sağ `delete_outline` (kırmızı, `AppColors.error`).
  - Her MANUAL tile'da seçim göstergesi (seçiliyse `AppColors.primary` tonal vurgu + check ikonu; tonal surface ile, **1px border yok**).
  - **Otomatik tile'lar (source != MANUAL):** seçilemez — dokununca seçim toggle olmaz (opsiyonel: hafif disabled görünüm + tek dokunuşta "manuel olmayan işlem seçilemez" snackbar).
  - Tile tap (seçim modunda) → `SelectionToggled`; (normal modda) → mevcut detay sayfası.
- **Sil:** onay dialog ("{n} işlem silinsin mi? Bu işlem geri alınamaz.") → `BulkDeleteRequested`.
- Filtre/arama/infinite-scroll mevcut davranışı seçim modunda da bozulmamalı (seçim modunda FAB/filtre gizlenebilir — UX dev kararı).

### 3.4 l10n (TR + EN)
- "{n} seçili" / "{n} selected"
- "Seçimi temizle" / "Clear selection"
- toplu silme onay başlık/içerik
- "manuel olmayan işlem seçilemez" / "auto-generated transactions can't be selected"

### 3.5 Testler
- BLoC: SelectionToggled MANUAL ekler/çıkarır; non-MANUAL toggle no-op; BulkDeleteRequested optimistic emit + başarı refresh; hata → revert.
- Widget: long-press → seçim modu + contextual AppBar; otomatik tile seçilemez; Sil → onay → event.

---

## 4. Test Senaryoları (kabul kriterleri)

### Backend
- ✅ `POST /bulk-delete` 3 MANUAL → 200 `{deleted:3}`, bakiyeler geri alınır, 3 event
- ✅ liste non-MANUAL içeriyor → 400, hiçbiri silinmez (atomik rollback)
- ✅ başkasına ait/yok id → 400
- ✅ boş ids → 400 (ArrayNotEmpty)

### Frontend
- ✅ long-press → seçim modu, contextual AppBar "{n} seçili"
- ✅ MANUAL tile seçilir/seçim kalkar; otomatik tile seçilemez
- ✅ Sil → onay → liste optimistic daralır, başarıda kalıcı; hata → geri döner
- ✅ Normal modda tile tap hâlâ detay açar (regresyon)

---

## 5. Sıra ve Bağımlılık
1. **Backend dev session (~0.25 gün):** DTO + bulkDelete servis + controller + spec/e2e. Bağımsız, hemen başlar.
2. **Frontend dev session (~0.75 gün):** repository + bloc seçim modu + UI + l10n + test. Backend kontratına göre paralel başlar.
3. **PM:** entegrasyon smoke (çoklu seç → sil → bakiye/bütçe doğru; otomatik seçilemez; tekli silme regresyonu) → Railway deploy + build.

---

## 6. Tahmini Süre
- Backend ~0.25 gün, Frontend ~0.75 gün, PM ~0.25 gün → **~1.25 iş günü**

---

## 7. Açık Sorular / PM Kararları (24 May 2026)
- (1) Toplu silme **yalnız MANUAL** seçilebilir. ✅ karar (veri tutarlılığı; düzenleme kararıyla tutarlı)
- (2) "Tümünü seç" → **out of scope**, ileriye.
- (3) **Bilinen pre-existing tutarsızlık (bu sprint DIŞI):** mevcut tekli swipe/detay silme `source`'a bakmıyor — otomatik işlem tekli silinebiliyor ve bağlı borç/abonelik `paidAmount`'ı geri sarılmıyor (desync). Toplu silme MANUAL-only olduğu için bu footgun'ı büyütmez. Tekli silmenin source-aware hale getirilmesi + linked-entity revert ayrı bir sprint olarak değerlendirilmeli.
  - **✅ ÇÖZÜLDÜ — frontend (25 May 2026):** Tekli silme artık MANUAL-only. `transaction_tile.dart` otomatik işlemleri `Dismissible` ile sarmıyor (swipe yok); `transaction_detail_page.dart` Sil butonunu `source == MANUAL` ile gizliyor (düzenleme deseniyle simetrik). Testler: detay sayfası MANUAL→var / RECURRING+DEBT_PAYMENT→yok; tile swipe MANUAL→`Dismissible` / otomatik→yok.
  - **Backend guard bilinçli ertelendi (25 May 2026):** `remove()`'a `source !== MANUAL` 400 guard'ı **eklenmedi**. Doğrulandı: `remove()` yalnız kullanıcı DELETE endpoint'inden çağrılıyor (cascade'den değil) + sahiplik `where: { id, userId }` ile zaten korunuyor. Bypass yalnız kullanıcının kendi token'ıyla kendi verisine karşı mümkün → güvenlik (yetki/cross-tenant) açığı değil, yalnız self-inflicted veri-bütünlüğü (CWE-602). İstenirse defense-in-depth olarak sonradan eklenebilir; linked-entity `paidAmount` revert ise silme yolu kapandığı için artık konusuz.
