import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../navigation/route_names.dart';
import '../bloc/account_bloc.dart';

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
              const SnackBar(content: Text('Hesap silindi')),
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
          title: const Text('Hesaplarım'),
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
                tooltip: 'Yenile',
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
      return _ErrorView(onRetry: _load);
    }
    if (accounts.isEmpty) {
      return _EmptyView(onAdd: _goToAdd);
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
        child: _AccountCard(
          account: accounts[i],
          onTap: () => _goToDetail(accounts[i]),
        ),
      ),
    );
  }
}

// ── Account card ─────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onTap});
  final AccountModel account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: account.cardColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(account.iconData, size: 22, color: account.cardColor),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(account.name, style: AppTypography.titleSm),
                          if (account.isDefault) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _DefaultBadge(),
                          ],
                        ],
                      ),
                      Text(
                        account.type.label,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(account.balance),
                      style: AppTypography.titleSm.copyWith(
                        color: account.balance >= 0
                            ? AppColors.onSurface
                            : AppColors.error,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      account.currency,
                      style: AppTypography.bodySm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            if (account.type == AccountType.CREDIT_CARD &&
                account.creditLimit != null) ...[
              const SizedBox(height: AppSpacing.md),
              _CreditBar(account: account),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'Varsayılan',
        style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontSize: 10),
      ),
    );
  }
}

class _CreditBar extends StatelessWidget {
  const _CreditBar({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final pct = account.creditUsagePercent;
    final barColor = pct > 0.8
        ? AppColors.error
        : pct > 0.5
            ? AppColors.tertiary
            : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Kullanılan: ${CurrencyFormatter.format(account.creditUsed)}',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              'Limit: ${CurrencyFormatter.format(account.creditLimit!)}',
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Henüz hesap yok', style: AppTypography.titleSm),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'İlk hesabınızı ekleyerek başlayın',
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Hesap Ekle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                minimumSize: const Size(180, 52),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Hesaplar yüklenemedi',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
