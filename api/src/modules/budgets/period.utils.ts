import { BudgetPeriod } from '@prisma/client';

/// ISO tarih string'ini ("YYYY-MM-DD") timezone-safe Date object'e çevirir.
/// UTC noon olarak parse eder; hangi timezone'da olursa olsun günün kaymasını engeller.
/// `new Date("2026-05-21")` JS davranışı UTC midnight oluşturur → local TZ'ye
/// (örn. TR = +3) çevrilince bir önceki güne kayabilir + @db.Date kolonuna
/// yanlış gün yazılır. parseLocalDate bu sorunu çözer.
export function parseLocalDate(s: string): Date {
  const [y, m, d] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 12, 0, 0));
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
