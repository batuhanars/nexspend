# Data Reset Contract — Tüm Kişisel Verileri Sıfırlama

> **Bu dosya neden var?** Kullanıcı deneysel veri girip "sıfırdan, tutarlı veriyle başlamak" istiyor. Ayarlar ekranının en altına bir **"Tüm Verileri Sıfırla"** aksiyonu eklenir: hesaplar, işlemler, bütçeler, borçlar, abonelikler, fişler vb. silinir; **hesabın kendisi (profil + tercihler) korunur** — kullanıcı oturumda kalır, temiz sayfayla devam eder.
>
> **PM (Opus) yazar; backend + frontend dev session'ları bu sözleşmeye uyar.** Karar tarihi: 24 May 2026.

---

## 0. Sprint Hedefi

1. Backend: kullanıcının **kişisel verisini** silen, **user satırını + profil/tercihleri koruyan** atomik bir reset endpoint'i.
2. Frontend: Ayarlar ekranının en altında "Tehlikeli Bölge" → "Tüm Verileri Sıfırla" → **yazarak onay ("SIFIRLA")** → sıfırla → temiz ana ekrana dön.

**Out of scope:**
- Hesabı silme (zaten var: `DELETE /users/me`). Bu farklı — hesap kalır.
- Aileden çıkarma / grup silme (PM kararı: aileye dokunulmaz, §1).
- Geri alma / yedek (reset geri alınamaz; uyarı UI'da).

---

## 1. Kapsam Kararları (PM, 24 May 2026)

### KORUNUR (silinmez)
- `User` satırı + profil: fullName, email, passwordHash, Google bağlantısı, **avatar**
- Tercihler: currency, language, biometricEnabled, notificationsEnabled, **FCM token**
- **Kategoriler** — hem sistem (userId null) hem kullanıcının özel kategorileri. *Gerekçe:* taksonomi/config; ayrıca korunan ortak bütçeler `categoryId` referans verir → silme FK'yı kırar.
- Global `MerchantCategoryMap` (userId null)
- **Aile:** `FamilyMember` (üyelik) + `FamilyGroup` + `SharedBudget` — hepsi korunur (çok-kullanıcılı; başka üyeleri bozmayız)

### SİLİNİR (kullanıcıya ait kişisel veri)
- `Account` (+ `CreditCardStatement`)
- `Transaction` (+ `TransactionTag`)
- `RecurringTransaction`
- `Budget`
- `Debt` (+ `DebtInstallment`, `DebtPayment`)
- `Subscription`
- `Receipt` (+ `ReceiptItem`) **+ disk'teki görseller** (`uploads/receipts/...`)
- `Insight`
- Kullanıcının kendi `Tag`'leri (userId = bu kullanıcı)
- Kullanıcının kendi `MerchantCategoryMap`'leri (userId = bu kullanıcı)
- Kullanıcının `SharedExpense` katkıları → silinir + **etkilenen `SharedBudget.spent` yeniden hesaplanır** (diğer üyelerin katkıları korunur)

> **Önemli:** Kategoriler SİLİNMEZ. Kullanıcının özel kategorileri kalır (config + FK güvenliği).

---

## 2. Backend Değişiklikleri

### 2.1 Endpoint
`POST /api/users/me/reset` (JwtAuthGuard). Yanıt: `{ message: 'Verileriniz sıfırlandı.' }` (opsiyonel: silinen kayıt sayıları).

> Defense-in-depth (opsiyonel): body `{ confirm: 'SIFIRLA' }` doğrula; değilse 400. Asıl koruma JWT + frontend typed-confirm. Dev kararı.

### 2.2 `UsersService.resetData(userId)`
1. `findUser(userId)` (yoksa 404).
2. **Fiş görsel URL'lerini topla** (silmeden önce): `receipt.findMany({ where: { userId }, select: { imageUrl } })`.
3. **Etkilenen SharedBudget'ları topla:** kullanıcının `SharedExpense`'lerinden `sharedBudgetId` set'i çıkar.
4. **Tek `$transaction`** içinde, FK-güvenli sırada `deleteMany({ where: { userId } })`:
   - Önce `Transaction` (cascade `TransactionTag`), `Budget`, `RecurringTransaction`, `Subscription`, `Insight`
   - `Debt` (cascade installment + payment)
   - `Receipt` (cascade item)
   - `CreditCardStatement` (accountId üzerinden: `where: { account: { userId } }`)
   - Kullanıcının `SharedExpense`'leri
   - `Tag` (userId), `MerchantCategoryMap` (userId **not null** filtresi — global'leri silme)
   - En son `Account`
   - **Kategorilere dokunma.** Aile tablolarına dokunma.
   - Silme sonrası etkilenen her `SharedBudget` için `spent` = kalan `SharedExpense` toplamı olarak güncelle.
5. Commit sonrası: toplanan fiş görsellerini disk'ten sil (mevcut `deleteLocalFile` helper'ı gibi, sessiz).
6. `{ message: 'Verileriniz sıfırlandı.' }` döndür.

> **FK sırası:** Transaction `accountId`/`debtId`/`subId`/`sharedBudgetId` referans verir → transaction'lar account/debt/subscription'dan **önce** silinmeli. Dev kesin sırayı şema FK'larına göre doğrulasın; gerekirse `deleteMany` çağrılarını sıralasın.

### 2.3 Testler
- Unit (`users.service.spec.ts`): resetData → user korunur (delete user ÇAĞRILMAZ), account/transaction/budget/debt/subscription/receipt/insight deleteMany çağrılır, kategori deleteMany ÇAĞRILMAZ, SharedBudget.spent recompute çağrılır, fiş görselleri için deleteLocalFile çağrılır.
- e2e (`test/users.e2e-spec.ts` veya mevcut): `POST /users/me/reset` 200; token yok → 401.

---

## 3. Frontend Değişiklikleri

### 3.1 Repository
`UsersRepository.resetData() → Future<void>` — `POST /users/me/reset`.

### 3.2 Ayarlar ekranı (`SettingsPage`)
- En alta yeni **"Tehlikeli Bölge"** bölümü (diğer gruplardan görsel olarak ayrı; başlık `AppColors.error` tonunda).
- İçinde tek öğe: **"Tüm Verileri Sıfırla"** (kırmızı metin/ikon `Icons.delete_forever_outlined`, `AppColors.error`).
- Alt açıklama: "Hesaplar, işlemler, bütçeler, borçlar, abonelikler ve fişler kalıcı olarak silinir. Profil ve ayarların korunur."

### 3.3 Onay akışı (yazarak onay)
- Tıklayınca **bottom sheet / dialog**:
  - Uyarı metni (geri alınamaz; ne silinir/ne kalır).
  - `TextField` — kullanıcı **"SIFIRLA"** yazmalı.
  - "Sıfırla" butonu (kırmızı) yalnız metin **tam** "SIFIRLA" olunca aktif; aksi disabled.
  - "Vazgeç".
- Onayda → `resetData()` çağrılır; sırasında buton spinner/disabled.
- **Başarı:** snackbar "Verileriniz sıfırlandı."; ana ekrana (`/home`) git ve veriyi yeniden çek (dashboard/hesaplar artık boş durum). Canlı blocs'ların stale kalmaması için `/home`'a dönüşte refresh tetikle (gerekiyorsa ilgili `AppEvents`/refresh event'leri).
- **Hata:** snackbar (hata mesajı), ekranda kal.

### 3.4 SettingsBloc / state
- Reset aksiyonu `SettingsBloc`'a event olarak (`SettingsResetRequested`) veya sayfadan doğrudan repository çağrısı (mevcut desene uy). Yükleniyor/başarı/hata durumları.

### 3.5 l10n (TR + EN)
- "Tehlikeli Bölge" / "Danger Zone"
- "Tüm Verileri Sıfırla" / "Reset All Data"
- açıklama, onay başlık/içerik, "SIFIRLA yazın" / "Type RESET", başarı/hata
- > **Not:** TR onay kelimesi "SIFIRLA", EN "RESET" — UI hangi dildeyse o kelimeyi beklesin (l10n'dan `resetConfirmWord`).

### 3.6 Testler
- BLoC/repository: reset başarı → success state; hata → error state.
- Widget: onay sheet'inde buton yalnız doğru kelime yazılınca aktifleşir; yanlış kelimede disabled.

---

## 4. Test Senaryoları (kabul kriterleri)

### Backend
- ✅ resetData sonrası: user + profil + tercihler DURUYOR; account/transaction/budget/debt/subscription/receipt/insight/tag(user)/merchantMap(user) GİTTİ
- ✅ Kategoriler (sistem + özel) DURUYOR
- ✅ Aile üyeliği + grup + ortak bütçe DURUYOR; kullanıcının SharedExpense'leri silindi + SharedBudget.spent recompute
- ✅ Fiş görselleri disk'ten silindi
- ✅ Başka kullanıcının verisi etkilenmedi
- ✅ token yok → 401

### Frontend
- ✅ Ayarlar en altında Tehlikeli Bölge + Sıfırla butonu
- ✅ Onay sheet: "SIFIRLA" yazılmadan buton disabled; yazılınca aktif
- ✅ Başarı → /home, boş durum; hata → snackbar + ekranda kal

---

## 5. Sıra ve Bağımlılık
1. **Backend dev (~0.5 gün):** resetData servis + endpoint + FK-güvenli silme + SharedBudget recompute + dosya temizliği + test. Bağımsız başlar.
2. **Frontend dev (~0.5 gün):** repository + Ayarlar Tehlikeli Bölge + yazarak-onay sheet + post-reset refresh + l10n + test. Backend kontratına göre paralel.
3. **PM:** entegrasyon smoke (veri gir → reset → her şey boş, profil/tercih duruyor, aile duruyor) → Railway deploy.

---

## 6. Tahmini Süre
- Backend ~0.5 gün, Frontend ~0.5 gün, PM ~0.25 gün → **~1.25 iş günü**

---

## 7. Açık Sorular / PM Kararları (24 May 2026)
- (1) Aile: **kişiseli sıfırla, aileye dokunma** + kullanıcının SharedExpense katkıları silinip SharedBudget.spent recompute. ✅ karar
- (2) Onay: **yazarak "SIFIRLA"** (EN'de "RESET"). ✅ karar
- (3) Kategoriler (sistem + özel) **korunur** (config + FK güvenliği). ✅ PM kararı
- (4) Profil + tercihler + avatar + FCM token **korunur**; user oturumda kalır. ✅ PM kararı
- (5) Fiş görselleri disk'ten **silinir**. ✅ PM kararı
