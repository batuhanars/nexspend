import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/di/injection.dart';
import '../../core/services/notification_service.dart';
import '../../navigation/route_names.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    debugPrint('[AppShell] initState — NotificationService başlatılıyor');
    getIt<NotificationService>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  static const _tabs = [
    _TabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Anasayfa',
      route: RouteNames.home,
    ),
    _TabItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: 'İşlemler',
      route: RouteNames.transactions,
    ),
    _TabItem(
      icon: Icons.pie_chart_outline,
      activeIcon: Icons.pie_chart,
      label: 'Bütçe',
      route: RouteNames.budgets,
    ),
    _TabItem(
      icon: Icons.handshake_outlined,
      activeIcon: Icons.handshake,
      label: 'Borç',
      route: RouteNames.debts,
    ),
    _TabItem(
      icon: Icons.subscriptions_outlined,
      activeIcon: Icons.subscriptions,
      label: 'Abonelik',
      route: RouteNames.subscriptions,
    ),
  ];

  int _currentIndex(String location) {
    if (location.startsWith(RouteNames.home)) return 0;
    if (location.startsWith(RouteNames.transactions)) return 1;
    if (location.startsWith(RouteNames.budgets)) return 2;
    if (location.startsWith(RouteNames.debts)) return 3;
    if (location.startsWith(RouteNames.subscriptions)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: _tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = i == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => context.go(tab.route),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
