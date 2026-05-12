sealed class InsightsEvent {
  const InsightsEvent();
}

class InsightsFetchRequested extends InsightsEvent {
  const InsightsFetchRequested({this.period});
  final String? period;
}

class InsightsSummaryFetchRequested extends InsightsEvent {
  const InsightsSummaryFetchRequested();
}

class InsightsMarkReadRequested extends InsightsEvent {
  const InsightsMarkReadRequested({required this.insightId});
  final String insightId;
}

class InsightsDismissRequested extends InsightsEvent {
  const InsightsDismissRequested({required this.insightId});
  final String insightId;
}

class InsightsGenerateRequested extends InsightsEvent {
  const InsightsGenerateRequested();
}

class InsightsMarkAllReadRequested extends InsightsEvent {
  const InsightsMarkAllReadRequested();
}
