import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import '../../features/agency/domain/agency_color_scheme.dart';

class StanomerTheme {
  static ThemeData get lightTheme => getThemeForScheme(const AgencyColorScheme.landlordScheme());

  static ThemeData getThemeForScheme(AgencyColorScheme scheme) {
    final baseTextTheme = GoogleFonts.outfitTextTheme().copyWith(
      headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: scheme.textPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: scheme.textPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: scheme.textPrimary),
      titleMedium: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.textPrimary),
      bodyLarge: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: scheme.textPrimary),
      bodyMedium: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w400, color: StanomerColors.textSecondary),
      labelLarge: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: StanomerColors.textSecondary),
      bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400, color: StanomerColors.textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: scheme.primary,
        onPrimary: StanomerColors.textInverse,
        surface: StanomerColors.bgPage,
        surfaceContainerHighest: scheme.bgWhite,
        error: StanomerColors.alertPrimary,
        outline: scheme.border,
      ),
      scaffoldBackgroundColor: StanomerColors.bgPage,
      textTheme: baseTextTheme,
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: StanomerColors.textInverse,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.38),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(StanomerRadius.lg)),
          elevation: 0,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(StanomerRadius.lg)),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.bgWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: StanomerColors.textSecondary),
        hintStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w400, color: StanomerColors.textTertiary),
        border: OutlineInputBorder(
          borderRadius: const BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: scheme.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: scheme.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(StanomerRadius.md),
          borderSide: BorderSide(color: StanomerColors.alertPrimary, width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(fontSize: 12, color: StanomerColors.alertPrimary),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.border,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.bgWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.textPrimary, size: 24),
        titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: scheme.textPrimary),
        shape: Border(bottom: BorderSide(color: scheme.border, width: 1)),
      ),
    );
  }
}
