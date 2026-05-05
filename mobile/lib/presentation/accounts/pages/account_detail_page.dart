import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/account_analytics_model.dart';
import '../../../data/models/account_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../navigation/route_names.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_detail_bloc.dart';
import '../widgets/account_detail_shimmer.dart';
import '../widgets/account_header_card.dart';
import '../widgets/account_transactions_section.dart';
import '../widgets/monthly_chart_section.dart';
import '../widgets/this_month_section.dart';
import '../widgets/top_categories_section.dart';
import '../../shared/widgets/error_view.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    super.key,
    required this.accountId,
    this.initialAccount,
  });

  final String accountId;
  final AccountModel? initialAccount;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late AccountModel? _displayAccount = widget.initialAccount;

  @override
  void initState() {
    super.initState();
    context.read<AccountDetailBloc>().add(
          AccountDetailLoadRequested(accountId: widget.accountId),
        );
  }

  Future<void> _addTransaction() async {
    final bloc = context.read<AccountDetailBloc>();
    await context.push(RouteNames.addTransaction,
        extra: {'accountId': widget.accountId});
    if (mounted) {
      bloc.add(AccountDetailRefreshRequested(accountId: widget.accountId));
    }
  }

  Future<void> _openEdit(AccountModel account) async {
    final updated = await context.push<AccountModel>(
      RouteNames.editAccount(account.id),
      extra: account,
    );
    if (updated != null && mounted) {
      setState(() => _displayAccount = updated);
      context.read<AccountDetailBloc>().add(
            AccountDetailAccountUpdated(updated),
          );
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String content,
    required String confirm,
    bool isDanger = false,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceContainerHigh,
          title: Text(title, style: AppTypography.titleSm),
          content: Text(
            content,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(AppStrings.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                confirm,
                style: TextStyle(
                  color: isDanger ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AccountBloc, AccountState>(
          listener: (context, state) {
            if (state is AccountDeleted) {
              context.pop();
            } else if (state is AccountActionDone) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              context.read<AccountDetailBloc>().add(
                    AccountDetailRefreshRequested(
                        accountId: widget.accountId),
                  );
            } else if (state is AccountError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<AccountDetailBloc, AccountDetailState>(
        builder: (context, state) {
          final account = state is AccountDetailLoaded
              ? state.account
              : _displayAccount;

          return Scaffold(
            body: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceContainerHigh,
              onRefresh: () async {
                context.read<AccountDetailBloc>().add(
                      AccountDetailRefreshRequested(
                          accountId: widget.accountId),
                    );
                await context
                    .read<AccountDetailBloc>()
                    .stream
                    .firstWhere((s) =>
                        s is AccountDetailLoaded ||
                        s is AccountDetailError);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildAppBar(context, account),
                  SliverToBoxAdapter(
                    child: _buildContent(context, state, account),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xxxl),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AccountModel? account) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      title: Text(
        account?.name ?? AppStrings.of(context).accountDetailTitle,
        style: AppTypography.headlineSm,
      ),
      actions: [
        if (account != null)
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: _addTransaction,
          ),
        if (account != null)
          BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              final isLoading = state is AccountSubmitting;
              if (isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }
              return PopupMenuButton<String>(
                color: AppColors.surfaceContainerHigh,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.onSurface,
                ),
                onSelected: (value) => _handleMenuAction(value, account),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.md),
                        Text(AppStrings.of(context).edit),
                      ],
                    ),
                  ),
                  if (!account.isDefault)
                    PopupMenuItem(
                      value: 'set_default',
                      child: Row(
                        children: [
                          const Icon(Icons.star_outline_rounded,
                              size: 18,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.md),
                          Text(AppStrings.of(context).setAsDefault),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        const Icon(Icons.archive_outlined,
                            size: 18,
                            color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.md),
                        Text(AppStrings.of(context).archive),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          AppStrings.of(context).deleteAccountTitle,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  void _handleMenuAction(String action, AccountModel account) async {
    switch (action) {
      case 'edit':
        _openEdit(account);
      case 'set_default':
        context.read<AccountBloc>().add(
              AccountSetDefaultRequested(account.id),
            );
      case 'archive':
        final confirm = await _confirmAction(
          title: AppStrings.of(context).archiveAccountTitle,
          content: AppStrings.of(context).archiveAccountContent,
          confirm: AppStrings.of(context).archiveConfirm,
        );
        if (confirm == true && mounted) {
          context.read<AccountBloc>().add(
                AccountArchiveRequested(account.id),
              );
        }
      case 'delete':
        final confirm = await _confirmAction(
          title: AppStrings.of(context).deleteAccountTitle,
          content: AppStrings.of(context).deleteAccountContent,
          confirm: AppStrings.of(context).delete,
          isDanger: true,
        );
        if (confirm == true && mounted) {
          context.read<AccountBloc>().add(
                AccountDeleteRequested(account.id),
              );
        }
    }
  }

  Widget _buildContent(
    BuildContext context,
    AccountDetailState state,
    AccountModel? account,
  ) {
    if (state is AccountDetailLoading || state is AccountDetailInitial) {
      return AccountDetailShimmer(account: _displayAccount);
    }
    if (state is AccountDetailError) {
      return ErrorView(
        message: state.message,
        onRetry: () => context.read<AccountDetailBloc>().add(
              AccountDetailLoadRequested(accountId: widget.accountId),
            ),
      );
    }
    if (state is AccountDetailLoaded) {
      return _DetailContent(
        account: state.account,
        analytics: state.analytics,
        transactions: state.transactions,
        onAddTransaction: _addTransaction,
      );
    }
    return const SizedBox.shrink();
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.account,
    required this.analytics,
    required this.transactions,
    required this.onAddTransaction,
  });

  final AccountModel account;
  final AccountAnalyticsModel analytics;
  final List<TransactionModel> transactions;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        AccountHeaderCard(account: account),
        const SizedBox(height: AppSpacing.xl),
        ThisMonthSection(analytics: analytics),
        if (analytics.months.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          MonthlyChartSection(months: analytics.months),
        ],
        if (analytics.topCategories.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          TopCategoriesSection(categories: analytics.topCategories),
        ],
        const SizedBox(height: AppSpacing.xl),
        AccountTransactionsSection(
          transactions: transactions,
          onAddTransaction: onAddTransaction,
        ),
      ],
    );
  }
}
