import 'package:flutter/material.dart';

class AppColors {
  // Vibrant Aurora Accents
  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color neonEmerald = Color(0xFF10B981);
  static const Color electricBlue = Color(0xFF00BBF9);
  static const Color cosmicMagenta = Color(0xFFF72585);
  static const Color luminousPurple = Color(0xFF7209B7);
  static const Color vibrantAmber = Color(0xFFFEE440);
  static const Color radiantSunset = Color(0xFFFB923C);

  // Dark Theme Palette (Cosmic & Deep)
  static const Color darkBackground = Color(0xFF0B0E1B);
  static const Color darkSurface = Color(0xFF13172C);
  static const Color darkSurfaceElevated = Color(0xFF1C223E);
  static const Color darkSurfaceHighlight = Color(0xFF262E52);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF262E52);

  // Light Theme Palette (Crisp & Luminous)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Aurora Gradients
  static const LinearGradient auroraPrimaryGradient = LinearGradient(
    colors: [neonCyan, electricBlue, luminousPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraEmeraldGradient = LinearGradient(
    colors: [neonEmerald, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient auroraSunsetGradient = LinearGradient(
    colors: [cosmicMagenta, radiantSunset, vibrantAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161B33), Color(0xFF111425)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
