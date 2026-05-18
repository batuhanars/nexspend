import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/di/injection.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/services/notification_service.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/utils/coach_mark_keys.dart';
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
    }
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

  Future<void> _checkCoachMark() async {
    final seen = await getIt<SecureStorage>().isCoachMarkSeen();
    if (!seen && mounted) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) _showCoachMark();
    }
  }

  void _showCoachMark() {
    final size = MediaQuery.of(context).size;

    TutorialCoachMark(
      targets: [
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
                title: 'Hızlı Ekle',
                body: 'Bu butona basarak gelir, gider, transfer ekleyebilir ve fiş tarayabilirsin.',
              ),
            ),
          ],
        ),
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
                title: 'Ayarlar',
                body: 'Profilini düzenleyebilir, Ortak Bütçe oluşturabilir ve bildirim tercihlerini ayarlayabilirsin.',
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: 'swipe',
          // Ekranın dışına konumlandırılmış 1×1 hedef — spotlight yok
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
              builder: (_, controller) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CoachContent(
                    title: 'Kaydırarak Sil',
                    body: 'İşlem, bütçe veya herhangi bir listede kartı sola kaydırarak silebilirsin.',
                    icon: Icons.swipe_left_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: controller.next,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusXl),
                        ),
                      ),
                      child: Text(
                        'Tamam',
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.surface,
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
      textSkip: 'Atla',
      skipWidget: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Atla',
          style: AppTypography.bodyMd.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
      onFinish: () => getIt<SecureStorage>().saveCoachMarkSeen(),
      onSkip: () {
        getIt<SecureStorage>().saveCoachMarkSeen();
        return true;
      },
    ).show(context: context);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerHigh,
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
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
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
                  color: AppColors.secondary,
                  onTap: onIncome,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetAction(
                  icon: Icons.arrow_upward_rounded,
                  label: s.expense,
                  color: AppColors.tertiary,
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
                  color: AppColors.primary,
                  onTap: onTransfer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SheetAction(
                  icon: Icons.document_scanner_outlined,
                  label: s.scanReceipt,
                  color: AppColors.onSurfaceVariant,
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
                color: AppColors.onSurface,
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
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _currentIndex(location);

    final leftTabs = [
      _TabItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: s.navHome,
        route: RouteNames.home,
      ),
      _TabItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: s.navTransactions,
        route: RouteNames.transactions,
      ),
    ];

    final rightTabs = [
      _TabItem(
        icon: Icons.pie_chart_outline,
        activeIcon: Icons.pie_chart,
        label: s.navBudgets,
        route: RouteNames.budgets,
      ),
      _TabItem(
        icon: Icons.subscriptions_outlined,
        activeIcon: Icons.subscriptions,
        label: s.navSubscriptions,
        route: RouteNames.subscriptions,
      ),
    ];

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
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.surface,
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
    return Expanded(
      child: InkWell(
        onTap: () => context.go(tab.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? tab.activeIcon : tab.icon,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
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
