import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Palette
  static const Color surface = Color(0xFF131313);
  static const Color primary = Color(0xFFBAC3FF);
  static const Color primaryContainer = Color(0xFF3C4C9F);
  static const Color primaryFixed = Color(0xFFDEE0FF);
  static const Color secondary = Color(0xFF70D8C8); // Gelir / Mint yeşil
  static const Color secondaryContainer = Color(0xFF32A192);
  static const Color tertiary = Color(0xFFFFB68F); // Gider / Şeftali-turuncu
  static const Color tertiaryContainer = Color(0xFF8A3B00);
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  // Surface Variants (Tonal Layering)
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF393939);

  // Text / On-Colors
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC6C5D4);
  static const Color onPrimary = Color(0xFF15267B);
  static const Color onPrimaryContainer = Color(0xFFBAC3FF);
  static const Color onSecondary = Color(0xFF003731);
  static const Color onTertiary = Color(0xFF542100);
  static const Color onError = Color(0xFF690005);

  // Outline
  static const Color outline = Color(0xFF8F8F9E);
  static const Color outlineVariant = Color(0xFF454652);

  // Inverse
  static const Color inverseSurface = Color(0xFFE5E2E1);
  static const Color inverseOnSurface = Color(0xFF313030);
  static const Color inversePrimary = Color(0xFF4858AB);

  // Semantic (Alias)
  static const Color income = secondary; // Gelir
  static const Color expense = tertiary; // Gider
  static const Color success = secondary;
  static const Color warning = Color(0xFFFFD54F);
  static const Color danger = error;
}
