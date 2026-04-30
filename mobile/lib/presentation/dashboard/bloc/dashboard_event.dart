part of 'dashboard_bloc.dart';

abstract class DashboardEvent {
  const DashboardEvent();
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested();
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
