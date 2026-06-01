import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/services/local_auth_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/validators.dart';
import '../../../navigation/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_input_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _showBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final storage = getIt<SecureStorage>();
      final biometricEnabled = await storage.getBiometricEnabled();
      final hasToken = await storage.hasTokens();
      if (!biometricEnabled || !hasToken) return;

      final localAuth = getIt<LocalAuthService>();
      final isAvailable = await localAuth.isAvailable();

      if (!isAvailable) {
        if (mounted) context.go(RouteNames.home);
        return;
      }

      if (mounted) {
        setState(() => _showBiometric = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AuthBloc>().add(const BiometricAuthRequested());
          }
        });
      }
    } catch (_) {
      // Biyometrik kontrol başarısız olursa sessizce geç
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RouteNames.home);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: context.colors.error,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 56),
                  _Header(),
                  const SizedBox(height: AppSpacing.xxl),
                  AuthInputField(
                    label: AppStrings.of(context).emailLabel,
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    focusNode: _emailFocus,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthInputField(
                    label: AppStrings.of(context).passwordLabel,
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    focusNode: _passwordFocus,
                    autofillHints: const [AutofillHints.password],
                    validator: Validators.password,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RouteNames.forgotPassword),
                      child: Text(
                        AppStrings.of(context).forgotPasswordAction,
                        style: AppTypography.bodySm.copyWith(
                          color: context.colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return AuthButton(
                        label: AppStrings.of(context).loginAction,
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return GoogleSignInButton(
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(const GoogleSignInRequested()),
                      );
                    },
                  ),
                  if (_showBiometric) ...[
                    const SizedBox(height: AppSpacing.md),
                    _BiometricButton(
                      onPressed: () => context
                          .read<AuthBloc>()
                          .add(const BiometricAuthRequested()),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  _RegisterLink(),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 36,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.of(context).welcomeBack,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMd.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.of(context).signInSubtitle,
          style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: colors.outlineVariant.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AppStrings.of(context).orDivider,
            style: AppTypography.bodySm.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Divider(
            color: colors.outlineVariant.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.fingerprint_rounded, size: 24),
        label: Text(
          AppStrings.of(context).biometricLoginBtn,
          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(
            color: colors.primary.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
    );
  }
}

class _RegisterLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.of(context).noAccount,
          style: AppTypography.bodyMd.copyWith(color: colors.onSurfaceVariant),
        ),
        TextButton(
          onPressed: () => context.push(RouteNames.register),
          style: TextButton.styleFrom(padding: const EdgeInsets.only(left: AppSpacing.xs)),
          child: Text(
            AppStrings.of(context).registerAction,
            style: AppTypography.bodyMd.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
