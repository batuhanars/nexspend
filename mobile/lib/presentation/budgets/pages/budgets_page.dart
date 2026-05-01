import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../navigation/route_names.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BudgetsView();
  }
}

class _BudgetsView extends StatelessWidget {
  const _BudgetsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainerHigh,
            onRefresh: () async {
              context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
              await context
                  .read<BudgetsBloc>()
                  .stream
                  .firstWhere((s) => s is BudgetsLoaded || s is BudgetsError);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  backgroundColor: AppColors.surface,
                  surfaceTintColor: Colors.transparent,
                  title: Text('Bütçeler', style: AppTypography.headlineSm),
                ),
                _buildBody(context, state),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: BlocBuilder<BudgetsBloc, BudgetsState>(
        builder: (context, state) {
          if (state is! BudgetsLoaded || state.budgets.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () async {
              await context.push(RouteNames.addBudget);
              if (context.mounted) {
                context
                    .read<BudgetsBloc>()
                    .add(const BudgetsRefreshRequested());
              }
            },
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BudgetsState state) {
    return switch (state) {
      BudgetsInitial() || BudgetsLoading() => const SliverFillRemaining(
          child: _BudgetsShimmer(),
        ),
      BudgetsError(:final message) => SliverFillRemaining(
          child: _ErrorView(
            message: message,
            onRetry: () => context
                .read<BudgetsBloc>()
                .add(const BudgetsLoadRequested()),
          ),
        ),
      BudgetsLoaded(:final overview, :final budgets) => SliverList(
          delegate: SliverChildListDelegate([
            if (overview.count > 0) ...[
              _OverviewCard(overview: overview),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (budgets.isEmpty)
              _EmptyBudgetsView(
                onAdd: () async {
                  await context.push(RouteNames.addBudget);
                  if (context.mounted) {
                    context
                        .read<BudgetsBloc>()
                        .add(const BudgetsRefreshRequested());
                  }
                },
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Aktif Bütçeler', style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.md),
                    ...budgets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _BudgetCard(
                          budget: b,
                          onDelete: () => context
                              .read<BudgetsBloc>()
                              .add(BudgetDeleteRequested(b.id)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────
// Overview Card
// ─────────────────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.overview});
  final BudgetOverviewModel overview;

  Color get _arcColor {
    final pct = overview.percentage;
    if (pct >= 100) return const Color(0xFFEF5350);
    if (pct >= 90) return const Color(0xFFFF9800);
    if (pct >= 80) return const Color(0xFFFFB68F);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(
                    percentage: overview.percentage,
                    color: _arcColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%${overview.percentage}',
                      style: AppTypography.headlineMd.copyWith(
                        color: _arcColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'harcandı',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'Toplam Bütçe',
                  value: CurrencyFormatter.format(overview.totalBudget),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Harcanan',
                  value: CurrencyFormatter.format(overview.totalSpent),
                  color: AppColors.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatChip(
                  label: 'Kalan',
                  value: CurrencyFormatter.format(overview.remaining),
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.bodySm.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Arc Painter
// ─────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.percentage, required this.color});
  final int percentage;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final pct = percentage.clamp(0, 100) / 100;
    if (pct > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * pct,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.percentage != percentage || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Budget Card
// ─────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.onDelete});
  final BudgetModel budget;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = (budget.percentage.clamp(0, 100) / 100).toDouble();
    final category = budget.category;

    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: const Color(0xFFEF5350).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF5350)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceContainerHigh,
            title: Text('Bütçeyi Sil', style: AppTypography.titleSm),
            content: Text(
              '"${budget.name}" bütçesi silinecek.',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'İptal',
                  style:
                      AppTypography.bodyMd.copyWith(color: AppColors.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Sil',
                  style: AppTypography.bodyMd
                      .copyWith(color: const Color(0xFFEF5350)),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category?.cardColor.withValues(alpha: 0.15) ??
                        AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconMapper.fromString(category?.icon ?? 'account_balance'),
                    color: category?.cardColor ?? AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(budget.name, style: AppTypography.titleSm),
                      if (category != null)
                        Text(
                          category.name,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Period badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    budget.periodLabel,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(budget.statusColor),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(budget.spent),
                  style: AppTypography.bodySm.copyWith(
                    color: budget.statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  ' / ${CurrencyFormatter.format(budget.amount)}',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: budget.statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '%${budget.percentage} · ${budget.statusLabel}',
                    style: AppTypography.labelSm.copyWith(
                      color: budget.statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty & Error States
// ─────────────────────────────────────────────────────────────

class _EmptyBudgetsView extends StatelessWidget {
  const _EmptyBudgetsView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 72,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Henüz bütçe yok',
            style: AppTypography.titleSm,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Harcamalarını takip etmek için\nbir bütçe oluştur.',
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Bütçe Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.wifi_off_rounded,
          size: 56,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          message,
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'Tekrar Dene',
            style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────

class _BudgetsShimmer extends StatelessWidget {
  const _BudgetsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview card shimmer
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            height: 16,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
