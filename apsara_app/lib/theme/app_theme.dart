import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFFE60023);
  static const primaryDark = Color(0xFFAD081B);
  static const text = Color(0xFF111111);
  static const textSecondary = Color(0xFF555555);
  static const textLight = Color(0xFF8E8E8E);
  static const surface = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF5F5F5);
  static const border = Color(0xFFEBEBEB);
  static const success = Color(0xFF22C55E);
  static const saleBg = Color(0xFFE8F5E9);
  static const saleText = Color(0xFF2E7D32);
}

ThemeData buildApsaraTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: AppColors.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.soft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.text),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
