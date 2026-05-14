import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/family_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../navigation/route_names.dart';
import '../../shared/widgets/split_amount_field.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';
import '../widgets/invite_status_badge.dart';
import '../widgets/member_avatar_row.dart';
import '../widgets/shared_budget_card.dart';

class FamilyGroupDetailPage extends StatefulWidget {
  const FamilyGroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<FamilyGroupDetailPage> createState() => _FamilyGroupDetailPageState();
}

class _FamilyGroupDetailPageState extends State<FamilyGroupDetailPage> {
  @override
  void initState() {
    super.initState();
    context
        .read<FamilyBloc>()
        .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FamilyBloc, FamilyState>(
      listener: (context, state) {
        if (state is FamilyInviteSent) {
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context).inviteSentSuccess)),
          );
        }
        if (state is FamilyInviteSendError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
        }
        if (state is FamilySharedBudgetCreated ||
            state is FamilySharedBudgetDeleted) {
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilySharedBudgetDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).sharedBudgetDeletedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
        if (state is FamilySharedBudgetDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilyGroupDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).groupDeletedSuccess),
              backgroundColor: AppColors.secondary,
            ),
          );
          context.pop();
        }
        if (state is FamilyGroupDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
          // Delete hatasından sonra detay sayfasını tekrar yükle — aksi halde
          // bloc FamilyGroupDeleteError state'inde takılı kalır ve switch'in
          // catch-all branch'i sonsuz _LoadingBody gösterir.
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilySharedBudgetCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error),
          );
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilyMemberRemoved) {
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            return switch (state) {
              FamilyGroupDetailLoading() => const _LoadingBody(),
              FamilyGroupDetailLoaded(:final group) =>
                _DetailBody(group: group, groupId: widget.groupId),
              FamilyGroupDetailError(:final message) => _ErrorBody(
                  message: message,
                  onRetry: () => context.read<FamilyBloc>().add(
                        FamilyGroupDetailLoadRequested(groupId: widget.groupId),
                      ),
                ),
              _ => const _LoadingBody(),
            };
          },
        ),
      ),
    );
  }

}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.group, required this.groupId});

  final FamilyGroupModel group;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    final isOwner = group.role == FamilyRole.OWNER;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceContainerHigh,
      onRefresh: () async {
        context
            .read<FamilyBloc>()
            .add(FamilyGroupDetailLoadRequested(groupId: groupId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppColors.onSurface),
          title: Text(group.name, style: AppTypography.headlineSm),
          actions: [
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _showInviteDialog(context, groupId),
                tooltip: AppStrings.of(context).inviteMemberTitle,
              ),
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              onPressed: () =>
                  context.push(RouteNames.familyContributions(groupId)),
              tooltip: 'Katkı Raporu',
            ),
            if (isOwner)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                ),
                onPressed: () => _confirmDeleteGroup(context, group),
                tooltip: AppStrings.of(context).deleteGroupTitle,
              ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üyeler
                Text(AppStrings.of(context).membersSection, style: AppTypography.labelSm),
                const SizedBox(height: AppSpacing.md),
                MemberAvatarRow(members: group.members, showRoles: true),

                // Üye kaldır (owner için)
                if (isOwner) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ...group.members
                      .where((m) => m.role != FamilyRole.OWNER)
                      .map(
                        (m) => Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                _confirmRemoveMember(context, groupId, m),
                            child: Text(
                              AppStrings.of(context).removeMemberAction(m.name),
                              style: AppTypography.bodySm
                                  .copyWith(color: AppColors.error),
                            ),
                          ),
                        ),
                      ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Ortak bütçeler
                Row(
                  children: [
                    Expanded(
                      child: Text(AppStrings.of(context).sharedBudgetsSection,
                          style: AppTypography.labelSm),
                    ),
                    TextButton(
                      onPressed: () => _showAddBudgetDialog(context, groupId),
                      child: Text(
                        AppStrings.of(context).addSharedBudgetBtn,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (group.sharedBudgets.isEmpty)
                  _EmptyBudgets(
                    onAdd: () => _showAddBudgetDialog(context, groupId),
                  )
                else
                  ...group.sharedBudgets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Dismissible(
                          key: ValueKey(b.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusLg),
                            ),
                            child: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error),
                          ),
                          confirmDismiss: (_) =>
                              _confirmDeleteBudget(context, b.name),
                          onDismissed: (_) {
                            context.read<FamilyBloc>().add(
                                  FamilySharedBudgetDeleteRequested(
                                      groupId: groupId, budgetId: b.id),
                                );
                          },
                          child: SharedBudgetCard(budget: b),
                        ),
                      )),

                // Bekleyen davetler (sadece owner)
                if (isOwner && group.pendingInvites.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(AppStrings.of(context).pendingInvitesSection, style: AppTypography.labelSm),
                  const SizedBox(height: AppSpacing.md),
                  ...group.pendingInvites.map(
                    (inv) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _InviteRow(invite: inv),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Future<bool?> _confirmDeleteBudget(BuildContext context, String budgetName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).deleteSharedBudgetTitle, style: AppTypography.titleSm),
        content: Text(
          AppStrings.of(context).deleteBudgetContent(budgetName),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel,
                style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).delete, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(BuildContext context, String groupId) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).inviteMemberTitle, style: AppTypography.titleSm),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: AppTypography.bodyMd,
          decoration: InputDecoration(
            hintText: AppStrings.of(context).emailAddressHint,
            hintStyle:
                AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            filled: true,
            fillColor: AppColors.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.of(context).cancel,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.of(ctx).pop();
              context.read<FamilyBloc>().add(FamilyInviteSendRequested(
                    groupId: groupId,
                    email: email,
                  ));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(AppStrings.of(context).sendInviteBtn),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, String groupId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddBudgetDialog(
        groupId: groupId,
        onSubmit: (name, amount, categoryId, startDate) {
          context.read<FamilyBloc>().add(FamilySharedBudgetCreateRequested(
                groupId: groupId,
                categoryId: categoryId,
                name: name,
                amount: amount,
                startDate: startDate,
              ));
        },
      ),
    );
  }

  void _confirmRemoveMember(
      BuildContext context, String groupId, FamilyMemberModel member) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).removeMemberTitle, style: AppTypography.titleSm),
        content: Text(
          AppStrings.of(context).removeMemberContent(member.name),
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).removeMemberBtn,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<FamilyBloc>().add(FamilyMemberRemoveRequested(
              groupId: groupId,
              userId: member.userId,
            ));
      }
    });
  }

  void _confirmDeleteGroup(BuildContext context, FamilyGroupModel group) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        title: Text(AppStrings.of(context).deleteGroupTitle,
            style: AppTypography.titleSm),
        content: Text(
          AppStrings.of(context).deleteGroupContent(group.name),
          style:
              AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.of(context).cancel,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.of(context).delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context
            .read<FamilyBloc>()
            .add(FamilyGroupDeleteRequested(groupId: group.id));
      }
    });
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite});

  final FamilyInviteModel invite;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(
            child: Text(invite.email, style: AppTypography.bodyMd),
          ),
          InviteStatusBadge(status: invite.status),
        ],
      ),
    );
  }
}

class _EmptyBudgets extends StatelessWidget {
  const _EmptyBudgets({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.primary, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.of(context).addSharedBudgetPrompt,
              style: AppTypography.bodyMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog({required this.groupId, required this.onSubmit});

  final String groupId;
  final void Function(String name, double amount, String categoryId, String startDate) onSubmit;

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  CategoryModel? _selectedCategory;
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = GetIt.I<CategoryRepository>().getCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  double? _parseAmount(String text) {
    final cleaned = text.replaceAll('.', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerHigh,
      title: Text(AppStrings.of(context).addSharedBudgetTitle, style: AppTypography.titleSm),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: AppStrings.of(context).sharedBudgetNameHint,
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
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsFormatter(),
              ],
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: AppStrings.of(context).amountTRYHint,
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
            const SizedBox(height: AppSpacing.sm),
            FutureBuilder<List<CategoryModel>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                }
                final categories = snapshot.data ?? [];
                return DropdownButtonFormField<CategoryModel>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.surfaceContainerHigh,
                  style: AppTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: AppStrings.of(context).selectCategory,
                    hintStyle: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                    filled: true,
                    fillColor: AppColors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name, style: AppTypography.bodyMd),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of(context).cancel,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final amount = _parseAmount(_amountCtrl.text);
            if (name.isEmpty || amount == null || _selectedCategory == null) return;
            Navigator.of(context).pop();
            final now = DateTime.now();
            final startDate =
                '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
            widget.onSubmit(name, amount, _selectedCategory!.id, startDate);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
          ),
          child: Text(AppStrings.of(context).addBtn),
        ),
      ],
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            onPressed: onRetry,
            child: Text(AppStrings.of(context).retry,
                style: AppTypography.bodyMd.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
