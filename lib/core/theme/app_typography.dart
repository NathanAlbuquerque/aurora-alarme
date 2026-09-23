import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Aurora Alarm Design System Typography
/// Blends futuristic, geometric [Space Grotesk] with clean, dynamic [Outfit]
class AppTypography {
  // Base display font: Space Grotesk
  static TextStyle get displayFont => GoogleFonts.spaceGrotesk();

  // Base interface font: Outfit
  static TextStyle get bodyFont => GoogleFonts.outfit();

  /// Specialized Huge Clock Digits
  static TextStyle clockDisplay({Color color = Colors.white, double size = 76}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -3.0,
      height: 1.0,
      color: color,
    );
  }

  /// Specialized Seconds Indicator
  static TextStyle clockSeconds({Color? color, double size = 22}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: color ?? AppColors.neonCyan,
    );
  }

  /// Stylized Pill/Tag Badge Text
  static TextStyle badge({Color? color, double size = 11}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: color,
    );
  }

  /// Neon Bold Headline
  static TextStyle headlineBold({Color? color, double size = 28}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: color,
    );
  }

  /// Card Time Big Display
  static TextStyle cardTime({Color? color, double size = 46}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.5,
      color: color,
    );
  }

  /// Build complete Material 3 TextTheme
  static TextTheme createTextTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      // Display: Space Grotesk (futuristic, bold)
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        letterSpacing: -2.0,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: primaryColor,
      ),

      // Headlines: Space Grotesk
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primaryColor,
      ),

      // Titles: Outfit (clear, modern)
      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: secondaryColor,
      ),

      // Body: Outfit
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondaryColor,
      ),

      // Labels: Space Grotesk / Outfit
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: secondaryColor,
      ),
    );
  }
}
