import '../../../data/models/inflation_model.dart';

sealed class InflationState {
  const InflationState();
}

class InflationInitial extends InflationState {
  const InflationInitial();
}

class InflationSuggestionsLoading extends InflationState {
  const InflationSuggestionsLoading();
}

class InflationSuggestionsLoaded extends InflationState {
  const InflationSuggestionsLoaded({required this.suggestions});
  // budgetId → suggestion (null means 204 — no suggestion)
  final Map<String, InflationSuggestionModel?> suggestions;
}

class InflationSuggestionsError extends InflationState {
  const InflationSuggestionsError(this.message);
  final String message;
}

class InflationApplying extends InflationState {
  const InflationApplying({required this.budgetId});
  final String budgetId;
}

class InflationApplied extends InflationState {
  const InflationApplied({required this.budgetId});
  final String budgetId;
}

class InflationApplyError extends InflationState {
  const InflationApplyError(this.message);
  final String message;
}

class InflationReportLoading extends InflationState {
  const InflationReportLoading();
}

class InflationReportLoaded extends InflationState {
  const InflationReportLoaded({
    required this.comparison,
    required this.history,
  });
  final InflationComparisonModel comparison;
  final Map<String, List<InflationRateModel>> history;
}

class InflationReportError extends InflationState {
  const InflationReportError(this.message);
  final String message;
}
