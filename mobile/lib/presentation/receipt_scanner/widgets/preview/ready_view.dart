import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/bloc/receipt_preview_bloc.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/account_dropdown.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/amount_field.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/category_dropdown.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/confidence_badge.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/date_field.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/duplicate_warning.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/field_label.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/image_thumbnail.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/items_section.dart';
import 'package:wallet_app/presentation/receipt_scanner/widgets/preview/merchant_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class ReadyView extends StatefulWidget {
  const ReadyView({super.key, required this.imagePath, required this.state});
  final String imagePath;
  final ReceiptPreviewReady state;

  @override
  State<ReadyView> createState() => _ReadyViewState();
}

class _ReadyViewState extends State<ReadyView> {
  late TextEditingController _amountCtrl;
  late TextEditingController _merchantCtrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _merchantCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    super.dispose();
  }

  void _syncControllers(ReceiptPreviewReady state) {
    if (!_initialized) {
      _amountCtrl.text = state.effectiveAmount > 0
          ? state.effectiveAmount.toStringAsFixed(2)
          : '';
      _merchantCtrl.text = state.effectiveMerchant;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncControllers(widget.state);
    final s = widget.state;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Makbuz Önizleme'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (s.isSubmitting)
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
            TextButton(
              onPressed: () => context.read<ReceiptPreviewBloc>().add(
                const ReceiptPreviewConfirmed(),
              ),
              child: Text(
                'Kaydet',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.lg,
        ),
        children: [
          // Duplicate warning
          if (s.result.isDuplicate) ...[
            DuplicateWarning(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Receipt image thumbnail
          ImageThumbnail(imagePath: widget.imagePath),
          const SizedBox(height: AppSpacing.xl),

          // Confidence indicator
          ConfidenceBadge(confidence: s.result.confidence),
          const SizedBox(height: AppSpacing.xl),

          // Amount
          FieldLabel(text: 'Tutar'),
          const SizedBox(height: AppSpacing.sm),
          AmountField(controller: _amountCtrl, state: s),
          const SizedBox(height: AppSpacing.lg),

          // Merchant
          FieldLabel(text: 'İşyeri'),
          const SizedBox(height: AppSpacing.sm),
          MerchantField(controller: _merchantCtrl, state: s),
          const SizedBox(height: AppSpacing.lg),

          // Date
          FieldLabel(text: 'Tarih'),
          const SizedBox(height: AppSpacing.sm),
          DateField(state: s),
          const SizedBox(height: AppSpacing.lg),

          // Category
          FieldLabel(text: 'Kategori'),
          const SizedBox(height: AppSpacing.sm),
          CategoryDropdown(state: s),
          const SizedBox(height: AppSpacing.lg),

          // Account
          FieldLabel(text: 'Hesap'),
          const SizedBox(height: AppSpacing.sm),
          AccountDropdown(state: s),
          const SizedBox(height: AppSpacing.xl),

          // Items list
          if (s.result.items.isNotEmpty) ...[
            ItemsSection(items: s.result.items),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: s.isSubmitting
                  ? null
                  : () => context.read<ReceiptPreviewBloc>().add(
                      const ReceiptPreviewConfirmed(),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: Text(
                'İşlem Oluştur',
                style: AppTypography.titleSm.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Rescan button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurface,
                side: const BorderSide(color: AppColors.onSurfaceVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: const Text('Tekrar Tara'),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
