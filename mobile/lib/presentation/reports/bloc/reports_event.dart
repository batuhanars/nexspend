part of 'reports_bloc.dart';

sealed class ReportsEvent {
  const ReportsEvent();
}

class ReportsLoadRequested extends ReportsEvent {
  const ReportsLoadRequested();
}

class ReportsPeriodChanged extends ReportsEvent {
  const ReportsPeriodChanged(this.period);
  final String period;
}
