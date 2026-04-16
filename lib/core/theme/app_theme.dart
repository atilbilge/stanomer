import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class StanomerTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.nunitoTextTheme().copyWith(
      headlineLarge: GoogleFonts.dmSerifDisplay(fontSize: 32, fontWeight: FontWeight.w400, color: StanomerColors.textPrimary),
      headlineMedium: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: StanomerColors.textPrimary),
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: StanomerColors.textPrimary),
      titleMedium: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700, color: StanomerColors.textPrimary),
      bodyLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: StanomerColors.textPrimary),
      bodyMedium: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: StanomerColors.textSecondary),
      labelLarge: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: StanomerColors.textSecondary),
      bodySmall: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w400, color: StanomerColors.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: StanomerColors.brandPrimary,
        onPrimary: StanomerColors.textInverse,
        surface: StanomerColors.bgPage,
        surfaceContainerHighest: StanomerColors.bgCard,
        error: StanomerColors.alertPrimary,
        outline: StanomerColors.borderInput,
      ),
      scaffoldBackgroundColor: StanomerColors.bgPage,
      textTheme: baseTextTheme,
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: StanomerColors.brandPrimary,
          foregroundColor: StanomerColors.textInverse,
          disabledBackgroundColor: StanomerColors.brandPrimary.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(StanomerRadius.lg)),
          elevation: 0,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: StanomerColors.brandPrimary,
          side: const BorderSide(color: StanomerColors.brandPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(StanomerRadius.lg)),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: StanomerColors.brandPrimary,
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: StanomerColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600, color: StanomerColors.textSecondary),
        hintStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w400, color: StanomerColors.textTertiary),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: StanomerColors.borderInput, width: 1.5),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: StanomerColors.borderInput, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: StanomerColors.borderFocused, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: StanomerColors.alertPrimary, width: 1.5),
        ),
        errorStyle: GoogleFonts.nunito(fontSize: 12, color: StanomerColors.alertPrimary),
      ),

      dividerTheme: const DividerThemeData(
        color: StanomerColors.borderDefault,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: StanomerColors.bgCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: StanomerColors.textPrimary, size: 24),
        titleTextStyle: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w800, color: StanomerColors.textPrimary),
        shape: const Border(bottom: BorderSide(color: StanomerColors.borderDefault, width: 1)),
      ),
    );
  }
}
