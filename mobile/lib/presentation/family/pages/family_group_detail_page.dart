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
        final colors = context.colors;
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
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
          );
        }
        if (state is FamilySharedBudgetCreated ||
            state is FamilySharedBudgetUpdated ||
            state is FamilySharedBudgetDeleted) {
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilySharedBudgetDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).sharedBudgetDeletedSuccess),
              backgroundColor: colors.secondary,
            ),
          );
        }
        if (state is FamilySharedBudgetDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
          );
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilyGroupDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).groupDeletedSuccess),
              backgroundColor: colors.secondary,
            ),
          );
          context.pop();
        }
        if (state is FamilyGroupDeleteError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
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
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
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
        if (state is FamilyInviteCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.of(context).inviteCancelledSuccess),
              backgroundColor: colors.secondary,
            ),
          );
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
        if (state is FamilyInviteCancelError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: colors.error),
          );
          context
              .read<FamilyBloc>()
              .add(FamilyGroupDetailLoadRequested(groupId: widget.groupId));
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.surface,
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
    final colors = context.colors;
    final isOwner = group.role == FamilyRole.OWNER;

    return RefreshIndicator(
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
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
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: colors.onSurface),
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
                tooltip: AppStrings.of(context).contributionReport,
              ),
              if (isOwner)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: colors.error),
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
                                    .copyWith(color: colors.error),
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
                        onPressed: () async {
                          await context.push(RouteNames.addSharedBudget(groupId));
                          if (!context.mounted) return;
                          context.read<FamilyBloc>().add(
                                FamilyGroupDetailLoadRequested(groupId: groupId),
                              );
                        },
                        child: Text(
                          AppStrings.of(context).addSharedBudgetBtn,
                          style: AppTypography.bodySm.copyWith(color: colors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (group.sharedBudgets.isEmpty)
                    _EmptyBudgets(
                      onAdd: () async {
                        await context.push(RouteNames.addSharedBudget(groupId));
                        if (!context.mounted) return;
                        context.read<FamilyBloc>().add(
                              FamilyGroupDetailLoadRequested(groupId: groupId),
                            );
                      },
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
                                color: colors.errorContainer,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusLg),
                              ),
                              child: Icon(Icons.delete_outline_rounded,
                                  color: colors.error),
                            ),
                            confirmDismiss: (_) =>
                                _confirmDeleteBudget(context, b.name),
                            onDismissed: (_) {
                              context.read<FamilyBloc>().add(
                                    FamilySharedBudgetDeleteRequested(
                                        groupId: groupId, budgetId: b.id),
                                  );
                            },
                            child: SharedBudgetCard(
                              budget: b,
                              onTap: () => context.push(
                                RouteNames.sharedBudgetDetail(groupId, b.id),
                                extra: {'budget': b},
                              ),
                            ),
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
                        child: _InviteRow(invite: inv, groupId: groupId),
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
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).deleteSharedBudgetTitle, style: AppTypography.titleSm),
          content: Text(
            AppStrings.of(context).deleteBudgetContent(budgetName),
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel,
                  style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.of(context).delete, style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context, String groupId) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).inviteMemberTitle, style: AppTypography.titleSm),
          content: TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: AppStrings.of(context).emailAddressHint,
              hintStyle: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
              filled: true,
              fillColor: colors.surfaceContainerHighest,
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
                  style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
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
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: Text(AppStrings.of(context).sendInviteBtn),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveMember(
      BuildContext context, String groupId, FamilyMemberModel member) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).removeMemberTitle, style: AppTypography.titleSm),
          content: Text(
            AppStrings.of(context).removeMemberContent(member.name),
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.of(context).removeMemberBtn,
                  style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
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
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(AppStrings.of(context).deleteGroupTitle, style: AppTypography.titleSm),
          content: Text(
            AppStrings.of(context).deleteGroupContent(group.name),
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel,
                  style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(AppStrings.of(context).delete,
                  style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
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
  const _InviteRow({required this.invite, required this.groupId});

  final FamilyInviteModel invite;
  final String groupId;

  Future<void> _confirmCancel(BuildContext context) async {
    final s = AppStrings.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = ctx.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          title: Text(s.cancelInviteTitle, style: AppTypography.titleSm),
          content: Text(
            s.cancelInviteConfirm(invite.email),
            style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel,
                  style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.delete, style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );
    if (ok == true && context.mounted) {
      context.read<FamilyBloc>().add(
            FamilyInviteCancelRequested(
              groupId: groupId,
              token: invite.token ?? '',
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(invite.email, style: AppTypography.bodyMd),
          ),
          InviteStatusBadge(status: invite.status),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _confirmCancel(context),
            child: Icon(Icons.close_rounded, size: 18, color: colors.error),
          ),
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
    final colors = context.colors;
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: colors.primary, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.of(context).addSharedBudgetPrompt,
              style: AppTypography.bodyMd.copyWith(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: context.colors.primary),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

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
