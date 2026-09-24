import 'package:flutter/material.dart';
import '../navigation/aurora_page_route.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Aurora Alarm Complete Material 3 Theme (Light & Dark)
class AppTheme {
  static const double cardRadius = 28.0;
  static const double buttonRadius = 24.0;
  static const double dialogRadius = 32.0;

  // ===========================================================================
  // 🌙 DARK THEME (The Hero Aurora Night Experience)
  // ===========================================================================
  static ThemeData get darkTheme {
    final textTheme = AppTypography.createTextTheme(brightness: Brightness.dark);

    const darkColorScheme = ColorScheme.dark(
      primary: AppColors.neonCyan,
      onPrimary: Color(0xFF022922),
      primaryContainer: Color(0xFF064E43),
      onPrimaryContainer: AppColors.neonCyan,
      secondary: AppColors.neonPink,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF5B002E),
      onSecondaryContainer: AppColors.pastelPink,
      tertiary: AppColors.neonYellow,
      onTertiary: Color(0xFF262000),
      tertiaryContainer: Color(0xFF4D4000),
      onTertiaryContainer: AppColors.pastelButter,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceElevated,
      error: Color(0xFFFF3366),
      onError: Colors.white,
      outline: AppColors.darkBorder,
      outlineVariant: Color(0xFF2E3966),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: AppColors.darkVoid,
      textTheme: textTheme,

      // Custom Aurora Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AuroraPageTransitionsBuilder(),
          TargetPlatform.iOS: AuroraPageTransitionsBuilder(),
          TargetPlatform.linux: AuroraPageTransitionsBuilder(),
          TargetPlatform.macOS: AuroraPageTransitionsBuilder(),
          TargetPlatform.windows: AuroraPageTransitionsBuilder(),
        },
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.darkTextPrimary,
        ),
      ),

      // Card Theme (Big 28px rounded corners)
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
      ),

      // Switch Theme (Neon Cyan Glowing Active State)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.neonCyan;
          }
          return AppColors.darkTextMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.neonCyan.withAlpha(50);
          }
          return AppColors.darkSurfaceHighlight;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.neonCyan.withAlpha(120);
          }
          return Colors.transparent;
        }),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: const Color(0xFF03221C),
        elevation: 12,
        focusElevation: 16,
        hoverElevation: 14,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),

      // Dialog & Bottom Sheet Themes (Curved 32-36px)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        elevation: 20,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      ),

      // Time Picker Theme (Modern Neon Accented)
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
        hourMinuteColor: AppColors.darkSurfaceElevated,
        hourMinuteTextColor: AppColors.neonCyan,
        dialBackgroundColor: AppColors.darkSurfaceElevated,
        dialHandColor: AppColors.neonCyan,
        dialTextColor: AppColors.darkTextPrimary,
        entryModeIconColor: AppColors.neonCyan,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===========================================================================
  // ☀️ LIGHT THEME (Vibrant Frost Light Experience)
  // ===========================================================================
  static ThemeData get lightTheme {
    final textTheme = AppTypography.createTextTheme(brightness: Brightness.light);

    const lightColorScheme = ColorScheme.light(
      primary: Color(0xFF009688),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD0F8F1),
      onPrimaryContainer: Color(0xFF004D40),
      secondary: Color(0xFFE0006C),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFD9E8),
      onSecondaryContainer: Color(0xFF5B002E),
      tertiary: Color(0xFF7928CA),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEEDDFF),
      onTertiaryContainer: Color(0xFF2E0054),
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      outline: AppColors.lightBorder,
      outlineVariant: Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme,

      // Custom Aurora Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AuroraPageTransitionsBuilder(),
          TargetPlatform.iOS: AuroraPageTransitionsBuilder(),
          TargetPlatform.linux: AuroraPageTransitionsBuilder(),
          TargetPlatform.macOS: AuroraPageTransitionsBuilder(),
          TargetPlatform.windows: AuroraPageTransitionsBuilder(),
        },
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.lightTextPrimary,
        ),
      ),

      // Card Theme (Big 28px rounded corners)
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        ),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF009688);
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF009688).withAlpha(50);
          }
          return const Color(0xFFCBD5E1);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF009688);
          }
          return Colors.transparent;
        }),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),

      // Dialog & Bottom Sheet Themes (Curved 32-36px)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
      ),

      // Time Picker Theme
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
        ),
        hourMinuteColor: AppColors.lightSurfaceElevated,
        hourMinuteTextColor: const Color(0xFF009688),
        dialBackgroundColor: AppColors.lightSurfaceElevated,
        dialHandColor: const Color(0xFF009688),
        dialTextColor: AppColors.lightTextPrimary,
        entryModeIconColor: const Color(0xFF009688),
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightSurfaceElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
