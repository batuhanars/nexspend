import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/ready_view.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/receipt_repository.dart';
import '../bloc/receipt_preview_bloc.dart';

class ReceiptPreviewPage extends StatelessWidget {
  const ReceiptPreviewPage({
    super.key,
    required this.imagePath,
    required this.ocrResult,
  });

  final String imagePath;
  final ReceiptParseResult ocrResult;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptPreviewBloc(
        receiptRepository: getIt<ReceiptRepository>(),
        categoryRepository: getIt<CategoryRepository>(),
        accountRepository: getIt<AccountRepository>(),
        initialResult: ocrResult,
      ),
      child: _ReceiptPreviewView(imagePath: imagePath),
    );
  }
}

class _ReceiptPreviewView extends StatelessWidget {
  const _ReceiptPreviewView({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReceiptPreviewBloc, ReceiptPreviewState>(
      listener: (context, state) {
        if (state is ReceiptPreviewSuccess) {
          // Pop back to ReceiptScannerPage with success=true.
          // ReceiptScannerPage owns the GoRouter pop + dashboard refresh.
          Navigator.of(context).pop(true);
        }
        if (state is ReceiptPreviewReady && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.errorContainer,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ReceiptPreviewInitial) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (state is ReceiptPreviewError) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              title: const Text('Makbuz Önizleme'),
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    state.message,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri Dön'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ReceiptPreviewSuccess) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final ready = state as ReceiptPreviewReady;
        return ReadyView(imagePath: imagePath, state: ready);
      },
    );
  }
}
