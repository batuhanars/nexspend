import { BudgetPeriod } from '@prisma/client';

/// ISO tarih string'ini timezone-safe Date object'e çevirir.
/// "YYYY-MM-DD" ve "YYYY-MM-DDTHH:mm:ss..." formatlarını kabul eder; her zaman
/// gün bileşenini koruyarak UTC noon'a normalize eder. Hangi timezone'da olursa
/// olsun gün kaymaz.
/// Sebep: `new Date("2026-05-21")` JS davranışı UTC midnight üretir, MariaDB
/// local TZ'ye (örn. TR = +3) çevirip @db.Date'e yanlış gün yazar.
export function parseLocalDate(s: string): Date {
  const match = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!match) {
    throw new Error(`Geçersiz tarih formatı: "${s}". Beklenen: YYYY-MM-DD veya ISO datetime.`);
  }
  const [, y, m, d] = match;
  return new Date(Date.UTC(Number(y), Number(m) - 1, Number(d), 12, 0, 0));
}

/// startDate dahil, endDate dahil. ('gte' / 'lte' aralığı)
/// UTC operasyonları kullanır — input timezone-safe Date object olmalı (parseLocalDate çıktısı).
export function computeEndDate(startDate: Date, period: BudgetPeriod): Date {
  const end = new Date(startDate);
  switch (period) {
    case 'WEEKLY':
      end.setUTCDate(end.getUTCDate() + 7);
      break;
    case 'MONTHLY':
      end.setUTCMonth(end.getUTCMonth() + 1);
      break;
    case 'YEARLY':
      end.setUTCFullYear(end.getUTCFullYear() + 1);
      break;
  }
  end.setUTCDate(end.getUTCDate() - 1);
  return end;
}
