import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../../navigation/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/otp_code_field.dart';

class VerifyResetCodePage extends StatefulWidget {
  const VerifyResetCodePage({super.key});

  @override
  State<VerifyResetCodePage> createState() => _VerifyResetCodePageState();
}

class _VerifyResetCodePageState extends State<VerifyResetCodePage> {
  final _tokenController = TextEditingController();
  String? _localError;

  @override
  void initState() {
    super.initState();
    _tokenController.addListener(() {
      if (_localError != null) setState(() => _localError = null);
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _tokenController.text.trim();
    final s = AppStrings.of(context);
    if (code.isEmpty) {
      setState(() => _localError = s.resetCodeRequired);
      return;
    }
    if (code.length != 6) {
      setState(() => _localError = s.resetCodeInvalid);
      return;
    }
    context.read<AuthBloc>().add(VerifyResetCodeRequested(token: code));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final colors = context.colors;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is VerifyResetCodeSuccess) {
          context.go(
            '${RouteNames.resetPassword}?token=${state.token}',
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: context.colors.error,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pin_outlined,
                    size: 28,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  s.verifyCodeTitle,
                  style: AppTypography.headlineMd
                      .copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  s.verifyCodeSubtitle,
                  style: AppTypography.bodyMd
                      .copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OtpCodeField(
                  controller: _tokenController,
                  errorText: _localError,
                  onCompleted: (_) => _submit(),
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
    );
  }
}
