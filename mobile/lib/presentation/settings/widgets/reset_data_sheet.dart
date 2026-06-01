import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/app_palette.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/constants/app_spacing.dart';
import 'package:wallet_app/core/constants/app_typography.dart';
import 'package:wallet_app/core/l10n/app_strings.dart';
import '../bloc/settings_bloc.dart';

class ResetDataSheet extends StatefulWidget {
  const ResetDataSheet({super.key});

  @override
  State<ResetDataSheet> createState() => _ResetDataSheetState();
}

class _ResetDataSheetState extends State<ResetDataSheet> {
  final _controller = TextEditingController();
  bool _canConfirm = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final s = AppStrings.of(context);
    final isMatch = _controller.text == s.resetConfirmWord;
    if (isMatch != _canConfirm) {
      setState(() => _canConfirm = isMatch);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsResetSuccess || state is SettingsResetFailure) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.xl,
              AppSpacing.pagePadding,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.error,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.resetConfirmTitle,
                        style: AppTypography.titleSm.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.resetConfirmBody,
                  style: AppTypography.bodyMd.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  controller: _controller,
                  style: AppTypography.bodyMd.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: s.resetConfirmInputHint,
                    hintStyle: AppTypography.bodyMd.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: context.colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final isLoading = state is SettingsResetting;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _canConfirm && !isLoading
                              ? context.colors.error
                              : context.colors.error.withAlpha(80),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusXl),
                          ),
                        ),
                        onPressed: (_canConfirm && !isLoading)
                            ? () {
                                context
                                    .read<SettingsBloc>()
                                    .add(const SettingsResetRequested());
                              }
                            : null,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                s.resetConfirmBtn,
                                style: AppTypography.bodyMd.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                    ),
                    child: Text(
                      AppStrings.of(context).cancel,
                      style: AppTypography.bodyMd.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
