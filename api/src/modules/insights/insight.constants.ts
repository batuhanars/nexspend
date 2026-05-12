export const INSIGHT_RULES = [
  'spending_spike',
  'unused_subscription',
  'category_overrun',
  'recurring_drift',
  'debt_aging',
  'inflation_gap',
  'saving_streak',
] as const;

export type InsightRuleId = (typeof INSIGHT_RULES)[number];

export const INSIGHT_SEVERITY_MAP: Record<
  InsightRuleId,
  'info' | 'warning' | 'success'
> = {
  spending_spike: 'warning',
  unused_subscription: 'warning',
  category_overrun: 'warning',
  recurring_drift: 'info',
  debt_aging: 'warning',
  inflation_gap: 'info',
  saving_streak: 'success',
};
