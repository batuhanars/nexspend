# Budget Lifecycle Contract — Bütçe Dönem Sonu Arşivleme + Geçmiş Raporlama

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya implementasyon sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** V1 + Sprint 11 Budget + SharedBudget modüllerine retroaktif eklenen **dönem sonu arşivleme** + **geçmiş raporlama** + **yeni dönem prefilled CTA**. Otomatik yenileme YOK — kullanıcı niyeti korunur.

---

## 0. Sprint Hedefi

Bütçeler şu an `endDate=null` ile sonsuza dek açık kalıyor — `period=MONTHLY` davranışsız bir etiket. Bu sprint:

1. Her bütçeye (kişisel + ortak) `endDate` zorunlu — period + startDate'ten hesaplanır.
2. Cron her gece dönemi biten bütçeleri **arşivler** (`isActive=false`).
3. Bildirim atılır: "Bütçen kapandı, yenisini oluşturmak ister misin?" → deep link `AddBudgetPage`'i ilgili alanlar dolu açar.
4. Frontend'de bütçe detayında "Geçmiş" tab'ı — aynı kategoride önceki dönem kayıtları görülür, karşılaştırma yapılır.

**Out of scope:**
- **Otomatik yeni dönem yaratma** — kullanıcı manuel oluşturur (bildirim + prefilled CTA yeterli). Her ay aynı bütçeyi otomatik açmak hayalet bütçe sorununa yol açar; kullanıcı niyetini her dönem yeniden ifade etmeli.
- Çoklu dönem geriye doldurma (cron eksik bıraktığı boşlukları yaratmaz).
- "Şablon" kavramı (her bütçe kendi kendine bir kayıt).

---

## 1. Veri Modeli Değişiklikleri

### 1.1 Budget tablosu

```prisma
model Budget {
  // ... mevcut alanlar
  endDate DateTime @map("end_date") @db.Date  // NULLABLE → NOT NULL
  // YENİ alan EKLENMEZ. seriesId YOK; geçmiş kategori bazlı sorgulanır.

  @@index([endDate, isActive], map: "idx_budget_endDate_active")  // Cron için
  @@index([userId, categoryId, endDate], map: "idx_budget_history")  // History için
}
```

### 1.2 SharedBudget tablosu

```prisma
model SharedBudget {
  // ... mevcut alanlar
  endDate DateTime @map("end_date") @db.Date  // NULLABLE → NOT NULL

  @@index([endDate, isActive], map: "idx_sb_endDate_active")
  @@index([groupId, categoryId, endDate], map: "idx_sb_history")
}
```

### 1.3 Migration

```bash
npx prisma migrate dev --name budget_endDate_required
```

**Backfill stratejisi** (migration SQL içinde):
```sql
-- Mevcut MONTHLY/WEEKLY/YEARLY bütçeler için endDate hesapla
UPDATE budgets SET end_date = CASE period
  WHEN 'WEEKLY'  THEN DATE_ADD(start_date, INTERVAL 6 DAY)
  WHEN 'MONTHLY' THEN DATE_SUB(DATE_ADD(start_date, INTERVAL 1 MONTH), INTERVAL 1 DAY)
  WHEN 'YEARLY'  THEN DATE_SUB(DATE_ADD(start_date, INTERVAL 1 YEAR), INTERVAL 1 DAY)
END
WHERE end_date IS NULL;

-- Aynı SQL shared_budgets için tekrarlanır
ALTER TABLE budgets MODIFY end_date DATE NOT NULL;
ALTER TABLE shared_budgets MODIFY end_date DATE NOT NULL;
```

> Closed test'teyiz (üretim kullanıcı yok), destruktif migration güvenli.

---

## 2. Sabit Tanımlar

### 2.1 Dönem hesaplama yardımcısı

Backend `api/src/modules/budgets/period.utils.ts` (yeni dosya):

```typescript
import { BudgetPeriod } from '@prisma/client';

/// startDate dahil, endDate dahil. ('gte' / 'lte' aralığı)
export function computeEndDate(startDate: Date, period: BudgetPeriod): Date {
  const end = new Date(startDate);
  switch (period) {
    case 'WEEKLY':  end.setDate(end.getDate() + 7); break;
    case 'MONTHLY': end.setMonth(end.getMonth() + 1); break;
    case 'YEARLY':  end.setFullYear(end.getFullYear() + 1); break;
  }
  end.setDate(end.getDate() - 1);
  return end;
}
```

Frontend `mobile/lib/core/utils/budget_period.dart`: aynı mantığın Dart eşdeğeri. Kullanıcı startDate seçtiğinde endDate'i preview olarak gösterir ("31 Mayıs 2026'da kapanacak").

### 2.2 Lifecycle kuralları

- `isActive=true` + `endDate >= today` → **aktif**, yeni harcamalar yansır
- `isActive=true` + `endDate < today` → cron'un henüz işlemediği (en fazla bir günlük buffer)
- `isActive=false` → **arşiv**: harcama yansımaz (event listener `isActive=true` filtresine girer), geçmiş tab'da görünür

---

## 3. Backend — Cron Job

### 3.1 BudgetDailyCheckJob güncellemesi

Mevcut `api/src/modules/budgets/jobs/budget-daily-check.job.ts` job'u 09:10'da çalışıyor ve sadece `spent` recompute ediyor. Bu job iki sorumluluğu birden alır:

```typescript
@Cron('30 0 * * *') // Tek job, 00:30 — önce arşivle, sonra aktiflerin spent'ini recompute et
async run() {
  this.logger.log('Bütçe dönem sonu kontrolü başladı');
  const archiveStats = await this.budgetsService.archiveExpired();
  this.logger.log(
    `Arşivleme — kişisel: ${archiveStats.personal}, ortak: ${archiveStats.shared}`,
  );
  // Var olan davranış devam eder (arşivlenenler `isActive=false` olduğu için recompute dışı kalır):
  await this.budgetsService.recomputeAllActive();
}
```

> **Karar (§8/1):** Tek job, **00:30**. `recomputeAllActive` kullanıcıya bildirim atmıyor (eşik bildirimleri zaten `transaction.created` listener'ında, event-driven). Job'ı ikiye bölmek (00:30 archive + 09:10 recalc) gereksiz karmaşa — sıralama tek runda doğal: önce `isActive=false` set edilir, sonra recompute sadece aktiflere çalışır.

### 3.2 BudgetsService.archiveExpired

```typescript
async archiveExpired(): Promise<{ personal: number; shared: number }> {
  const today = startOfDayUtc(new Date()); // 00:00 UTC

  // Kişisel bütçeler
  const expiredPersonal = await this.prisma.budget.findMany({
    where: { isActive: true, endDate: { lt: today } },
    include: { category: true },
  });
  for (const b of expiredPersonal) {
    await this.prisma.budget.update({
      where: { id: b.id },
      data: { isActive: false },
    });
    // Fire-and-forget bildirim
    setImmediate(() =>
      this.notifyPersonalArchive(b).catch((e) => this.logger.error(e)),
    );
  }

  // Ortak bütçeler
  const expiredShared = await this.prisma.sharedBudget.findMany({
    where: { isActive: true, endDate: { lt: today } },
    include: { category: true, group: { include: { members: true } } },
  });
  for (const b of expiredShared) {
    await this.prisma.sharedBudget.update({
      where: { id: b.id },
      data: { isActive: false },
    });
    setImmediate(() =>
      this.notifySharedArchive(b).catch((e) => this.logger.error(e)),
    );
  }

  return { personal: expiredPersonal.length, shared: expiredShared.length };
}
```

> Tek-satır arşivleme. Yeni dönem **yaratılmaz**.

### 3.3 Bildirim formatı

`NotificationService` üzerinden FCM, `data:{type:'BUDGET_CLOSED', closedBudgetId, scope:'personal'|'shared', groupId?}`:

**Kişisel bütçe arşivlendi** (sahibine 1 salt bilgi bildirimi):

| Durum | Başlık | Gövde |
|---|---|---|
| Aşılmamış | "Bütçe dönemi kapandı" | "[Bütçe Adı]: 4.500₺/5.000₺ ile bitirdin." |
| Aşılmış | "Bütçe dönemi kapandı (aşıldı)" | "[Bütçe Adı]: 5.500₺/5.000₺ — %110 ile kapandı." |

**Ortak bütçe arşivlendi** (grubun **tüm üyelerine** salt bilgi bildirimi):

| Durum | Başlık | Gövde |
|---|---|---|
| Aşılmamış | "Ortak bütçe kapandı" | "[Grup · Bütçe Adı]: 8.200₺/10.000₺ ile bitti." |
| Aşılmış | "Ortak bütçe aşıldı" | "[Grup · Bütçe Adı]: 11.500₺/10.000₺ — %115 ile kapandı." |

> **Karar (§8/2 + §8/4):** Hem kişisel hem ortak bütçede bildirim **salt bilgilendirme**. "Yenisini oluştur" CTA'sı **iki tarafta da yok**. Yeni dönem kullanıcı/grup hazır olduğunda normal akıştan (`+ Bütçe Ekle`) oluşturulur. Prefilled CTA flow §8/4 ile geri çekildi.

### 3.4 Deep link payload

**Kişisel bildirim tap'i** → `BudgetDetailPage` (kapanan bütçenin kendi detayı), **"Bu Dönem" tab default açık** (yani kapanan bütçenin kendi verileri: tutar, harcama, %, kategori). Kullanıcı isterse "Geçmiş" tab'ına geçerek aynı kategorideki önceki dönemleri görür. Prefilled form açılmaz.

**Ortak bildirim tap'i** → `SharedBudgetDetailPage` (kapanan bütçenin kendi detayı), **"Bu Dönem" tab default açık**. Aynı davranış.

> **Karar düzeltmesi (21 May, smoke test 3. tur):** İlk kararda "Geçmiş tab default" yazılıydı; ama Geçmiş tab "aynı kategorideki önceki arşivler" listesidir — kapanan bütçe o kategorideki ilk arşiv ise tab boş düşer ve kullanıcı kendi kapanan bütçesinin verilerini hiç göremez. Doğrusu: "Bu Dönem" tab default — kullanıcı arşivlenmiş bütçesinin kendi verilerini görür (artık arşiv olarak), istediğinde Geçmiş tab'ına geçer.

> **Karar (§8/4):** Prefilled CTA akışı geri çekildi. Hem kişisel hem ortak için tap → spesifik bütçe detayı (Geçmiş tab). Sebep: smoke test'te async fetch chain (`getById` + `addPostFrameCallback` + push) timing bug'larına yol açtı (kullanıcı başka bir ekrana tıklarken alakasız yerde AddBudgetPage prefilled açılması). Senkron push akışı bu yüzey'i ortadan kaldırır + UX kişisel/ortak arasında tutarlı kalır.

---

## 4. Backend — Endpoint Değişiklikleri

### 4.1 Mevcutlar (davranış değişikliği)

| Endpoint | Değişiklik |
|---|---|
| `POST /api/budgets` | DTO'da `endDate` opsiyonel kalır; backend doluysa kullanır, yoksa `computeEndDate(startDate, period)` ile set eder |
| `POST /api/family/groups/:id/budgets` | Aynı kural |
| `PATCH /api/budgets/:id` | Sadece **aktif** kayıt güncellenebilir (`isActive=true`). Arşiv kayıt → 400, message: `"Geçmiş döneme ait bütçe düzenlenemez"` |
| `PATCH /api/family/.../budgets/:id` | Aynı kural |
| `GET /api/budgets` | Varsayılan filtre: `isActive=true`. Yeni query param: `?includeArchived=true` |
| `GET /api/family/groups/:id/budgets` | Aynı kural |

### 4.2 Yeni endpoint'ler

```
GET /api/budgets/:id/history
  → Aynı userId + categoryId, endDate < bu kaydın startDate.
  → Sıralama: endDate DESC (en yeni geçmiş başta).
  → Response: [{ id, name, startDate, endDate, amount, spent, percentage, isActive }, ...]
  → Limit: son 12 dönem (frontend chart için yeterli).

GET /api/family/groups/:groupId/budgets/:id/history
  → SharedBudget muadili: aynı groupId + categoryId.
```

> Geçmiş, **kategori bazlı** sorgulanır — `seriesId` yok. Kullanıcı kategoriyi farklılaştırırsa (örn. "Market" → "Süpermarket") yeni seri başlar. Bu kabul edilen bir trade-off: schema sade.

### 4.3 Hata durumları

- `DELETE /api/budgets/:id` aktif veya arşiv — fark etmez, sadece o kayıt silinir. Geçmiş etkilenmez (history zaten o kategoride başka kayıtlardan gelir).

---

## 5. Frontend — UI Değişiklikleri

### 5.1 AddBudgetPage / EditBudgetSheet

- Period seçildikten sonra `endDate` **read-only chip** olarak gösterilir: "Bu dönem 31 Mayıs 2026'da kapanacak"
- Frontend `BudgetPeriodUtils.computeEndDate(startDate, period)` ile hesaplar
- Backend kanonik kaynak; frontend hint olarak gösterir

### 5.2 BudgetDetailPage — "Geçmiş" tab (kişisel)

Mevcut Scaffold şuna dönüşür:

```dart
DefaultTabController(
  length: 2,
  child: Scaffold(
    appBar: AppBar(
      title: Text(budget.name),
      bottom: TabBar(tabs: [
        Tab(text: 'Bu Dönem'),
        Tab(text: 'Geçmiş'),
      ]),
    ),
    body: TabBarView(children: [
      _CurrentPeriodView(budget),                          // Mevcut detay
      _HistoryView(budgetId: budget.id),                   // YENİ
    ]),
  ),
);
```

`_HistoryView` içeriği:
- Üstte mini bar chart (son 6-12 dönem: tutar bar + harcama bar yan yana, aşılan dönemlerde harcama bar'ı renkli)
- Altta liste: her dönem kartı `{period label, amount, spent, %, statusColor}` — dokununca read-only detay
- Boş geçmiş için empty state: "Bu kategoride başka dönem yok"

### 5.3 SharedBudgetDetailPage — aynı tab yapısı

Aynı pattern; `_HistoryView` `groupId + budget.id` ile `GET /api/family/groups/:gid/budgets/:bid/history` çağırır.

### 5.4 "Yeni dönem oluştur" CTA — kaldırıldı

Hem **kişisel** hem **ortak** arşiv detayında bu CTA **YOK** (§8/4). Yeni dönem normal akıştan (`+ Bütçe Ekle`) sıfırdan oluşturulur. Bildirim de salt bilgi (§3.3), prefilled form yok (§3.4).

### 5.5 Frontend model

```dart
class BudgetModel {
  // ... mevcutlar
  final DateTime endDate;  // nullable → non-nullable
}

class SharedBudgetModel {
  // ... mevcutlar
  final DateTime endDate;  // nullable → non-nullable
}

class BudgetHistoryEntry {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final double spent;
  final double percentage;
  final bool isActive;
}
```

### 5.6 Push notification handling

`NotificationService` `BUDGET_CLOSED` type'ı `scope` alanına göre ayrışır, ama hedef davranış iki tarafta **aynı**: salt bilgi + spesifik bütçe detayına (Geçmiş tab) yönlendirme.

**`scope='personal'`** — kişisel:
- **Foreground:** Bilgi SnackBar (CTA action button **yok**)
- **Background tap:** GoRouter ile `BudgetDetailPage` (kapanan bütçenin detayı, **"Bu Dönem" tab default**)
- **Cold start:** pending `closedBudgetId` mekanizması (Insights pattern'i)

**`scope='shared'`** — ortak:
- **Foreground:** Bilgi SnackBar
- **Background tap:** GoRouter ile `SharedBudgetDetailPage` (kapanan bütçenin detayı, **"Bu Dönem" tab default**)
- **Cold start:** pending `closedSharedBudgetId` → detay sayfasına yönlendirir

> **Senkron push gereği (§8/4):** Detay sayfası constructor'ları, model objesi yerine `budgetId` ile de açılabilmeli (model verilmemişse sayfa kendi içinde fetch eder). Bu, notification handler'ı async fetch zincirinden kurtarır → `addPostFrameCallback + push` deterministik kalır → pending consume timing bug'ları yüzey'i ortadan kalkar.
>
> **Pending consume güvenliği (§8/4):** Cold start'ta AppShell mount olmadan pending'in tüketilmemesini sağlamak için: `_consumePending` `mounted=false` durumunda pending'i **geri set etmeli** (consume'u geri al), AppShell mount olunca yeniden tetiklenmeli. Aksi halde sonraki lifecycle resumed event'inde pending consume edilip alakasız yerde navigasyon tetiklenir.

---

## 6. Test Senaryoları

### 6.1 Backend unit (`budgets.service.spec.ts`)

- ✅ `archiveExpired` boş listeyle 0 işler
- ✅ Süresi geçmiş 3 kişisel + 2 ortak bütçe → tümü `isActive=false`
- ✅ Süresi geçmemiş bütçeye dokunmaz
- ✅ Bildirim formatı: aşılmamış vs aşılmış mesaj farklı
- ✅ Kişisel bildirim CTA içerir ("yenisini oluştur"), ortak bildirim salt bilgilendirme — mesaj gövdeleri §3.3 tablosuyla aynı
- ✅ Ortak bütçe arşivinde tüm grup üyelerine bildirim gönderilir
- ✅ Arşivlenmiş bütçeye PATCH → 400
- ✅ Yeni bütçe oluştururken endDate verilmezse auto-compute

### 6.2 Backend e2e (`test/budget-lifecycle.e2e-spec.ts`)

- ✅ Bütçe oluştur, endDate yok → response'ta endDate dolu
- ✅ `GET /api/budgets/:id/history` aynı kategori arşivlerini sıralı döner
- ✅ `?includeArchived=true` ile arşivler de listede
- ✅ Bütçe arşivlendikten sonra yeni harcama yapılsa `spent` artmaz (BudgetListener `isActive=true` filtresine girer)

### 6.3 Frontend

- ✅ `BudgetPeriodUtils.computeEndDate` her period için doğru
- ✅ BudgetDetailPage Geçmiş tab'ı history endpoint'i çağırır
- ✅ Kişisel "Yeni Dönem Aç" CTA AddBudgetPage'i doğru prefill ile açar
- ✅ Ortak detayda "Yeni Dönem Aç" CTA **bulunmaz** (regression koruması)
- ✅ Bildirim tap → kişisel: prefilled AddBudgetPage; ortak: SharedBudgetDetailPage (cold start dahil)

---

## 7. Migration & Deployment

### 7.1 Sıra

1. **Backend dev session:**
   - schema.prisma güncellenir (`endDate` NOT NULL, index'ler)
   - Migration: backfill SQL + sütun tipi değişimi
   - `period.utils.ts` + `archiveExpired` + 2 history endpoint'i
   - `BudgetDailyCheckJob` 00:30'a çekilir, archive akışı eklenir
   - PATCH guard (arşiv kayıt 400)
   - Bildirim payload + deep link data
   - Unit + e2e testler

2. **Frontend dev session:**
   - `BudgetModel` + `SharedBudgetModel` `endDate` non-nullable
   - `BudgetPeriodUtils` Dart helper
   - `AddBudgetPage` endDate chip
   - `BudgetDetailPage` + `SharedBudgetDetailPage` "Geçmiş" tab
   - `_HistoryView` widget + mini chart
   - "Yeni Dönem Aç" CTA + prefill flow
   - `NotificationService` BUDGET_CLOSED handler + GoRouter
   - l10n stringler (TR + EN)

3. **PM:** Migration'ı Railway'de deploy + ilk gece cron (00:30) log incelenir.

### 7.2 Backend & Frontend bağımlılık sırası

- Frontend session modelden başlayıp UI iskeletini yapabilir (mock veriyle), endpoint'ler hazır olmadan da çalışır.
- Backend migration tamamlanmadan e2e test çalışmaz; frontend integration testleri backend deploy sonrası.

### 7.3 Geri alma

Cron yanlış kayıt arşivlerse: `isActive=true` set ederek geri açılabilir, veri kaybı yok. Migration backfill'i hatalıysa: ayrıca `endDate=NULL` set edilemez (NOT NULL constraint), ama UPDATE ile düzeltilir.

---

## 8. Açık Sorular — Kararlar (21 May 2026, PM)

| # | Soru | Karar | Gerekçe |
|---|---|---|---|
| 1 | Cron saati 00:30 mı yoksa mevcut 09:10 mu? Job ikiye mi bölünsün? | **Tek job, 00:30.** `archiveExpired` + `recomputeAllActive` sırasıyla aynı runda. | Job kullanıcıya bildirim atmıyor; eşik bildirimleri zaten event-driven. Sıralama doğal: arşivlenen `isActive=false` olur, recompute sadece aktiflere çalışır. İkiye bölmek gereksiz karmaşa. |
| 2 | Ortak bütçe arşiv bildirimi yalnız oluşturana mı, tüm üyelere mi? Prefilled CTA olsun mu? | **Tüm üyelere salt bilgi.** "Yenisini oluştur" CTA YOK. Tap → `SharedBudgetDetailPage` arşiv detayı. | Yeni dönem grup kararı — sistem tek bir üyeyi tetikleyip bütçe tutarını/kapsamını tek başına belirletmemeli. Üyeler hazır olduğunda normal akıştan sıfırdan açar. |
| 3 | History endpoint'inde max kaç dönem dönsün? | **Son 12 dönem**, period bağımsız. | MONTHLY için 1 yıl tam; WEEKLY için ~3 ay; YEARLY için 12 yıl (yeterinden fazla). MVP için tek sabit limit pratik; period'a göre dinamik limit ileride gerekirse eklenir. |
| 4 | (21 May, smoke test sonrası ek) Kişisel prefilled CTA flow korunsun mu? | **Geri çekildi.** Kişisel tap → `BudgetDetailPage` (Geçmiş tab default). Bildirim CTA içermez (foreground SnackBar dahil). Kişisel + ortak parite. | **UX gerekçesi (asıl):** Prefilled CTA tüm bütçeleri *döngüsel* kabul ediyordu. Oysa bütçelerin önemli bir kısmı **tek seferlik niyet**: tatil bütçesi, taşınma, düğün, doğum günü, sınav hazırlık dönemi… Dönem sonunda "yenisini oluşturmak ister misin?" dürtüsü bu kullanıcılarda yanlış müdahale olur. Bilgi bildirimi + arşivde görme nötr UX sağlar; kullanıcı isterse normal akıştan yeni bir bütçe açar, isterse bırakır. **Teknik gerekçe (ikincil):** Smoke test'te async fetch chain (`getById` + `addPostFrameCallback` + push) timing bug'ı üretti — kullanıcı başka bir ekrana (örn. kredi kartı detayı) tıklarken pending consume geç tetiklendi, alakasız yerde AddBudgetPage prefilled açıldı. Senkron push akışı bu hata yüzeyini de ortadan kaldırır + iki scope arasında tutarlılık sağlar. |
| 5 | (21 May ek) Arşivlenmiş bütçeleri DB seviyesinde ayrı tabloya mı taşıyalım? | **Hayır, mevcut `isActive` soft-delete pattern korunur.** UX ayrımı için Settings altına "Arşivlenmiş Bütçeler" sayfası (`ArchivedBudgetsPage`) eklendi. | DB ayrımı 2-3 ek gün backend rewrite + 142 test revize anlamına gelirdi; mevcut pattern projenin (`accounts` tablosundaki `isArchived`) konvansiyonuyla zaten uyumlu. UX karışıklığı sorunu frontend tarafında daha küçük bir maliyetle çözüldü. |

> Bu kararlar §3.1, §3.3, §3.4, §5.4, §5.6 ve §6'ya işlendi. §8 kapalı.

---

## 9. Tahmini Süre

- Backend dev: ~1 gün (migration + cron archive + history endpoint + bildirim + test)
- Frontend dev: ~1 gün (model + utils + history tab + prefilled CTA + notif handler)
- PM koordinasyon + deploy: ~0.5 gün
- **Toplam: ~2-2.5 iş günü**
