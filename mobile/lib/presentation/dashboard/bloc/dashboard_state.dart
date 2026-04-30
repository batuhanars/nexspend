part of 'dashboard_bloc.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded(this.dashboard);
  final DashboardModel dashboard;
}

class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
}
