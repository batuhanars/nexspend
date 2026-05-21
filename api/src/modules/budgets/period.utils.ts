import { BudgetPeriod } from '@prisma/client';

/// startDate dahil, endDate dahil. ('gte' / 'lte' aralığı)
export function computeEndDate(startDate: Date, period: BudgetPeriod): Date {
  const end = new Date(startDate);
  switch (period) {
    case 'WEEKLY':
      end.setDate(end.getDate() + 7);
      break;
    case 'MONTHLY':
      end.setMonth(end.getMonth() + 1);
      break;
    case 'YEARLY':
      end.setFullYear(end.getFullYear() + 1);
      break;
  }
  end.setDate(end.getDate() - 1);
  return end;
}
