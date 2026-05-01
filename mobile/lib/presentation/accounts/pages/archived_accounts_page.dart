import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../bloc/account_bloc.dart';

class ArchivedAccountsPage extends StatefulWidget {
  const ArchivedAccountsPage({super.key});

  @override
  State<ArchivedAccountsPage> createState() => _ArchivedAccountsPageState();
}

class _ArchivedAccountsPageState extends State<ArchivedAccountsPage> {
  int _refreshKey = 0;

  Future<List<AccountModel>> _load() => getIt<AccountRepository>()
      .getAccounts(includeArchived: true)
      .then((list) => list.where((a) => a.isArchived).toList());

  @override
  Widget build(BuildContext context) {
    return BlocListener<AccountBloc, AccountState>(
      listener: (context, state) {
        if (state is AccountActionDone) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          setState(() => _refreshKey++);
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
        appBar: AppBar(
          title: const Text('Arşivlenmiş Hesaplar'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: FutureBuilder<List<AccountModel>>(
          key: ValueKey(_refreshKey),
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Yüklenemedi',
                  style: AppTypography.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              );
            }
            final accounts = snapshot.data ?? [];
            if (accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.archive_outlined,
                      size: 64,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Arşivlenmiş hesap yok',
                        style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Hesap detayından arşivleyebilirsiniz',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: accounts.length,
              itemBuilder: (context, i) =>
                  _AccountTile(account: accounts[i]),
            );
          },
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        final isLoading = state is AccountSubmitting;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pagePadding,
            vertical: AppSpacing.xs,
          ),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: account.cardColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    account.iconData,
                    size: 20,
                    color: account.cardColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: AppTypography.bodyMd
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        account.type.label,
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context
                          .read<AccountBloc>()
                          .add(AccountRestoreRequested(account.id)),
                  child: Text(
                    'Geri Yükle',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
