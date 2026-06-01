import 'package:flutter/material.dart';
import '../../../core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/account_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../bloc/account_bloc.dart';
import '../widgets/archived_account_tile.dart';

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
    final colors = context.colors;
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
              backgroundColor: colors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.of(context).archivedAccounts),
          backgroundColor: colors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        body: FutureBuilder<List<AccountModel>>(
          key: ValueKey(_refreshKey),
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  AppStrings.of(context).loadFailed,
                  style: AppTypography.bodyMd
                      .copyWith(color: colors.onSurfaceVariant),
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
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(AppStrings.of(context).noArchivedAccounts,
                        style: AppTypography.titleSm),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.of(context).archiveHint,
                      style: AppTypography.bodyMd
                          .copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: accounts.length,
              itemBuilder: (context, i) =>
                  ArchivedAccountTile(account: accounts[i]),
            );
          },
        ),
      ),
    );
  }
}
