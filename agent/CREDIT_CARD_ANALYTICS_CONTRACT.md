# Credit Card Analytics Contract — Kredi Kartı Hesap Semantiği

> **Bu dosya neden var?** Sprint 12 smoke test sonunda fark edilen kavramsal hata: kredi kartı hesap detayında "Gelir" istatistiği gösterilmesi. Kredi kartı bir borç hesabıdır — gelir kavramı anlamsız. Bu mini sprint (12.5) kredi kartı semantiğini hem backend (analytics + validation) hem frontend (UI) tarafında tutarlı hale getirir.
>
> **PM (proje yöneticisi rolündeki Opus) yazar; backend + frontend dev session'ları bu sözleşmeye uyar.**

---

## 0. Sprint Hedefi

Kredi kartı hesabı için:
1. Analytics endpoint kavramsal olarak doğru veri döner (Gelir/Gider yerine Harcama/Ödeme).
2. Backend Transaction validation: `type=INCOME` + `account.type=CREDIT_CARD` kombinasyonu **reject** edilir (400).
3. Frontend hesap detayında "Bu Ay" + 6 aylık chart kredi kartı için doğru semantikle render edilir.

**Out of scope:**
- TRANSFER mekanizmasının kendisini değiştirmek (zaten var).
- Mevcut yanlış INCOME kayıtlarını migrate / temizleme (closed test'teyiz, kullanıcı verisi az; gerekirse manuel temizlik).
- Diğer hesap tiplerinin analytics davranışını değiştirme (sadece CREDIT_CARD'a şartlı dal).

---

## 1. Kavramsal Model

Kredi kartı = **borç hesabı**. Tek yönlü:
- **Kart harcaması** → `Transaction { type: EXPENSE, accountId: card.id }` — kart bakiyesi negatife gider, borç birikir
- **Kart borcu ödeme** → `Transaction { type: TRANSFER, fromAccountId: bank.id, toAccountId: card.id }` — banka azalır, kart bakiyesi sıfıra/pozitife yaklaşır
- **INCOME → card** → **anlamsız**, sistem reject etmeli

Sonuç olarak kredi kartı istatistiklerinde iki kavram:
| Kavram | Hesaplama (Transaction filter) |
|---|---|
| **Harcama** (Spend) | `type=EXPENSE AND accountId=card.id` |
| **Ödeme** (Payment) | `type=TRANSFER AND toAccountId=card.id` |

> Mevcut "Gelir" hesaplaması (`type=INCOME AND accountId=card.id`) kaldırılır — kredi kartı için 0 dönüyordu zaten (kullanıcı INCOME yazmazsa); yazdıysa veri kirliliği. Validation bunu engelleyecek.

---

## 2. Backend Değişiklikleri

### 2.1 `AccountsService.getAnalytics`

Hesap tipine göre şartlı dal:

```typescript
async getAnalytics(userId: string, id: string) {
  const account = await this.findOwned(userId, id);
  // ...
  const isCreditCard = account.type === 'CREDIT_CARD';

  const monthlyData = await Promise.all(
    Array.from({ length: 6 }, (_, i) => {
      // ...
      return Promise.all([
        isCreditCard
          ? this.prisma.transaction.aggregate({
              where: {
                toAccountId: id,
                type: 'TRANSFER',
                transactionDate: { gte: start, lte: end },
              },
              _sum: { amount: true },
            })
          : this.prisma.transaction.aggregate({
              where: { accountId: id, type: 'INCOME', transactionDate: { gte: start, lte: end } },
              _sum: { amount: true },
            }),
        this.prisma.transaction.aggregate({
          where: { accountId: id, type: 'EXPENSE', transactionDate: { gte: start, lte: end } },
          _sum: { amount: true },
        }),
      ]).then(([primary, exp]) => ({
        month: date.toISOString().slice(0, 7),
        // Kredi kartı: primary = payment, expense = spend
        // Diğer: primary = income, expense = expense
        ...(isCreditCard
          ? {
              payment: Number(primary._sum.amount ?? 0),
              spend: Number(exp._sum.amount ?? 0),
            }
          : {
              income: Number(primary._sum.amount ?? 0),
              expense: Number(exp._sum.amount ?? 0),
            }),
      }));
    }),
  );

  // topCategories filter aynı: EXPENSE — kredi kartında da harcama kategorileri gösterilir
  // ... (mevcut kod korunur)

  return { months: monthlyData, topCategories, isCreditCard };
}
```

> **Response kontratı:**
> - Standart hesap: `months: [{ month, income, expense }]` (mevcut)
> - Kredi kartı: `months: [{ month, payment, spend }]`
> - Top-level: yeni `isCreditCard: boolean` alanı (frontend'in hangi şemayı parse edeceğini bilmesi için)

### 2.2 Transaction validation

`TransactionsService.create` ve `update`'te şu kontrol eklenir:

```typescript
if (dto.type === 'INCOME' && account.type === 'CREDIT_CARD') {
  throw new BadRequestException(
    'Kredi kartı hesabına gelir kaydedilemez. Kart borcu kapatmak için hesaplar arası transfer kullanın.',
  );
}
```

> `update`'te eğer kullanıcı transaction'ı INCOME'a çevirip aynı zamanda accountId'yi kredi karta değiştiriyorsa: yeni account + yeni type kombinasyonuyla kontrol et (yani `effectiveType` ve `effectiveAccount` üzerinden).

### 2.3 Test güncellemeleri

- `accounts.service.spec.ts`: `getAnalytics` kredi kartı için `payment` + `spend` döner; standart için `income` + `expense` döner (test her ikisini de assert eder).
- `transactions.service.spec.ts`: yeni unit test — `INCOME` + CREDIT_CARD account → 400 throw.

---

## 3. Frontend Değişiklikleri

### 3.1 `AccountAnalyticsModel`

```dart
class AccountAnalyticsModel {
  final List<MonthlyEntry> months;
  final List<TopCategoryEntry> topCategories;
  final bool isCreditCard;

  // ...
}

class MonthlyEntry {
  final String month;          // "2026-05"
  final double? income;        // standart hesap
  final double? expense;       // standart + kredi kartı (kredi kartında "spend" semantiği)
  final double? payment;       // kredi kartı
  final double? spend;         // kredi kartı (expense ile aynı, ayrı isim semantik tutarlılığı için)

  // Yardımcı getter'lar — UI hangi alana bakacağını isCreditCard ile karar verir.
}
```

> Sade alternatif: `MonthlyEntry { month, primaryAmount, secondaryAmount }` + üst seviye `isCreditCard` flag'i ile UI etiketleri belirler. Backend dev session'la uyumluysa bunu da yapabiliriz; PM kararı: backend kontratındaki ayrı alan isimleri (`income/expense` vs `payment/spend`) korunsun — tip güvenliği daha iyi.

### 3.2 `ThisMonthSection`

`account.type == CREDIT_CARD` ise:
- Sol chip: "Ödeme" — `analytics.currentMonthPayment` — `AppColors.secondary` (mint, pozitif), ikon `arrow_downward_rounded`
- Sağ chip: "Harcama" — `analytics.currentMonthSpend` — `AppColors.tertiary` (turuncu, gider), ikon `arrow_upward_rounded`

Diğer hesap tipleri için mevcut "Gelir / Gider" davranışı korunur.

`currentMonthIncome` / `currentMonthExpense` getter'ları model'de kalır (standart için); ek olarak `currentMonthPayment` / `currentMonthSpend` getter'ları (kredi kartı için).

### 3.3 `MonthlyChartSection`

Aynı şartlı render:
- Standart: income bar + expense bar (mevcut)
- Kredi kartı: payment bar + spend bar (etiketler "Ödeme" / "Harcama", renkler aynı semantikte)

### 3.4 l10n stringleri

Yeni TR + EN:
- "Ödeme" / "Payment"
- "Harcama" / "Spend" (mevcut "expense" kullanılabilir veya ayrı yeni string — UX kararı dev'e)

### 3.5 AddTransactionPage (varsa) — kullanıcı UX

INCOME tipli transaction oluştururken kredi kartı hesabı seçeneklerden çıkar veya disabled olur + tooltip. Backend zaten 400 dönecek, ama UI'da önceden engellemek hata yüzeyini azaltır.

> Bu opsiyonel — eğer bu sprint kapsamına sığmıyorsa atlanabilir, backend 400 yeterli (snackbar gösterilir).

---

## 4. Test Senaryoları

### Backend
- ✅ Kredi kartı `getAnalytics` → `months[i].payment` + `months[i].spend` döner, `income`/`expense` yok
- ✅ Standart hesap `getAnalytics` → mevcut davranış, `income` + `expense` döner
- ✅ Top-level `isCreditCard` flag doğru set
- ✅ POST transaction `INCOME` + CREDIT_CARD → 400
- ✅ PATCH transaction type=INCOME + accountId=card → 400
- ✅ TRANSFER → kredi kartı → analytics `payment` toplamına yansıyor

### Frontend
- ✅ Kredi kartı detayında `ThisMonthSection` "Ödeme / Harcama" chip'leri
- ✅ Standart hesap detayında "Gelir / Gider" (regression koruması)
- ✅ Kredi kartı 6 aylık chart'ta payment + spend bar'ları
- ✅ Analytics model `isCreditCard` true ise hangi alanların parse edildiği assert

---

## 5. Sıra ve Bağımlılık

1. **Backend dev session:**
   - `AccountsService.getAnalytics` şartlı dal + response şeması
   - Transaction validation (INCOME + CREDIT_CARD reject)
   - Spec'ler
   - Lokal test
2. **Frontend dev session (paralel başlayabilir):**
   - Model güncelle (`isCreditCard`, yeni alanlar)
   - Widget şartlı render
   - l10n
   - Mock'lu test, backend hazır olunca integration

3. **PM:** Integration smoke test (kredi kartı oluştur → harcama yap → borç öde TRANSFER → analytics doğru) → Railway deploy

---

## 6. Tahmini Süre

- Backend: ~0.5 gün
- Frontend: ~0.5 gün
- PM koordinasyon + deploy: ~0.25 gün
- **Toplam: ~1-1.25 iş günü**
