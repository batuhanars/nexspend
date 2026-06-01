import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/account_model.dart';
import '../bloc/account_bloc.dart';

class ArchivedAccountTile extends StatelessWidget {
  const ArchivedAccountTile({super.key, required this.account});
  final AccountModel account;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colorForAccount(account).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(account.iconData,
                      size: 20, color: context.colorForAccount(account)),
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
                        account.type.labelOf(context),
                        style: AppTypography.bodySm
                            .copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<AccountBloc>().add(
                            AccountRestoreRequested(account.id),
                          ),
                  child: Text(
                    AppStrings.of(context).restoreBtn,
                    style: TextStyle(color: colors.primary),
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
