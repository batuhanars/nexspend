import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_colors.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/data/repositories/receipt_repository.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_history_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/receipt_history_tile.dart';

class ReceiptHistoryPage extends StatelessWidget {
  const ReceiptHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptHistoryBloc(
        receiptRepository: getIt<ReceiptRepository>(),
      )..add(ReceiptHistoryLoadRequested()),
      child: const _ReceiptHistoryView(),
    );
  }
}

class _ReceiptHistoryView extends StatelessWidget {
  const _ReceiptHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Fiş Geçmişi', style: AppTypography.headlineSm),
        centerTitle: false,
      ),
      body: BlocBuilder<ReceiptHistoryBloc, ReceiptHistoryState>(
        builder: (context, state) => switch (state) {
          ReceiptHistoryLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ReceiptHistoryError(:final message) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    message,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonal(
                    onPressed: () => context
                        .read<ReceiptHistoryBloc>()
                        .add(ReceiptHistoryRefreshRequested()),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ReceiptHistoryLoaded(:final receipts) when receipts.isEmpty =>
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Henüz fiş taranmadı.',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ReceiptHistoryLoaded(:final receipts) => RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => context
                  .read<ReceiptHistoryBloc>()
                  .add(ReceiptHistoryRefreshRequested()),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: receipts.length,
                itemBuilder: (_, i) =>
                    ReceiptHistoryTile(receipt: receipts[i]),
              ),
            ),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}
