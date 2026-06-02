import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/family_model.dart';
import '../../../navigation/route_names.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

class FamilyGroupPage extends StatelessWidget {
  const FamilyGroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyGroupCreated || state is FamilyGroupDeleted) {
          context.read<FamilyBloc>().add(const FamilyGroupsLoadRequested());
        }
        if (state is FamilyGroupCreateError || state is FamilyGroupDeleteError) {
          final msg = state is FamilyGroupCreateError
              ? state.message
              : (state as FamilyGroupDeleteError).message;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: colors.error),
          );
          context.read<FamilyBloc>().add(const FamilyGroupsLoadRequested());
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
          title: Text(AppStrings.of(context).familyBudgetTitle),
          titleTextStyle: AppTypography.headlineSm.copyWith(color: colors.onSurface),
          iconTheme: IconThemeData(color: colors.onSurface),
        ),
        body: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            return switch (state) {
              FamilyGroupsLoading() || FamilyInitial() => const _LoadingView(),
              FamilyGroupsError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context
                      .read<FamilyBloc>()
                      .add(const FamilyGroupsLoadRequested()),
                ),
              FamilyGroupsLoaded(:final groups) when groups.isEmpty =>
                _EmptyView(onCreateTap: () => _showCreateGroupDialog(context)),
              FamilyGroupsLoaded(:final groups) =>
                _GroupListView(groups: groups),
              FamilyGroupCreating() => const _LoadingView(),
              _ => BlocBuilder<FamilyBloc, FamilyState>(
                  builder: (context, inner) => const _LoadingView(),
                ),
            };
          },
        ),
        floatingActionButton: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            final isEmpty = state is FamilyGroupsLoaded && state.groups.isEmpty;
            if (isEmpty) return const SizedBox.shrink();
            return FloatingActionButton(
              onPressed: () => _showCreateGroupDialog(context),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: const Icon(Icons.add_rounded),
            );
          },
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    String? selectedIcon;
    final icons = ['home', 'favorite', 'star', 'group', 'apartment'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final colors = ctx.colors;
          return AlertDialog(
            backgroundColor: colors.surfaceContainerHigh,
            title: Text(AppStrings.of(context).createNewGroupTitle, style: AppTypography.titleSm),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: AppStrings.of(context).groupNameHint,
                    hintStyle: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
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
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.2)
                              : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: isSelected
                              ? Border.all(color: colors.primary, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          _iconData(icon),
                          color: isSelected ? colors.primary : colors.onSurfaceVariant,
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
                child: Text(AppStrings.of(context).cancel,
                    style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.of(ctx).pop();
                  context.read<FamilyBloc>().add(FamilyGroupCreateRequested(
                        name: name,
                        icon: selectedIcon,
                      ));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: Text(AppStrings.of(context).createGroupBtn),
              ),
            ],
          );
        },
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
}

class _GroupListView extends StatelessWidget {
  const _GroupListView({required this.groups});

  final List<FamilyGroupModel> groups;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      onRefresh: () async {
        context.read<FamilyBloc>().add(const FamilyGroupsLoadRequested());
        await context
            .read<FamilyBloc>()
            .stream
            .firstWhere((s) => s is FamilyGroupsLoaded || s is FamilyGroupsError);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: groups.length,
        separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _GroupCard(group: groups[index]),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final FamilyGroupModel group;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => context.push(RouteNames.familyGroupDetail(group.id)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.group_outlined,
                color: colors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name, style: AppTypography.titleSm),
                  Text(
                    AppStrings.of(context).memberCountRole(
                        group.memberCount, group.role == FamilyRole.OWNER),
                    style: AppTypography.bodySm,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_outlined,
                color: colors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(AppStrings.of(context).noGroupsTitle, style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.of(context).noGroupsSubtitle,
              style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.of(context).createGroupLargeBtn),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      itemCount: 3,
      separatorBuilder: (context, i) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => Container(
        height: 80,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
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
    final colors = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onRetry,
            child: Text(AppStrings.of(context).retry,
                style: AppTypography.bodyMd.copyWith(color: colors.primary)),
          ),
        ],
      ),
    );
  }
}
