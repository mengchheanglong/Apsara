import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF8A1538);
  static const primaryDark = Color(0xFF5D0B24);
  static const secondary = Color(0xFF234C63);
  static const tertiary = Color(0xFFB8862B);
  static const text = Color(0xFF211A16);
  static const textSecondary = Color(0xFF645A52);
  static const textLight = Color(0xFF92867B);
  static const surface = Color(0xFFFFFCF7);
  static const surfaceWarm = Color(0xFFF9F3EA);
  static const soft = Color(0xFFF2EADF);
  static const border = Color(0xFFE3D6C8);
  static const success = Color(0xFF287A4D);
  static const saleBg = Color(0xFFE6F1E7);
  static const saleText = Color(0xFF25613D);
  static const chatCanvas = Color(0xFFFFF8EF);
  static const chatOutgoing = Color(0xFF7D1F3D);
  static const chatOutgoingSoft = Color(0xFFE9CDD7);
  static const chatIncoming = Color(0xFFF2E8DA);
  static const chatIncomingBorder = Color(0xFFE0CFBC);
  static const chatAccent = Color(0xFF234C63);
  static const chatRead = Color(0xFF2F7F95);
}

ThemeData buildApsaraTheme() {
  const roundedDialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFF4D8E1),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFD8E8EF),
      onSecondaryContainer: const Color(0xFF123142),
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFF3E3C1),
      onTertiaryContainer: const Color(0xFF4A3108),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      surfaceContainerHighest: AppColors.soft,
      outline: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    canvasColor: AppColors.surface,
    dividerColor: AppColors.border,
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
    iconTheme: const IconThemeData(color: AppColors.text),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      contentTextStyle: TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: roundedDialogShape,
      dragHandleColor: AppColors.border,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.soft,
      selectedColor: AppColors.primary,
      secondarySelectedColor: AppColors.primary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      textStyle: TextStyle(
        color: AppColors.text,
        fontSize: 13,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.text,
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      actionTextColor: Color(0xFFF3E3C1),
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
