sealed class InflationEvent {
  const InflationEvent();
}

class InflationSuggestionsFetchRequested extends InflationEvent {
  const InflationSuggestionsFetchRequested({required this.budgetIds});
  final List<String> budgetIds;
}

class InflationApplyRequested extends InflationEvent {
  const InflationApplyRequested({
    required this.budgetId,
    required this.newAmount,
  });
  final String budgetId;
  final double newAmount;
}

class InflationReportFetchRequested extends InflationEvent {
  const InflationReportFetchRequested({this.period, this.months = 6});
  final String? period;
  final int months;
}
