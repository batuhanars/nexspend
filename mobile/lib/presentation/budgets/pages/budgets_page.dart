import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/icon_mapper.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/models/inflation_model.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../navigation/route_names.dart';
import '../../inflation/bloc/inflation_bloc.dart';
import '../../inflation/bloc/inflation_event.dart';
import '../../inflation/bloc/inflation_state.dart';
import '../../inflation/widgets/inflation_suggestion_card.dart';
import '../bloc/budgets_bloc.dart';
import '../bloc/budgets_event.dart';
import '../bloc/budgets_state.dart';
import '../widgets/budget_card.dart';
import '../widgets/budgets_shimmer.dart';
import '../widgets/edit_budget_sheet.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';
import '../widgets/overview_card.dart';
import '../widgets/warning_banner.dart';

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
    final s = AppStrings.of(context);
    return MultiBlocListener(
      listeners: [
        // İlk yüklemede (Loading→Loaded) aktif bütçeler için suggestion çek
        BlocListener<BudgetsBloc, BudgetsState>(
          listenWhen: (prev, curr) =>
              curr is BudgetsLoaded && prev is! BudgetsLoaded,
          listener: (context, state) {
            if (state is BudgetsLoaded && state.budgets.isNotEmpty) {
              final ids = state.budgets
                  .where((b) => b.isActive)
                  .map((b) => b.id)
                  .toList();
              context.read<InflationBloc>().add(
                    InflationSuggestionsFetchRequested(budgetIds: ids),
                  );
            }
          },
        ),
        // Apply başarılı → bütçeleri + suggestion'ları yenile
        BlocListener<InflationBloc, InflationState>(
          listener: (context, state) {
            if (state is InflationApplied) {
              context.read<BudgetsBloc>().add(const BudgetsRefreshRequested());
              final budgetsState = context.read<BudgetsBloc>().state;
              if (budgetsState is BudgetsLoaded) {
                final ids = budgetsState.budgets
                    .where((b) => b.isActive)
                    .map((b) => b.id)
                    .toList();
                context.read<InflationBloc>().add(
                      InflationSuggestionsFetchRequested(budgetIds: ids),
                    );
              }
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Bütçe enflasyona göre güncellendi'),
                backgroundColor: AppColors.secondary,
              ));
            } else if (state is InflationApplyError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: BlocBuilder<BudgetsBloc, BudgetsState>(
          builder: (context, state) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
              onRefresh: () async {
                context
                    .read<BudgetsBloc>()
                    .add(const BudgetsRefreshRequested());
                final newState = await context
                    .read<BudgetsBloc>()
                    .stream
                    .firstWhere((s) => s is BudgetsLoaded || s is BudgetsError);
                // _onRefresh intermediate BudgetsLoading emit etmediği için
                // listenWhen tetiklenmiyor → suggestion fetch'i burada açıkça
                // tetikliyoruz, aksi halde değişen updatedAt'ler yansımıyor.
                if (newState is BudgetsLoaded && context.mounted) {
                  final ids = newState.budgets
                      .where((b) => b.isActive)
                      .map((b) => b.id)
                      .toList();
                  context.read<InflationBloc>().add(
                        InflationSuggestionsFetchRequested(budgetIds: ids),
                      );
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppColors.surface,
                    surfaceTintColor: Colors.transparent,
                    title:
                        Text(s.budgetsTitle, style: AppTypography.headlineSm),
                    actions: [
                      IconButton(
                        icon: const Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          await context.push(RouteNames.addBudget);
                          if (context.mounted) {
                            context
                                .read<BudgetsBloc>()
                                .add(const BudgetsRefreshRequested());
                          }
                        },
                      ),
                    ],
                  ),
                  _buildBody(context, state, s),
                  const SliverToBoxAdapter(child: SizedBox(height: 96)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, BudgetsState state, AppStrings s) {
    return switch (state) {
      BudgetsInitial() || BudgetsLoading() => const SliverFillRemaining(
          child: BudgetsShimmer(),
        ),
      BudgetsError(:final message) => SliverFillRemaining(
          child: ErrorView(
            message: message,
            onRetry: () =>
                context.read<BudgetsBloc>().add(const BudgetsLoadRequested()),
          ),
        ),
      BudgetsLoaded(:final overview, :final budgets) => SliverList(
          delegate: SliverChildListDelegate([
            if (overview.count > 0) ...[
              OverviewCard(overview: overview),
              const SizedBox(height: AppSpacing.xl),
            ],
            const _FamilyGroupsSection(),
            _InflationSuggestionsSection(budgets: budgets),
            if (budgets.isEmpty)
              EmptyStateView(
                icon: Icons.account_balance_wallet_outlined,
                title: s.noBudgets,
                subtitle: s.noBudgetsSubtitle,
                buttonLabel: s.createBudgetBtn,
                onAction: () async {
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
                    WarningBanner(budgets: budgets),
                    Text(s.activeBudgets, style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.md),
                    ...budgets.map(
                      (b) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BudgetCard(
                          budget: b,
                          onDelete: () {
                            context
                                .read<BudgetsBloc>()
                                .add(BudgetDeleteRequested(b.id));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Text(AppStrings.of(context)
                                  .budgetDeletedSuccess),
                              backgroundColor: AppColors.secondary,
                            ));
                          },
                          onEdit: () {
                            final bloc = context.read<BudgetsBloc>();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor:
                                  AppColors.surfaceContainerHigh,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                      AppSpacing.radiusLg),
                                ),
                              ),
                              builder: (_) => BlocProvider.value(
                                value: bloc,
                                child: EditBudgetSheet(budget: b),
                              ),
                            );
                          },
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

/// Aktif bütçeler için enflasyon öneri kartlarını gösterir.
/// Null suggestion (204) olan bütçeler için kart render edilmez.
class _InflationSuggestionsSection extends StatelessWidget {
  const _InflationSuggestionsSection({required this.budgets});

  final List<BudgetModel> budgets;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        if (state is! InflationSuggestionsLoaded) {
          return const SizedBox.shrink();
        }

        final pairs = budgets
            .where((b) => b.isActive && state.suggestions[b.id] != null)
            .map((b) => (budget: b, suggestion: state.suggestions[b.id]!))
            .toList();

        if (pairs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...pairs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SuggestionCardWrapper(
                    budget: p.budget,
                    suggestion: p.suggestion,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

// ── Aile Grupları Bölümü ───────────────────────────────────────────────────

class _FamilyGroupsSection extends StatefulWidget {
  const _FamilyGroupsSection();

  @override
  State<_FamilyGroupsSection> createState() => _FamilyGroupsSectionState();
}

class _FamilyGroupsSectionState extends State<_FamilyGroupsSection> {
  late Future<List<FamilyGroupModel>> _future;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _future = GetIt.I<FamilyRepository>().getGroups();
  }

  void _reload() => setState(
        () => _future = GetIt.I<FamilyRepository>().getGroups(),
      );

  Future<void> _createGroup(String name, String? icon) async {
    setState(() => _isCreating = true);
    try {
      await GetIt.I<FamilyRepository>().createGroup(name: name, icon: icon);
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grup oluşturulamadı'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    String? selectedIcon;
    const icons = ['home', 'favorite', 'star', 'group', 'apartment'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text('Yeni Grup Oluştur', style: AppTypography.titleSm),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Grup adı (örn. Ev Bütçesi)',
                  hintStyle: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: icons.map((icon) {
                  final isSelected = selectedIcon == icon;
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedIcon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        _iconData(icon),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                        size: 22,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'İptal',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                _createGroup(name, selectedIcon);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(String icon) => switch (icon) {
        'home' => Icons.home_outlined,
        'favorite' => Icons.favorite_outline_rounded,
        'star' => Icons.star_outline_rounded,
        'group' => Icons.group_outlined,
        'apartment' => Icons.apartment_outlined,
        _ => Icons.group_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FamilyGroupModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isCreating) {
          return const SizedBox.shrink();
        }

        final groups = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child:
                        Text('AİLE GRUPLARI', style: AppTypography.labelSm),
                  ),
                  if (_isCreating)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _showCreateDialog,
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (groups.isEmpty)
                _CreateGroupPromptCard(onTap: _showCreateDialog)
              else
                ...groups.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _FamilyGroupEntryCard(group: g),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }
}

class _CreateGroupPromptCard extends StatelessWidget {
  const _CreateGroupPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Aile grubu oluştur',
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyGroupEntryCard extends StatelessWidget {
  const _FamilyGroupEntryCard({required this.group});

  final FamilyGroupModel group;

  @override
  Widget build(BuildContext context) {
    final icon = IconMapper.fromString(group.icon ?? 'people');
    return GestureDetector(
      onTap: () => context.push(RouteNames.familyGroupDetail(group.id)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${group.memberCount} üye',
                    style: AppTypography.bodySm
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCardWrapper extends StatelessWidget {
  const _SuggestionCardWrapper({
    required this.budget,
    required this.suggestion,
  });

  final BudgetModel budget;
  final InflationSuggestionModel suggestion;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      buildWhen: (_, curr) =>
          curr is InflationApplying ||
          curr is InflationApplied ||
          curr is InflationApplyError ||
          curr is InflationSuggestionsLoaded,
      builder: (context, state) {
        final isApplying = state is InflationApplying &&
            state.budgetId == suggestion.budgetId;
        return InflationSuggestionCard(
          suggestion: suggestion,
          budgetName: budget.name,
          isApplying: isApplying,
          onApply: () => context.read<InflationBloc>().add(
                InflationApplyRequested(
                  budgetId: suggestion.budgetId,
                  newAmount: suggestion.suggestedAmount,
                ),
              ),
        );
      },
    );
  }
}
