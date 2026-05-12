class InsightRuleId {
  InsightRuleId._();

  static const spendingSpike = 'spending_spike';
  static const unusedSubscription = 'unused_subscription';
  static const categoryOverrun = 'category_overrun';
  static const recurringDrift = 'recurring_drift';
  static const debtAging = 'debt_aging';
  static const inflationGap = 'inflation_gap';
  static const savingStreak = 'saving_streak';
}

enum InsightSeverity { info, warning, success }
