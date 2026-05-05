import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/account_bloc.dart';
import '../widgets/account_list_tile.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_view.dart';

class AccountsListPage extends StatefulWidget {
  const AccountsListPage({super.key});

  @override
  State<AccountsListPage> createState() => _AccountsListPageState();
}

class _AccountsListPageState extends State<AccountsListPage> {
  List<AccountModel>? _accounts;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final result = await getIt<AccountRepository>().getAccounts();
      if (mounted) setState(() { _accounts = result; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  Future<void> _goToAdd() async {
    await context.push(RouteNames.addAccount);
    _load();
  }

  Future<void> _goToDetail(AccountModel account) async {
    await context.push(RouteNames.accountDetail(account.id), extra: account);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts ?? [];
    final showFab = !_isLoading && !_hasError && accounts.isNotEmpty;

    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountActionDone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          _load();
        } else if (state is AccountSuccess || state is AccountDeleted) {
          if (state is AccountDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppStrings.of(context).accountDeleted)),
            );
          }
          _load();
        } else if (state is AccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(AppStrings.of(context).myAccountsTitle),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: AppSpacing.lg),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: AppStrings.of(context).refreshTooltip,
              ),
          ],
        ),
        floatingActionButton: showFab
            ? FloatingActionButton(
                onPressed: _goToAdd,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                child: const Icon(Icons.add_rounded),
              )
            : null,
        body: _buildBody(accounts),
      ),
    );
  }

  Widget _buildBody(List<AccountModel> accounts) {
    if (_isLoading && _accounts == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_hasError) {
      return ErrorView(message: AppStrings.of(context).accountsLoadFailed, onRetry: _load);
    }
    if (accounts.isEmpty) {
      return EmptyStateView(
        icon: Icons.account_balance_wallet_outlined,
        title: AppStrings.of(context).noAccountsYet,
        subtitle: AppStrings.of(context).noAccountsSubtitle,
        buttonLabel: AppStrings.of(context).addAccountTitle,
        onAction: _goToAdd,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.lg,
        AppSpacing.pagePadding,
        AppSpacing.xxxl + 80,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AccountListTile(
          account: accounts[i],
          onTap: () => _goToDetail(accounts[i]),
        ),
      ),
    );
  }
}
