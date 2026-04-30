import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // Display-LG — Ana bakiyeler (₺45.230,00)
  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.1,
    letterSpacing: -1.0,
  );

  // Display-MD
  static const TextStyle displayMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.15,
    letterSpacing: -0.5,
  );

  // Headline-MD — Bölüm başlıkları
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.25,
    letterSpacing: -0.25,
  );

  // Headline-SM
  static const TextStyle headlineSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.3,
  );

  // Title-SM — Kart başlıkları
  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Body-MD — İşlem detayları
  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Body-SM
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
    letterSpacing: 0.2,
  );

  // Label-SM — Uppercase overline'lar (DÜN, GELİR)
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.45,
    letterSpacing: 1.0,
  );

  // Label-MD
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.45,
    letterSpacing: 0.5,
  );
}
