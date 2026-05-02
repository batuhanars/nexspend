import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../bloc/transactions_bloc.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.lg),
          Text(message,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonal(
            onPressed: () => context
                .read<TransactionsBloc>()
                .add(TransactionsLoadRequested()),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
}
