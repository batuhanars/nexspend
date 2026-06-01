import 'package:flutter/material.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/ready_view.dart';
import '../../../core/di/injection.dart';
import '../../../data/models/receipt_model.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/family_repository.dart';
import '../../../data/repositories/receipt_repository.dart';
import '../bloc/receipt_preview_bloc.dart';

class ReceiptPreviewPage extends StatelessWidget {
  const ReceiptPreviewPage({
    super.key,
    required this.imagePath,
    required this.ocrResult,
    this.initialCategoryId,
    this.initialSharedBudgetId,
  });

  final String imagePath;
  final ReceiptParseResult ocrResult;
  final String? initialCategoryId;
  final String? initialSharedBudgetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReceiptPreviewBloc(
        receiptRepository: getIt<ReceiptRepository>(),
        categoryRepository: getIt<CategoryRepository>(),
        accountRepository: getIt<AccountRepository>(),
        familyRepository: getIt<FamilyRepository>(),
        initialResult: ocrResult,
        initialCategoryId: initialCategoryId,
        initialSharedBudgetId: initialSharedBudgetId,
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
          Navigator.of(context).pop(true);
        }
        if (state is ReceiptPreviewReady && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colors.errorContainer,
            ),
          );
        }
      },
      builder: (context, state) {
        final colors = context.colors;
        if (state is ReceiptPreviewInitial) {
          return Scaffold(
            backgroundColor: colors.surface,
            body: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }
        if (state is ReceiptPreviewError) {
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              title: Text(AppStrings.of(context).receiptPreviewTitle),
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: colors.error, size: 48),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    state.message,
                    style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppStrings.of(context).goBack),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ReceiptPreviewSuccess) {
          return Scaffold(
            backgroundColor: colors.surface,
            body: Center(
              child: CircularProgressIndicator(color: colors.primary),
            ),
          );
        }

        final ready = state as ReceiptPreviewReady;
        return ReadyView(imagePath: imagePath, state: ready);
      },
    );
  }
}
