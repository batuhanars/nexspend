import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../navigation/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_input_field.dart';

class VerifyResetCodePage extends StatefulWidget {
  const VerifyResetCodePage({super.key});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _tokenFocus = FocusNode();

  @override
  void dispose() {
    _tokenController.dispose();
    _tokenFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            VerifyResetCodeRequested(token: _tokenController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is VerifyResetCodeSuccess) {
          context.go(
            '${RouteNames.resetPassword}?token=${state.token}',
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pin_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    s.verifyCodeTitle,
                    style: AppTypography.headlineMd
                        .copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    s.verifyCodeSubtitle,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AuthInputField(
                    label: s.resetCodeLabel,
                    controller: _tokenController,
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    focusNode: _tokenFocus,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return s.resetCodeRequired;
                      if (t.length != 6) return s.resetCodeInvalid;
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return AuthButton(
                        label: s.continueButton,
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
