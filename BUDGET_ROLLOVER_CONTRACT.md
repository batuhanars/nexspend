# Budget Rollover Contract — Aylık/Haftalık/Yıllık Bütçe Dönem Yönetimi

> **Bu dosya neden var?** Backend ve frontend dev session'ları tek doğruluk kaynağından çalışsın diye. PM (proje yöneticisi rolündeki Opus) yazar; iki dev session da kendi tarafını implemente ederken bu sözleşmeye uyar.
>
> **Değiştirme kuralı:** Bu dosya implementasyon sırasında değişirse → PM güncelleyip ilgili session'a haber verir. Tek taraflı sapma yasak.
>
> **Kapsam:** V1+V2 Budget + SharedBudget modüllerine retroaktif eklenen dönem yönetimi katmanı. Sprint 4 (Bütçeler) ve Sprint 11 (Ortak Bütçe) üstüne kurulur.

---

## 0. Sprint Hedefi

Bütçeler şu an `endDate=null` ile sonsuz açık kalıyor — `period=MONTHLY` davranışsız bir etiket. Bu sprint:

1. Her bütçeye `endDate` zorunlu hale getirilir (period + startDate'ten hesaplanır).
2. Cron her gece dönemi biten bütçeleri arşivler ve bir sonraki dönemi otomatik açar.
3. Aynı "mantıksal" bütçenin dönemleri `seriesId` ile bağlanır → geçmiş raporlama.
4. Frontend'de bütçe detayında "Geçmiş" tab'ı → dönem dönem karşılaştırma.

**Out of scope:** "Şablon tutarını kalıcı değiştir" UX (kullanıcı her yeni dönem amount'u manuel günceller), birden fazla dönem geriye kopyalama (cron eksik bıraktığı boşlukları doldurmaz), kapanış raporu kartı (Insights modülü zaten "saving_streak"/"category_overrun" üretiyor).

---

## 1. Veri Modeli Değişiklikleri

### 1.1 Budget tablosuna ekleme

```prisma
model Budget {
  // ... mevcut alanlar
  endDate    DateTime  @map("end_date") @db.Date  // NULLABLE → NOT NULL'a çevrildi
  seriesId   String    @map("series_id") @db.VarChar(36)  // YENİ
  rolledOverFromId String? @map("rolled_over_from_id") @db.VarChar(36)  // YENİ — denetim izi

  // İlişki: opsiyonel self-reference
  rolledOverFrom Budget? @relation("BudgetRollover", fields: [rolledOverFromId], references: [id])
  rollovers      Budget[] @relation("BudgetRollover")

  @@index([seriesId, startDate], map: "idx_budget_series_period")
  @@index([endDate, isActive], map: "idx_budget_endDate_active")  // Cron için
}
```

### 1.2 SharedBudget tablosuna aynı ekleme

```prisma
model SharedBudget {
  // ... mevcut alanlar
  endDate         DateTime  @map("end_date") @db.Date  // NULLABLE → NOT NULL
  seriesId        String    @map("series_id") @db.VarChar(36)
  rolledOverFromId String?  @map("rolled_over_from_id") @db.VarChar(36)

  rolledOverFrom SharedBudget? @relation("SharedBudgetRollover", fields: [rolledOverFromId], references: [id])
  rollovers      SharedBudget[] @relation("SharedBudgetRollover")

  @@index([seriesId, startDate], map: "idx_sb_series_period")
  @@index([endDate, isActive], map: "idx_sb_endDate_active")
}
```

### 1.3 Migration adı

```bash
npx prisma migrate dev --name budget_period_lifecycle
```

**Backfill stratejisi (migration script'i):**
- Mevcut tüm Budget + SharedBudget kayıtları için:
  - `seriesId = uuid()` (her kayıt kendi serisinin başı)
  - `rolledOverFromId = null`
  - `endDate` doluysa dokunma; null ise `period` ve `startDate`'ten hesaplanır:
    - `MONTHLY`: `startDate + 1 ay - 1 gün`
    - `WEEKLY`: `startDate + 7 gün - 1 gün`
    - `YEARLY`: `startDate + 1 yıl - 1 gün`
- Closed test'teyiz (üretim kullanıcı yok), data loss riski sıfır — backfill TypeScript raw SQL migration script'i olarak yazılabilir.

> **Önemli:** Closed test sona ermeden bu migration deploy edilmeli. Açık beta veya prod'a geçildiğinde aynı migration daha katı validate edilir.

---

## 2. Sabit Tanımlar

### 2.1 Dönem hesaplama yardımcısı

Backend `api/src/modules/budgets/period.utils.ts` (yeni dosya):

```typescript
import { BudgetPeriod } from '@prisma/client';

/// startDate dahil, endDate dahil (`gte`/`lte` arası).
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

/// Bir sonraki dönemin startDate'i = mevcut endDate + 1 gün.
export function computeNextStartDate(currentEndDate: Date): Date {
  const next = new Date(currentEndDate);
  next.setDate(next.getDate() + 1);
  return next;
}
```

Frontend `mobile/lib/core/utils/budget_period.dart` (yeni dosya): aynı mantığın Dart eşdeğeri (`BudgetPeriod` enum üzerinden). Frontend kullanıcı startDate seçtiğinde endDate'i preview olarak gösterir.

### 2.2 Tutar mirası kuralı

Cron yenileme yeni dönem oluştururken `amount` değerini **eski dönemden** kopyalar:
- Kullanıcı bu ay 5000₺'yi 6000₺'ye çekti → cron ay sonunda yeni dönemde **6000₺** açar (en son yürürlükteki tutar).
- Hayır, "ilk dönem amount'u" template değildir — pragmatik tercih: kullanıcı tutarı değiştiriyorsa yeni durum kalıcıdır.

> ⚠️ **PM notu:** İlk konuşmada "sadece bu dönemi değiştirir" denmişti, ama düşününce: kullanıcı amount'u artırırsa muhtemelen "kalıcı artırıyorum" niyetindedir; sıradaki ay tutarı geri çekmek sürpriz olur. **Cron'un kuralı: yeni dönem amount = bir önceki dönemin son amount değeri.** Eğer kullanıcı geçmişe dönüş istiyorsa edit ile düşürür.

### 2.3 isActive yaşam döngüsü

- `isActive=true` + `endDate >= today`: aktif, harcama yansıyor
- `isActive=true` + `endDate < today`: cron'un işlemediği güncel olmayan kayıt (1 günlük buffer yakalanır)
- `isActive=false`: arşiv, harcama hesaba katılmıyor, geçmiş raporda görünüyor

---

## 3. Backend — Cron Job

### 3.1 BudgetRolloverJob (yeni dosya)

`api/src/modules/budgets/jobs/budget-rollover.job.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { BudgetsService } from '../budgets.service';

@Injectable()
export class BudgetRolloverJob {
  private readonly logger = new Logger(BudgetRolloverJob.name);
  constructor(private readonly budgetsService: BudgetsService) {}

  @Cron('30 0 * * *') // Her gün 00:30 (BudgetDailyCheckJob 09:10'dan önce çalışır)
  async run() {
    this.logger.log('Bütçe rollover işlemi başladı');
    const stats = await this.budgetsService.processRollovers();
    this.logger.log(
      `Rollover tamamlandı — kişisel: ${stats.personal}, ortak: ${stats.shared}, hata: ${stats.errors}`,
    );
  }
}
```

### 3.2 BudgetsService.processRollovers

```typescript
async processRollovers(): Promise<{ personal: number; shared: number; errors: number }> {
  const today = startOfDayUtc(new Date()); // 00:00 UTC
  let personal = 0, shared = 0, errors = 0;

  // Kişisel bütçeler
  const expired = await this.prisma.budget.findMany({
    where: { isActive: true, endDate: { lt: today } },
  });
  for (const b of expired) {
    try {
      await this.rolloverPersonal(b);
      personal++;
    } catch (err) { this.logger.error(err); errors++; }
  }

  // Ortak bütçeler
  const sharedExpired = await this.prisma.sharedBudget.findMany({
    where: { isActive: true, endDate: { lt: today } },
  });
  for (const b of sharedExpired) {
    try {
      await this.rolloverShared(b);
      shared++;
    } catch (err) { this.logger.error(err); errors++; }
  }

  return { personal, shared, errors };
}
```

### 3.3 rolloverPersonal — atomic transaction

```typescript
private async rolloverPersonal(old: Budget): Promise<Budget> {
  return this.prisma.$transaction(async (tx) => {
    // 1. Eskiyi arşivle
    await tx.budget.update({
      where: { id: old.id },
      data: { isActive: false },
    });

    // 2. Yeniyi oluştur
    const newStart = computeNextStartDate(old.endDate);
    const newEnd = computeEndDate(newStart, old.period);
    const newBudget = await tx.budget.create({
      data: {
        userId: old.userId,
        categoryId: old.categoryId,
        name: old.name,
        amount: old.amount,                    // Son tutarı koru
        spent: 0,
        period: old.period,
        note: old.note,
        smartTracking: old.smartTracking,
        isActive: true,
        startDate: newStart,
        endDate: newEnd,
        seriesId: old.seriesId,                // Aynı seri
        rolledOverFromId: old.id,              // Denetim izi
      },
    });

    // 3. Bildirim (fire-and-forget, transaction dışı await edilmez)
    setImmediate(() => this.notifyRollover(old, newBudget).catch(() => {}));
    return newBudget;
  });
}
```

`rolloverShared` aynı yapı, `prisma.sharedBudget` üzerinde + grup üyelerinin **tümüne** bildirim.

### 3.4 Bildirim formatı

`NotificationService` üzerinden FCM, `data:{type:'BUDGET_ROLLOVER', budgetId:newId, seriesId}`:

| Senaryo | Başlık | Gövde |
|---|---|---|
| Kişisel, %100 altı | "Yeni dönem başladı" | "[Bütçe Adı]: önceki dönemi 4.500₺/5.000₺ ile kapattın. Yeni dönem başladı." |
| Kişisel, %100 üstü | "Bütçeni aştın" | "[Bütçe Adı]: önceki dönemi 5.500₺/5.000₺ ile kapattın (%110). Yeni dönem başladı." |
| Ortak (her üyeye) | "Ortak bütçe yenilendi" | "[Grup · Bütçe Adı]: önceki dönem 8.200₺/10.000₺. Yeni dönem başladı." |

Bildirime tıklama → `wallet://budgets/<newBudgetId>` (kişisel) veya `wallet://family/<groupId>/budgets/<newBudgetId>` (ortak).

---

## 4. Backend — Endpoint Değişiklikleri

### 4.1 Mevcutlar (davranış değişikliği)

| Endpoint | Değişiklik |
|---|---|
| `POST /api/budgets` | DTO'da `endDate` artık opsiyonel ama backend doluysa kullanır, yoksa `computeEndDate(startDate, period)` ile set eder. `seriesId` yoksa yeni UUID üretir. |
| `PATCH /api/budgets/:id` | Sadece **aktif** dönemi günceller (varsayılan). Geçmiş döneme PATCH 400 döner. |
| `GET /api/budgets` | Varsayılan filtre: `isActive=true`. Yeni query: `?includeArchived=true` |
| `POST /api/family/groups/:id/budgets` | Aynı kurallar |

### 4.2 Yeni endpoint'ler

```
GET /api/budgets/:id/history
  → Aynı seriesId'deki tüm dönemler, eskiden yeniye, isActive dahil.
  → Response: [{ id, startDate, endDate, amount, spent, isActive, percentage }, ...]

GET /api/family/groups/:groupId/budgets/:id/history
  → SharedBudget muadili
```

### 4.3 Hata durumları

- `PATCH /api/budgets/:id` arşiv kayıt → `400 Bad Request`, message: `"Geçmiş döneme ait bütçe düzenlenemez"`.
- `DELETE /api/budgets/:id` aktif kayıt → tüm seri silinir mi yoksa sadece aktif mi? **Karar: sadece bu dönem silinir, seri devam eder.** Tüm seriyi silmek için `DELETE /api/budgets/series/:seriesId` ayrı endpoint (sadece kullanıcı isterse).

> ⚠️ Bu kararı doğrula: kullanıcı bir bütçeyi sildiğinde tüm seri mi gitmeli? Tek dönem silmek mantıksız olur — ileride seri silme zorunlu hale gelebilir.

---

## 5. Frontend — UI Değişiklikleri

### 5.1 AddBudgetPage / EditBudgetSheet

- Period seçimi sonrası `endDate` artık **kullanıcıya gösterilir** (read-only chip): "31 May 2026'da yenilenecek"
- Frontend `BudgetPeriodUtils.computeEndDate(startDate, period)` ile hesaplar
- Backend bu hesabı doğrulayıp persistlemez (frontend hint, backend kanonik kaynağı)

### 5.2 BudgetDetailPage — "Geçmiş" tab

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
      _CurrentPeriodView(budget),   // Mevcut detay (özet kart + grafik + işlem listesi)
      _HistoryView(seriesId: budget.seriesId), // YENİ
    ]),
  ),
);
```

`_HistoryView` içeriği:
- Üstte mini bar chart (son 6-12 dönem: tutar vs harcama yan yana)
- Altında liste: her dönem için `{period label, amount, spent, %, statusColor}`
- Dönem kartına dokunmak → o döneme özel detay sayfası (read-only mode)

### 5.3 SharedBudgetDetailPage

Aynı pattern: "Bu Dönem" + "Geçmiş" tab'ları.

### 5.4 BudgetsPage liste

- Varsayılan: sadece aktif (`isActive=true`) dönemler. Mevcut davranış zaten bu, değişiklik yok.
- "Geçmiş bütçeler" sayfası ileride (out of scope) — kullanıcı detayda görüyor.

### 5.5 Frontend BudgetModel + SharedBudgetModel

Yeni alanlar:
```dart
class BudgetModel {
  // ... mevcutlar
  final String seriesId;
  final String? rolledOverFromId;
  final DateTime endDate; // artık zorunlu
}
```

### 5.6 Push notification handling

`NotificationService` `BUDGET_ROLLOVER` type'ı:
- Foreground: snackbar + "Görüntüle" butonu → ilgili budget detay
- Background tap: GoRouter ile budget detay sayfası
- Cold start: pending budgetId mekanizması (Insights pattern'i)

---

## 6. Test Senaryoları

### 6.1 Backend unit testleri (`budgets.service.spec.ts`)

- ✅ `processRollovers` boş listeyle 0 işler
- ✅ Süresi geçmiş 3 bütçe → 3 yeni dönem açılır + 3 arşiv
- ✅ Yeni dönem `spent=0`, `seriesId` korunur, `rolledOverFromId` set edilir
- ✅ Transaction içinde hata → rollback (eski dönem isActive=true kalır)
- ✅ %100 altı bütçe → bildirim "Yeni dönem başladı"
- ✅ %100 üstü bütçe → bildirim "Bütçeni aştın"
- ✅ Ortak bütçe rollover → tüm grup üyelerine bildirim

### 6.2 Backend e2e (`test/budget-rollover.e2e-spec.ts`)

- ✅ Bütçe oluştur → endDate otomatik hesaplandı mı
- ✅ `GET /api/budgets/:id/history` aktif + arşiv döner mi, sıralı mı
- ✅ Arşiv bütçeyi PATCH → 400
- ✅ Cron'u manuel tetikle (test helper) → DB state bekleneni gösteriyor

### 6.3 Frontend test'leri

- ✅ `BudgetPeriodUtils.computeEndDate` tüm periodlar için doğru
- ✅ BudgetDetailPage Geçmiş tab'ı seriesId üzerinden veri çekiyor
- ✅ Bildirim tap → GoRouter doğru sayfaya yönlendiriyor

---

## 7. Migration & Deployment

### 7.1 Sıra

1. **Backend dev session:** 
   - schema.prisma güncellenir, migration yazılır, backfill SQL'i migration içinde
   - `budgets.service.ts` + cron job + endpoint'ler
   - Test'ler yeşil
2. **Frontend dev session:**
   - Model genişletme, period utils, history endpoint çağrısı, tab UI
   - Bildirim handling
3. **PM:** Migration'ı Railway'de manuel deploy + monitör (ilk gece cron'unda log incelenir)

### 7.2 Geri alma planı

Eğer cron yanlış dönem açarsa: `isActive` flag'iyle yanlış kayıtları silmeden gizleyebiliriz. seriesId koruduğu için kayıtları çakıştırmadan tekrar çalıştırılabilir (idempotent değil ama düzeltilebilir).

> Cron şu an idempotent değil — aynı gün iki kez çalışırsa duplicate kayıt açar. v1'de günde tek sefer çalışacağı varsayımıyla geçiyoruz; v2'de `seriesId + startDate` unique constraint eklenir.

---

## 8. Açık Sorular — PM Karar Vermeli

1. **DELETE davranışı (§4.3):** Aktif bütçeyi sil → sadece bu dönem mi, tüm seri mi? Önerilen: bu dönem; ayrı endpoint seri silme için.
2. **Edit dönemi geriye kaydırma:** Kullanıcı startDate'i geçmişe çekerse mevcut harcamalar yeniden hesaplanır (event listener zaten yapıyor); endDate'i de yeniden hesaplanmalı mı, kullanıcı manuel mi vermeli?
3. **Boş dönemler:** Kullanıcı 3 ay uygulamayı kullanmadıysa cron geriye dönük 3 boş dönem mi açar yoksa sadece bugünden geçerli bir dönem mi başlatır? Önerilen: sadece bir sonraki dönem (boşluklar history'de gözükmez).

---

## 9. Tahmini Süre

- Backend dev: 1-1.5 gün (migration + cron + endpoint + test)
- Frontend dev: 1 gün (model + period utils + history tab + bildirim)
- PM koordinasyon + deploy: 0.5 gün
- **Toplam: 2.5-3 iş günü**
