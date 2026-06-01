import 'package:flutter/material.dart';
import 'package:wallet_app/data/models/account_model.dart';
import 'package:wallet_app/data/models/debt_model.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.primaryFixed,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.income,
    required this.expense,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color surface;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color primaryFixed;
  final Color inversePrimary;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color income;
  final Color expense;
  final Color success;
  final Color warning;
  final Color danger;

  static const AppPalette dark = AppPalette(
    surface: Color(0xFF131313),
    surfaceDim: Color(0xFF131313),
    surfaceBright: Color(0xFF393939),
    surfaceContainerLowest: Color(0xFF0E0E0E),
    surfaceContainerLow: Color(0xFF1C1B1B),
    surfaceContainer: Color(0xFF201F1F),
    surfaceContainerHigh: Color(0xFF2A2A2A),
    surfaceContainerHighest: Color(0xFF353534),
    primary: Color(0xFFBAC3FF),
    onPrimary: Color(0xFF15267B),
    primaryContainer: Color(0xFF3C4C9F),
    onPrimaryContainer: Color(0xFFBAC3FF),
    primaryFixed: Color(0xFFDEE0FF),
    inversePrimary: Color(0xFF4858AB),
    secondary: Color(0xFF70D8C8),
    onSecondary: Color(0xFF003731),
    secondaryContainer: Color(0xFF32A192),
    onSecondaryContainer: Color(0xFFE5E2E1),
    tertiary: Color(0xFFFFB68F),
    onTertiary: Color(0xFF542100),
    tertiaryContainer: Color(0xFF8A3B00),
    onTertiaryContainer: Color(0xFFE5E2E1),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFE5E2E1),
    onSurface: Color(0xFFE5E2E1),
    onSurfaceVariant: Color(0xFFC6C5D4),
    outline: Color(0xFF8F8F9E),
    outlineVariant: Color(0xFF454652),
    inverseSurface: Color(0xFFE5E2E1),
    inverseOnSurface: Color(0xFF313030),
    income: Color(0xFF70D8C8),
    expense: Color(0xFFFFB68F),
    success: Color(0xFF70D8C8),
    warning: Color(0xFFFFD54F),
    danger: Color(0xFFFFB4AB),
  );

  static const AppPalette light = AppPalette(
    surface: Color(0xFFFBF9F9),
    surfaceDim: Color(0xFFDBD9D9),
    surfaceBright: Color(0xFFFBF9F9),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF5F3F3),
    surfaceContainer: Color(0xFFEFEDED),
    surfaceContainerHigh: Color(0xFFE9E7E7),
    surfaceContainerHighest: Color(0xFFE3E2E2),
    primary: Color(0xFF4858AB),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDEE0FF),
    onPrimaryContainer: Color(0xFF001257),
    primaryFixed: Color(0xFFDEE0FF),
    inversePrimary: Color(0xFFBAC3FF),
    secondary: Color(0xFF00796B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFF9FF2E2),
    onSecondaryContainer: Color(0xFF00201C),
    tertiary: Color(0xFF964900),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBC8),
    onTertiaryContainer: Color(0xFF331300),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    onSurface: Color(0xFF1B1B1B),
    onSurfaceVariant: Color(0xFF45464E),
    outline: Color(0xFF767680),
    outlineVariant: Color(0xFFC7C6D0),
    inverseSurface: Color(0xFF303030),
    inverseOnSurface: Color(0xFFF3F0EF),
    income: Color(0xFF00796B),
    expense: Color(0xFF964900),
    success: Color(0xFF00796B),
    warning: Color(0xFF8A6100),
    danger: Color(0xFFBA1A1A),
  );

  @override
  AppPalette copyWith({
    Color? surface,
    Color? surfaceDim,
    Color? surfaceBright,
    Color? surfaceContainerLowest,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? primaryFixed,
    Color? inversePrimary,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? income,
    Color? expense,
    Color? success,
    Color? warning,
    Color? danger,
  }) =>
      AppPalette(
        surface: surface ?? this.surface,
        surfaceDim: surfaceDim ?? this.surfaceDim,
        surfaceBright: surfaceBright ?? this.surfaceBright,
        surfaceContainerLowest:
            surfaceContainerLowest ?? this.surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
        surfaceContainer: surfaceContainer ?? this.surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
        surfaceContainerHighest:
            surfaceContainerHighest ?? this.surfaceContainerHighest,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primaryContainer: primaryContainer ?? this.primaryContainer,
        onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
        primaryFixed: primaryFixed ?? this.primaryFixed,
        inversePrimary: inversePrimary ?? this.inversePrimary,
        secondary: secondary ?? this.secondary,
        onSecondary: onSecondary ?? this.onSecondary,
        secondaryContainer: secondaryContainer ?? this.secondaryContainer,
        onSecondaryContainer:
            onSecondaryContainer ?? this.onSecondaryContainer,
        tertiary: tertiary ?? this.tertiary,
        onTertiary: onTertiary ?? this.onTertiary,
        tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
        error: error ?? this.error,
        onError: onError ?? this.onError,
        errorContainer: errorContainer ?? this.errorContainer,
        onErrorContainer: onErrorContainer ?? this.onErrorContainer,
        onSurface: onSurface ?? this.onSurface,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
        outline: outline ?? this.outline,
        outlineVariant: outlineVariant ?? this.outlineVariant,
        inverseSurface: inverseSurface ?? this.inverseSurface,
        inverseOnSurface: inverseOnSurface ?? this.inverseOnSurface,
        income: income ?? this.income,
        expense: expense ?? this.expense,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      surfaceBright: Color.lerp(surfaceBright, other.surfaceBright, t)!,
      surfaceContainerLowest:
          Color.lerp(surfaceContainerLowest, other.surfaceContainerLowest, t)!,
      surfaceContainerLow:
          Color.lerp(surfaceContainerLow, other.surfaceContainerLow, t)!,
      surfaceContainer:
          Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      surfaceContainerHighest:
          Color.lerp(surfaceContainerHighest, other.surfaceContainerHighest, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimaryContainer:
          Color.lerp(onPrimaryContainer, other.onPrimaryContainer, t)!,
      primaryFixed: Color.lerp(primaryFixed, other.primaryFixed, t)!,
      inversePrimary: Color.lerp(inversePrimary, other.inversePrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      onSecondaryContainer:
          Color.lerp(onSecondaryContainer, other.onSecondaryContainer, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer:
          Color.lerp(tertiaryContainer, other.tertiaryContainer, t)!,
      onTertiaryContainer:
          Color.lerp(onTertiaryContainer, other.onTertiaryContainer, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      onErrorContainer:
          Color.lerp(onErrorContainer, other.onErrorContainer, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      inverseOnSurface:
          Color.lerp(inverseOnSurface, other.inverseOnSurface, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;

  Color getColorForAccountType(AccountType type) {
    final palette = colors;
    return switch (type) {
      AccountType.BANK => palette.primary,
      AccountType.CASH => palette.secondary,
      AccountType.CREDIT_CARD => palette.warning,
      AccountType.INVESTMENT => palette.tertiary,
    };
  }

  /// Hesabın efektif rengi: özel hex rengi varsa onu, yoksa tema-duyarlı tip rengini döner.
  Color colorForAccount(AccountModel account) =>
      account.customColor ?? getColorForAccountType(account.type);

  Color getColorForDebtType(DebtType type) {
    final palette = colors;
    return type == DebtType.LENT ? palette.secondary : palette.tertiary;
  }

  Color getColorForDebtStatus(DebtStatus status) {
    final palette = colors;
    return switch (status) {
      DebtStatus.PENDING => palette.warning,
      DebtStatus.PAID => palette.secondary,
      DebtStatus.OVERDUE => palette.error,
    };
  }
}
