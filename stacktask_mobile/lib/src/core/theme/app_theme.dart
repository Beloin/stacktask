import 'package:flutter/material.dart';

class AppColors {
  static const accent = Color(0xFF6C5CE7);
  static const accentLight = Color(0xFFA29BFE);
  static const danger = Color(0xFFFF6B6B);
  static const success = Color(0xFF00CEC9);
  static const background1 = Color(0xFF0F0C29);
  static const background2 = Color(0xFF302B63);
  static const background3 = Color(0xFF24243E);
  static const cardSurface = Color(0xF2FFFFFF);
  static const textPrimary = Color(0xFF2D3436);
  static const textSecondary = Color(0xFF636E72);
  static const textMuted = Color(0x80FFFFFF);
  static const textWhite = Color(0xFFFFFFFF);
  static const tagPillPink = Color(0xFFFD79A8);
  static const tagPillTeal = Color(0xFF00CEC9);
  static const modalBackground = Color(0xFF1A1A2E);
  static const inputBorder = Color(0x1AFFFFFF);
  static const inputFill = Color(0x0FFFFFFF);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background1,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentLight,
        surface: AppColors.background1,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: AppColors.textWhite,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.25,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: AppColors.accentLight,
        ),
      ),
    );
  }
}