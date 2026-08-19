import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand palette — kept identical to the investor PDF and the in-app
/// Features (HTML) page so the whole product feels like one thing.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF0B1F3A);
  static const navyLight = Color(0xFF16335A);
  static const gold = Color(0xFFC98A2C);
  static const goldLight = Color(0xFFE0AC55);

  static const background = Color(0xFFF4F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEEF1F7);

  static const textPrimary = Color(0xFF161C2A);
  static const textMuted = Color(0xFF5B6272);
  static const border = Color(0x1A0B1F3A); // navy @ 10%

  static const success = Color(0xFF1E8E5A);
  static const danger = Color(0xFFC0392B);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme = GoogleFonts.tajawalTextTheme();
    final headingFont = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: headingFont.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        headlineMedium: headingFont.headlineMedium
            ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        titleLarge: headingFont.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        titleMedium: headingFont.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        bodySmall: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headingFont.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.navy,
        labelStyle: textTheme.bodySmall!.copyWith(color: AppColors.textMuted),
        secondaryLabelStyle: textTheme.bodySmall!.copyWith(color: Colors.white),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
      ),
      dividerColor: AppColors.border,
    );
  }
}
