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
@Cron('30 0 * * *') // 09:10 → 00:30'a çekilir (dönem bittiği gün hemen arşivlensin)
async run() {
  this.logger.log('Bütçe dönem sonu kontrolü başladı');
  const archiveStats = await this.budgetsService.archiveExpired();
  this.logger.log(
    `Arşivleme — kişisel: ${archiveStats.personal}, ortak: ${archiveStats.shared}`,
  );
  // Var olan davranış devam eder:
  await this.budgetsService.recomputeAllActive();
}
```

> Cron saatini değiştirmek istemiyorsak (mevcut 09:10), arşivleme akşam saatlerine kalır. Önerilen: **00:30'a çek** — kullanıcı sabah uygulamayı açtığında "bütçen kapandı, yenisini ister misin?" bildirimi hazır olsun.

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

**Kişisel bütçe arşivlendi** (sahibine 1 bildirim):

| Durum | Başlık | Gövde |
|---|---|---|
| Aşılmamış | "Bütçe dönemi kapandı" | "[Bütçe Adı]: 4.500₺/5.000₺ ile bitirdin. Yeni dönem için yenisini oluşturmak ister misin?" |
| Aşılmış | "Bütçe dönemi kapandı (aşıldı)" | "[Bütçe Adı]: 5.500₺/5.000₺ — %110 ile kapandı. Yeni dönem için tutarı ayarlamak ister misin?" |

**Ortak bütçe arşivlendi** (grubun **tüm üyelerine** bildirim):

| Durum | Başlık | Gövde |
|---|---|---|
| Aşılmamış | "Ortak bütçe kapandı" | "[Grup · Bütçe Adı]: 8.200₺/10.000₺ ile bitti. Grup için yenisini oluşturabilirsin." |
| Aşılmış | "Ortak bütçe aşıldı" | "[Grup · Bütçe Adı]: 11.500₺/10.000₺ — %115. Yeni dönem için tutarı tekrar düşün." |

> Ortak bütçe için "kim oluşturur" sınırlaması Sprint 11'de yok — grup üyesi herkes ortak bütçe yaratabiliyor. Bu sprint'te de aynı davranış: bildirim tüm üyelere gider, oluşturma kararı grup içi.

### 3.4 Deep link payload

Bildirime tıklama → `AddBudgetPage` veya `AddSharedBudgetPage` **prefilled** açılır. Frontend `data.closedBudgetId` ile eski kaydı `GET /api/budgets/:id` (veya shared) çağırır ve form'u doldurur:

| Alan | Değer | Düzenlenebilir? |
|---|---|---|
| `name` | Eski isim | Evet |
| `categoryId` | Eski kategori | Evet |
| `amount` | Eski son tutar | Evet (genelde burada değiştirir) |
| `period` | Eski period | Evet |
| `startDate` | Eski `endDate + 1 gün` | Evet |
| `smartTracking` | Eski değer | Evet |

> Kullanıcı **hiçbir şeyi** değiştirmeden "Kaydet" diyebilir — tek dokunuş yenileme.

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

### 5.4 "Yeni dönem oluştur" CTA

Arşivlenmiş bütçenin detayında (Bu Dönem tab'ı aslında en son arşiv) prominent buton:
- Kişisel: "Yeni Dönem Aç" → `AddBudgetPage` prefilled (eski kayıt verisi)
- Ortak: "Yeni Dönem Aç" → `AddSharedBudgetPage` prefilled (grup içinde)

Aynı CTA bildirim tıklamasından da tetiklenir (§3.4 deep link).

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

`NotificationService` `BUDGET_CLOSED` type'ı:
- **Foreground:** SnackBar + "Yenisini Aç" butonu → prefilled AddBudgetPage
- **Background tap:** GoRouter ile prefilled AddBudgetPage
- **Cold start:** pending closedBudgetId mekanizması (Insights pattern'i)

---

## 6. Test Senaryoları

### 6.1 Backend unit (`budgets.service.spec.ts`)

- ✅ `archiveExpired` boş listeyle 0 işler
- ✅ Süresi geçmiş 3 kişisel + 2 ortak bütçe → tümü `isActive=false`
- ✅ Süresi geçmemiş bütçeye dokunmaz
- ✅ Bildirim formatı: aşılmamış vs aşılmış mesaj farklı
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
- ✅ "Yeni Dönem Aç" CTA AddBudgetPage'i doğru prefill ile açar
- ✅ Bildirim tap → cold start dahil doğru sayfaya yönlendirir

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

## 8. Açık Sorular — PM Karar Vermeli

1. **Cron saati:** 00:30 vs mevcut 09:10? Önerilen: **00:30**, sabah bildirimi hazır olsun.
2. **Ortak bütçe arşiv bildirimi:** Tüm grup üyelerine mi yoksa sadece bütçeyi oluşturan kullanıcıya mı? Önerilen: **tüm üyeler** — herkes haberdar olmalı, oluşturma kararı grup içi.
3. **Geçmiş limiti:** History endpoint'i max kaç dönem döner? Önerilen: **son 12 dönem** (1 yıllık aylık için 12 ay, haftalık için ~3 ay yeterli).

---

## 9. Tahmini Süre

- Backend dev: ~1 gün (migration + cron archive + history endpoint + bildirim + test)
- Frontend dev: ~1 gün (model + utils + history tab + prefilled CTA + notif handler)
- PM koordinasyon + deploy: ~0.5 gün
- **Toplam: ~2-2.5 iş günü**
