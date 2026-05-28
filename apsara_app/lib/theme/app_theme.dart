import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ApsaraPalette extends ThemeExtension<ApsaraPalette> {
  const ApsaraPalette({
    required this.primary,
    required this.primaryDark,
    required this.secondary,
    required this.tertiary,
    required this.text,
    required this.textSecondary,
    required this.textLight,
    required this.surface,
    required this.surfaceWarm,
    required this.soft,
    required this.border,
    required this.success,
    required this.saleBg,
    required this.saleText,
    required this.chatCanvas,
    required this.chatOutgoing,
    required this.chatOutgoingSoft,
    required this.chatIncoming,
    required this.chatIncomingBorder,
    required this.chatAccent,
    required this.chatRead,
  });

  final Color primary;
  final Color primaryDark;
  final Color secondary;
  final Color tertiary;
  final Color text;
  final Color textSecondary;
  final Color textLight;
  final Color surface;
  final Color surfaceWarm;
  final Color soft;
  final Color border;
  final Color success;
  final Color saleBg;
  final Color saleText;
  final Color chatCanvas;
  final Color chatOutgoing;
  final Color chatOutgoingSoft;
  final Color chatIncoming;
  final Color chatIncomingBorder;
  final Color chatAccent;
  final Color chatRead;

  static const light = ApsaraPalette(
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    secondary: AppColors.secondary,
    tertiary: AppColors.tertiary,
    text: AppColors.text,
    textSecondary: AppColors.textSecondary,
    textLight: AppColors.textLight,
    surface: AppColors.surface,
    surfaceWarm: AppColors.surfaceWarm,
    soft: AppColors.soft,
    border: AppColors.border,
    success: AppColors.success,
    saleBg: AppColors.saleBg,
    saleText: AppColors.saleText,
    chatCanvas: AppColors.chatCanvas,
    chatOutgoing: AppColors.chatOutgoing,
    chatOutgoingSoft: AppColors.chatOutgoingSoft,
    chatIncoming: AppColors.chatIncoming,
    chatIncomingBorder: AppColors.chatIncomingBorder,
    chatAccent: AppColors.chatAccent,
    chatRead: AppColors.chatRead,
  );

  static const dark = ApsaraPalette(
    primary: Color(0xFFC7687D),
    primaryDark: Color(0xFFE9B9C5),
    secondary: Color(0xFF8BB7CB),
    tertiary: Color(0xFFE0B45B),
    text: Color(0xFFF6EEE7),
    textSecondary: Color(0xFFCFC1B5),
    textLight: Color(0xFF9F9186),
    surface: Color(0xFF151210),
    surfaceWarm: Color(0xFF1F1A16),
    soft: Color(0xFF2A231E),
    border: Color(0xFF3B312A),
    success: Color(0xFF77C99A),
    saleBg: Color(0xFF213A2C),
    saleText: Color(0xFFA3E0B9),
    chatCanvas: Color(0xFF12100F),
    chatOutgoing: Color(0xFF8A2A4C),
    chatOutgoingSoft: Color(0xFF3A2430),
    chatIncoming: Color(0xFF241F1B),
    chatIncomingBorder: Color(0xFF40362E),
    chatAccent: Color(0xFF8BB7CB),
    chatRead: Color(0xFF7AD3E8),
  );

  @override
  ApsaraPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? secondary,
    Color? tertiary,
    Color? text,
    Color? textSecondary,
    Color? textLight,
    Color? surface,
    Color? surfaceWarm,
    Color? soft,
    Color? border,
    Color? success,
    Color? saleBg,
    Color? saleText,
    Color? chatCanvas,
    Color? chatOutgoing,
    Color? chatOutgoingSoft,
    Color? chatIncoming,
    Color? chatIncomingBorder,
    Color? chatAccent,
    Color? chatRead,
  }) {
    return ApsaraPalette(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textLight: textLight ?? this.textLight,
      surface: surface ?? this.surface,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      soft: soft ?? this.soft,
      border: border ?? this.border,
      success: success ?? this.success,
      saleBg: saleBg ?? this.saleBg,
      saleText: saleText ?? this.saleText,
      chatCanvas: chatCanvas ?? this.chatCanvas,
      chatOutgoing: chatOutgoing ?? this.chatOutgoing,
      chatOutgoingSoft: chatOutgoingSoft ?? this.chatOutgoingSoft,
      chatIncoming: chatIncoming ?? this.chatIncoming,
      chatIncomingBorder: chatIncomingBorder ?? this.chatIncomingBorder,
      chatAccent: chatAccent ?? this.chatAccent,
      chatRead: chatRead ?? this.chatRead,
    );
  }

  @override
  ApsaraPalette lerp(ThemeExtension<ApsaraPalette>? other, double t) {
    if (other is! ApsaraPalette) {
      return this;
    }
    return ApsaraPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceWarm: Color.lerp(surfaceWarm, other.surfaceWarm, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      saleBg: Color.lerp(saleBg, other.saleBg, t)!,
      saleText: Color.lerp(saleText, other.saleText, t)!,
      chatCanvas: Color.lerp(chatCanvas, other.chatCanvas, t)!,
      chatOutgoing: Color.lerp(chatOutgoing, other.chatOutgoing, t)!,
      chatOutgoingSoft:
          Color.lerp(chatOutgoingSoft, other.chatOutgoingSoft, t)!,
      chatIncoming: Color.lerp(chatIncoming, other.chatIncoming, t)!,
      chatIncomingBorder:
          Color.lerp(chatIncomingBorder, other.chatIncomingBorder, t)!,
      chatAccent: Color.lerp(chatAccent, other.chatAccent, t)!,
      chatRead: Color.lerp(chatRead, other.chatRead, t)!,
    );
  }
}

extension ApsaraThemeContext on BuildContext {
  ApsaraPalette get appColors =>
      Theme.of(this).extension<ApsaraPalette>() ?? ApsaraPalette.light;
}

class ApsaraThemeController extends ChangeNotifier {
  static const _storageKey = 'apsara_dark_mode_enabled';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final enabled = preferences.getBool(_storageKey) ?? false;
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    final next = enabled ? ThemeMode.dark : ThemeMode.light;
    if (_mode == next) {
      return;
    }
    _mode = next;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, enabled);
  }
}

ThemeData buildApsaraTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? ApsaraPalette.dark : ApsaraPalette.light;
  const roundedDialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: colors.primary,
      primary: colors.primary,
      onPrimary: isDark ? const Color(0xFF241014) : Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF4A1E2D) : const Color(0xFFF4D8E1),
      onPrimaryContainer:
          isDark ? const Color(0xFFFFDCE5) : AppColors.primaryDark,
      secondary: colors.secondary,
      onSecondary: Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF213844) : const Color(0xFFD8E8EF),
      onSecondaryContainer:
          isDark ? const Color(0xFFD4EEF8) : const Color(0xFF123142),
      tertiary: colors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer:
          isDark ? const Color(0xFF473716) : const Color(0xFFF3E3C1),
      onTertiaryContainer:
          isDark ? const Color(0xFFFFE6AD) : const Color(0xFF4A3108),
      surface: colors.surface,
      onSurface: colors.text,
      surfaceContainerHighest: colors.soft,
      outline: colors.border,
    ),
    extensions: [colors],
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    dividerColor: colors.border,
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: colors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        color: colors.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: colors.textSecondary,
      ),
    ),
    iconTheme: IconThemeData(color: colors.text),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.text,
      surfaceTintColor: colors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colors.text),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: colors.text,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: colors.text,
      ),
      contentTextStyle: TextStyle(
        fontSize: 13,
        color: colors.textSecondary,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      modalBackgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      shape: roundedDialogShape,
      dragHandleColor: colors.border,
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 1,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text,
        side: BorderSide(color: colors.border),
        textStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.soft,
      selectedColor: colors.primary,
      secondarySelectedColor: colors.primary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: colors.text,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      secondaryLabelStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surface,
      surfaceTintColor: colors.surface,
      textStyle: TextStyle(
        color: colors.text,
        fontSize: 13,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.text,
      contentTextStyle: TextStyle(
        color: colors.surface,
        fontSize: 13,
      ),
      actionTextColor: colors.tertiary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.soft,
      hintStyle: TextStyle(color: colors.textLight, fontSize: 13),
      prefixIconColor: colors.textLight,
      prefixStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
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
        borderSide: BorderSide(color: colors.text),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
