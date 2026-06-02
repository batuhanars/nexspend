import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/di/injection.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/coach_mark_keys.dart';
import '../../data/models/family_model.dart' show SharedBudgetModel;
import '../../data/repositories/family_repository.dart';
import '../../navigation/route_names.dart';
import 'banner_ad_widget.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  StreamSubscription<String>? _inviteSub;
  StreamSubscription<({String token, String action})>? _actionSub;
  StreamSubscription<String>? _groupNavSub;
  StreamSubscription<void>? _insightsNavSub;
  StreamSubscription<String>? _personalBudgetClosedSub;
  StreamSubscription<({String budgetId, String groupId})>?
      _sharedBudgetClosedSub;
  StreamSubscription<void>? _consumeTriggerSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    _checkCoachMark();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inviteSub?.cancel();
    _actionSub?.cancel();
    _groupNavSub?.cancel();
    _insightsNavSub?.cancel();
    _personalBudgetClosedSub?.cancel();
    _sharedBudgetClosedSub?.cancel();
    _consumeTriggerSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // onMessageOpenedApp'ın tetiklenmesine kısa süre tanı
      Future.delayed(const Duration(milliseconds: 400), _consumePending);
    }
  }

  void _consumePending() {
    if (!mounted) return;
    final ns = getIt<NotificationService>();

    final inviteToken = ns.consumePendingInvite();
    if (inviteToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.familyInvite(inviteToken));
      });
      return;
    }

    final groupId = ns.consumePendingGroupId();
    if (groupId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.familyGroupDetail(groupId));
      });
      return;
    }

    if (ns.consumePendingInsights()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.insights);
      });
      return;
    }

    final closedBudgetId = ns.consumePendingClosedBudget();
    if (closedBudgetId != null) {
      if (!mounted) {
        ns.restorePendingClosedBudget(closedBudgetId);
        return;
      }
      _openBudgetHistory(closedBudgetId);
      return;
    }

    final closedShared = ns.consumePendingClosedSharedBudget();
    if (closedShared != null) {
      if (!mounted) {
        ns.restorePendingClosedSharedBudget(
          budgetId: closedShared.budgetId,
          groupId: closedShared.groupId,
        );
        return;
      }
      _openSharedBudgetHistory(closedShared.groupId, closedShared.budgetId);
    }
  }

  Future<void> _openSharedBudgetHistory(
      String groupId, String budgetId) async {
    try {
      final budgets =
          await getIt<FamilyRepository>().getSharedBudgets(groupId);
      if (!mounted) return;
      final budget = budgets.cast<SharedBudgetModel?>().firstWhere(
            (b) => b!.id == budgetId,
            orElse: () => null,
          );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (budget != null) {
          context.push(
            RouteNames.sharedBudgetDetail(groupId, budgetId),
            extra: {'budget': budget, 'initialTabIndex': 0},
          );
        } else {
          context.push(RouteNames.familyGroupDetail(groupId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppStrings.of(context).budgetClosedSharedSnackbar),
              backgroundColor: context.colors.primary,
            ),
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.familyGroupDetail(groupId));
      });
    }
  }

  void _openBudgetHistory(String budgetId) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.push(
        RouteNames.budgetDetail(budgetId),
        extra: {'budgetId': budgetId, 'initialTabIndex': 0},
      );
    });
  }

  Future<void> _initNotifications() async {
    final ns = getIt<NotificationService>();
    await ns.initialize();
    await ns.tryRegisterToken();
    if (!mounted) return;

    // Foreground local bildirim tap → InvitePage
    _inviteSub = NotificationService.onInvite.listen((token) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.familyInvite(token));
      });
    });

    // Foreground bildirim aksiyon butonları (Kabul Et / Reddet)
    _actionSub = NotificationService.onInviteAction.listen(_handleInviteAction);

    // Foreground INVITE_RESPONSE bildirimi tap → Grup detay sayfası
    _groupNavSub = NotificationService.onGroupNav.listen((groupId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.familyGroupDetail(groupId));
      });
    });

    // Foreground MONTHLY_REPORT bildirimi tap → Insights sayfası
    _insightsNavSub = NotificationService.onInsightsNav.listen((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.push(RouteNames.insights);
      });
    });

    // Foreground BUDGET_CLOSED personal → bilgi SnackBar
    _personalBudgetClosedSub =
        NotificationService.onPersonalBudgetClosed.listen((budgetId) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).budgetClosedPersonalSnackbar),
          backgroundColor: context.colors.primary,
        ),
      );
    });

    // Foreground BUDGET_CLOSED shared → info SnackBar
    _sharedBudgetClosedSub =
        NotificationService.onSharedBudgetClosed.listen((event) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).budgetClosedSharedSnackbar),
          backgroundColor: context.colors.primary,
        ),
      );
    });

    // Foreground tap'inde NotificationService manuel tetikleyici yayar
    // (lifecycle resumed event'i tetiklenmediği durumlar için).
    _consumeTriggerSub =
        NotificationService.onConsumeTrigger.listen((_) => _consumePending());

    // Cold start ve başlangıç pending token'larını tüket
    _consumePending();
  }

  Future<void> _handleInviteAction(
      ({String token, String action}) event) async {
    if (!mounted) return;
    try {
      if (event.action == 'accept') {
        final group =
            await getIt<FamilyRepository>().acceptInvite(event.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gruba katıldınız!')),
        );
        context.push(RouteNames.familyGroupDetail(group.id));
      } else {
        await getIt<FamilyRepository>().rejectInvite(event.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Davet reddedildi.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem sırasında hata oluştu.')),
      );
    }
  }

  static const int kCoachMarkVersion = 2;

  Future<void> _checkCoachMark() async {
    final storedVersion = await getIt<SecureStorage>().getCoachMarkVersion();
    if (storedVersion >= kCoachMarkVersion) return;
    if (!mounted) return;

    // Poll until the dashboard-body keys are mounted (they only appear after
    // DashboardLoaded). Try every 200 ms for up to 8 seconds then give up.
    const interval = Duration(milliseconds: 200);
    const maxWait = Duration(seconds: 8);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);
      if (!mounted) return;
      if (CoachMarkKeys.accounts.currentContext != null &&
          CoachMarkKeys.debts.currentContext != null &&
          CoachMarkKeys.reports.currentContext != null) {
        break;
      }
    }

    if (!mounted) return;
    // Verify all critical keys are ready before showing
    if (CoachMarkKeys.accounts.currentContext == null ||
        CoachMarkKeys.debts.currentContext == null ||
        CoachMarkKeys.reports.currentContext == null) {
      return; // Timeout — skip silently
    }

    _showCoachMark();
  }

  void _showCoachMark() {
    final s = AppStrings.of(context);
    final size = MediaQuery.of(context).size;

    void saveVersion() =>
        getIt<SecureStorage>().saveCoachMarkVersion(kCoachMarkVersion);

    TutorialCoachMark(
      targets: [
        // Step 1 — Home tab
        TargetFocus(
          identify: 'navHome',
          keyTarget: CoachMarkKeys.navHome,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachNavHomeTitle,
                body: s.coachNavHomeBody,
              ),
            ),
          ],
        ),
        // Step 2 — Transactions tab
        TargetFocus(
          identify: 'navTransactions',
          keyTarget: CoachMarkKeys.navTransactions,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachNavTransactionsTitle,
                body: s.coachNavTransactionsBody,
              ),
            ),
          ],
        ),
        // Step 3 — FAB (+ button)
        TargetFocus(
          identify: 'fab',
          keyTarget: CoachMarkKeys.fab,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachFabTitle,
                body: s.coachFabBody,
              ),
            ),
          ],
        ),
        // Step 4 — Budgets tab
        TargetFocus(
          identify: 'navBudgets',
          keyTarget: CoachMarkKeys.navBudgets,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachNavBudgetsTitle,
                body: s.coachNavBudgetsBody,
              ),
            ),
          ],
        ),
        // Step 5 — Subscriptions tab
        TargetFocus(
          identify: 'navSubscriptions',
          keyTarget: CoachMarkKeys.navSubscriptions,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachNavSubscriptionsTitle,
                body: s.coachNavSubscriptionsBody,
              ),
            ),
          ],
        ),
        // Step 6 — Reports icon (app bar, top of screen → content below)
        TargetFocus(
          identify: 'reports',
          keyTarget: CoachMarkKeys.reports,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachReportsTitle,
                body: s.coachReportsBody,
              ),
            ),
          ],
        ),
        // Step 7 — Settings icon (app bar)
        TargetFocus(
          identify: 'settings',
          keyTarget: CoachMarkKeys.settings,
          shape: ShapeLightFocus.Circle,
          paddingFocus: 6,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachSettingsTitle,
                body: s.coachSettingsBody,
              ),
            ),
          ],
        ),
        // Step 8 — My Accounts section
        TargetFocus(
          identify: 'accounts',
          keyTarget: CoachMarkKeys.accounts,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 8,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachAccountsTitle,
                body: s.coachAccountsBody,
              ),
            ),
          ],
        ),
        // Step 9 — Debts shortcut card
        TargetFocus(
          identify: 'debts',
          keyTarget: CoachMarkKeys.debts,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: _CoachContent(
                title: s.coachDebtsTitle,
                body: s.coachDebtsBody,
              ),
            ),
          ],
        ),
        // Step 10 — Swipe to delete (off-screen spotlight)
        TargetFocus(
          identify: 'swipe',
          targetPosition: TargetPosition(const Size(1, 1), Offset(-10, -10)),
          color: Colors.transparent,
          contents: [
            TargetContent(
              align: ContentAlign.custom,
              customPosition: CustomTargetContentPosition(
                top: size.height * 0.28,
                left: AppSpacing.pagePadding,
                right: AppSpacing.pagePadding,
              ),
              builder: (btnCtx, controller) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoachContent(
                    title: s.coachSwipeTitle,
                    body: s.coachSwipeBody,
                    icon: Icons.swipe_left_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: controller.next,
                      style: FilledButton.styleFrom(
                        backgroundColor: btnCtx.colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      child: Text(
                        s.coachDone,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: btnCtx.colors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      opacityShadow: 0.88,
      textSkip: s.coachSkip,
      skipWidget: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          s.coachSkip,
          style: AppTypography.bodyMd.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
      onFinish: saveVersion,
      onSkip: () {
        saveVersion();
        return true;
      },
    ).show(context: context);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => _AddActionSheet(
        onIncome: () {
          Navigator.pop(context);
          context.push(RouteNames.addTransaction, extra: {'type': 'INCOME'});
        },
        onExpense: () {
          Navigator.pop(context);
          context.push(RouteNames.addTransaction, extra: {'type': 'EXPENSE'});
        },
        onTransfer: () {
          Navigator.pop(context);
          context.push(RouteNames.addTransaction, extra: {'type': 'TRANSFER'});
        },
        onScan: () {
          Navigator.pop(context);
          context.push(RouteNames.receiptScanner);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BannerAdWidget(),
          _BottomNavBar(onAddTap: _showAddSheet),
        ],
      ),
    );
  }
}

class _AddActionSheet extends StatelessWidget {
  const _AddActionSheet({
    required this.onIncome,
    required this.onExpense,
    required this.onTransfer,
    required this.onScan,
  });

  final VoidCallback onIncome;
  final VoidCallback onExpense;
  final VoidCallback onTransfer;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _SheetAction(
                  icon: Icons.arrow_downward_rounded,
                  label: s.income,
                  color: colors.secondary,
                  onTap: onIncome,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetAction(
                  icon: Icons.arrow_upward_rounded,
                  label: s.expense,
                  color: colors.tertiary,
                  onTap: onExpense,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SheetAction(
                  icon: Icons.swap_horiz_rounded,
                  label: s.transfer,
                  color: colors.primary,
                  onTap: onTransfer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetAction(
                  icon: Icons.document_scanner_outlined,
                  label: s.scanReceipt,
                  color: colors.onSurfaceVariant,
                  onTap: onScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.onAddTap});

  final VoidCallback onAddTap;

  int _currentIndex(String location) {
    if (location.startsWith(RouteNames.transactions)) return 1;
    if (location.startsWith(RouteNames.budgets)) return 3;
    if (location.startsWith(RouteNames.subscriptions)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    final leftTabs = [
      _TabItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: s.navHome,
        route: RouteNames.home,
        coachKey: CoachMarkKeys.navHome,
      ),
      _TabItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: s.navTransactions,
        route: RouteNames.transactions,
        coachKey: CoachMarkKeys.navTransactions,
      ),
    ];

    final rightTabs = [
      _TabItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        label: s.navBudgets,
        route: RouteNames.budgets,
        coachKey: CoachMarkKeys.navBudgets,
      ),
      _TabItem(
        icon: Icons.subscriptions_outlined,
        activeIcon: Icons.subscriptions,
        label: s.navSubscriptions,
        route: RouteNames.subscriptions,
        coachKey: CoachMarkKeys.navSubscriptions,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              ...leftTabs.asMap().entries.map((e) {
                return _buildTabItem(context, e.value, e.key == currentIndex);
              }),
              // Center "+" action button
              Expanded(
                child: GestureDetector(
                  onTap: onAddTap,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      key: CoachMarkKeys.fab,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: colors.surface,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              ...rightTabs.asMap().entries.map((e) {
                return _buildTabItem(
                  context,
                  e.value,
                  (e.key + 3) == currentIndex,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, _TabItem tab, bool isActive) {
    final colors = context.colors;
    return Expanded(
      child: InkWell(
        key: tab.coachKey,
        onTap: () => context.go(tab.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive ? colors.primary : colors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
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
    this.coachKey,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final GlobalKey? coachKey;
}

class _CoachContent extends StatelessWidget {
  const _CoachContent({
    required this.title,
    required this.body,
    this.icon,
  });

  final String title;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(
          title,
          style: AppTypography.titleSm.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          style: AppTypography.bodyMd.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
