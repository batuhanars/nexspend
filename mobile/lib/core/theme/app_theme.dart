import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_spacing.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(Color onSurface, Color onSurfaceVariant) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 56, fontWeight: FontWeight.w700, color: onSurface, height: 1.1, letterSpacing: -1.0),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700, color: onSurface, height: 1.15, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: onSurface, height: 1.25, letterSpacing: -0.25),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, height: 1.3),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.4, letterSpacing: 0.1),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5, letterSpacing: 0.1),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVariant, height: 1.5, letterSpacing: 0.2),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: onSurfaceVariant, height: 1.45, letterSpacing: 1.0),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant, height: 1.45, letterSpacing: 0.5),
      ),
    );
  }

  static ThemeData get dark {
    const p = AppPalette.dark;
    final textTheme = _buildTextTheme(p.onSurface, p.onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        surface: p.surface,
        onSurface: p.onSurface,
        primary: p.primary,
        onPrimary: p.onPrimary,
        primaryContainer: p.primaryContainer,
        onPrimaryContainer: p.onPrimaryContainer,
        secondary: p.secondary,
        onSecondary: p.onSecondary,
        secondaryContainer: p.secondaryContainer,
        onSecondaryContainer: p.onSurface,
        tertiary: p.tertiary,
        onTertiary: p.onTertiary,
        tertiaryContainer: p.tertiaryContainer,
        onTertiaryContainer: p.onSurface,
        error: p.error,
        onError: p.onError,
        errorContainer: p.errorContainer,
        onErrorContainer: p.onSurface,
        outline: p.outline,
        outlineVariant: p.outlineVariant,
        inverseSurface: p.inverseSurface,
        onInverseSurface: p.inverseOnSurface,
        inversePrimary: p.inversePrimary,
        surfaceContainerLowest: p.surfaceContainerLowest,
        surfaceContainerLow: p.surfaceContainerLow,
        surfaceContainer: p.surfaceContainer,
        surfaceContainerHigh: p.surfaceContainerHigh,
        surfaceContainerHighest: p.surfaceContainerHighest,
      ),

      scaffoldBackgroundColor: p.surface,
      textTheme: textTheme,
      extensions: const [AppPalette.dark],

      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: textTheme.headlineSmall,
      ),

      cardTheme: CardThemeData(
        color: p.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(
            color: p.outlineVariant.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: p.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceContainerHigh,
        selectedColor: p.primaryContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.onSurface,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: p.primary,
        unselectedItemColor: p.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
      ),
    );
  }

  static ThemeData get light {
    const p = AppPalette.light;
    final textTheme = _buildTextTheme(p.onSurface, p.onSurfaceVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        surface: Color(0xFFFBF9F9),
        onSurface: Color(0xFF1B1B1B),
        primary: Color(0xFF4858AB),
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFDEE0FF),
        onPrimaryContainer: Color(0xFF001257),
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
        outline: Color(0xFF767680),
        outlineVariant: Color(0xFFC7C6D0),
        inverseSurface: Color(0xFF303030),
        onInverseSurface: Color(0xFFF3F0EF),
        inversePrimary: Color(0xFFBAC3FF),
        surfaceContainerLowest: Color(0xFFFFFFFF),
        surfaceContainerLow: Color(0xFFF5F3F3),
        surfaceContainer: Color(0xFFEFEDED),
        surfaceContainerHigh: Color(0xFFE9E7E7),
        surfaceContainerHighest: Color(0xFFE3E2E2),
      ),

      scaffoldBackgroundColor: p.surface,
      textTheme: textTheme,
      extensions: const [AppPalette.light],

      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: p.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: textTheme.headlineSmall,
      ),

      cardTheme: CardThemeData(
        color: p.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(
            color: p.outlineVariant.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: p.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: p.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceContainerHigh,
        selectedColor: p.primaryContainer,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: p.onSurface,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: p.primary,
        unselectedItemColor: p.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
      ),
    );
  }
}
