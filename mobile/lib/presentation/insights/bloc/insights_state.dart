import '../../../data/models/insight_model.dart';

sealed class InsightsState {
  const InsightsState();
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  const InsightsLoaded({required this.insights, this.period});
  final List<InsightModel> insights;
  final String? period;
}

class InsightsError extends InsightsState {
  const InsightsError(this.message);
  final String message;
}

class InsightsSummaryLoading extends InsightsState {
  const InsightsSummaryLoading();
}

class InsightsSummaryLoaded extends InsightsState {
  const InsightsSummaryLoaded({required this.summary});
  final InsightSummaryModel summary;
}

class InsightsSummaryError extends InsightsState {
  const InsightsSummaryError(this.message);
  final String message;
}

class InsightDismissing extends InsightsState {
  const InsightDismissing({required this.insightId});
  final String insightId;
}

class InsightDismissed extends InsightsState {
  const InsightDismissed({
    required this.insightId,
    required this.insights,
  });
  final String insightId;
  final List<InsightModel> insights;
}

class InsightReadMarked extends InsightsState {
  const InsightReadMarked({required this.insights});
  final List<InsightModel> insights;
}

class InsightsGenerating extends InsightsState {
  const InsightsGenerating();
}

class InsightsGenerated extends InsightsState {
  const InsightsGenerated({required this.generated, required this.period});
  final int generated;
  final String period;
}

class InsightsGenerateError extends InsightsState {
  const InsightsGenerateError(this.message);
  final String message;
}
