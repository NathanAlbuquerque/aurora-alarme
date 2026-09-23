import 'package:flutter/material.dart';

/// Aurora Alarm Design System Colors (2025/2026 Vibrant & Hyper-Aesthetic)
class AppColors {
  // ===========================================================================
  // ⚡ NEON & CYBER PALETTE (High-voltage, vibrant energy)
  // ===========================================================================
  static const Color neonPink = Color(0xFFFF2A85);
  static const Color cyberPink = Color(0xFFFF007F);
  static const Color neonCyan = Color(0xFF00F5D4);
  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color neonPurple = Color(0xFF9D4EDD);
  static const Color plasmaViolet = Color(0xFF7928CA);
  static const Color neonYellow = Color(0xFFFEE440);
  static const Color solarYellow = Color(0xFFFFDE59);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color hyperOrange = Color(0xFFFF5400);
  static const Color neonLime = Color(0xFF39FF14);
  static const Color acidGreen = Color(0xFF00F59B);
  static const Color electricBlue = Color(0xFF00BBF9);
  static const Color laserAqua = Color(0xFF38BDF8);

  // ===========================================================================
  // 🌸 CONTRASTING PASTEL PALETTE (Soft, luminous harmony)
  // ===========================================================================
  static const Color pastelPink = Color(0xFFFFB7D5);
  static const Color pastelLavender = Color(0xFFD8B4FE);
  static const Color pastelMint = Color(0xFFA7F3D0);
  static const Color pastelButter = Color(0xFFFEF08A);
  static const Color pastelPeach = Color(0xFFFED7AA);
  static const Color pastelSky = Color(0xFFBAE6FD);
  static const Color pastelCoral = Color(0xFFFECDD3);

  // ===========================================================================
  // 🌌 DEEP COSMIC DARK (Night Void, Glass & Surfaces)
  // ===========================================================================
  static const Color darkVoid = Color(0xFF070913);
  static const Color darkBackground = Color(0xFF0A0D1B);
  static const Color darkSurface = Color(0xFF10152B);
  static const Color darkSurfaceElevated = Color(0xFF171E3C);
  static const Color darkSurfaceHighlight = Color(0xFF222B52);
  static const Color darkGlassFill = Color(0x33121833);
  static const Color darkGlassBorder = Color(0x404E6096);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
  static const Color darkBorder = Color(0xFF1E274D);

  // ===========================================================================
  // ☀️ LUMINOUS FROST LIGHT (Crisp, iridescent brightness)
  // ===========================================================================
  static const Color lightBackground = Color(0xFFF4F7FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFEDF2FB);
  static const Color lightSurfaceHighlight = Color(0xFFE2E8F0);
  static const Color lightGlassFill = Color(0x73FFFFFF);
  static const Color lightGlassBorder = Color(0x40CBD5E1);
  static const Color lightTextPrimary = Color(0xFF0A0F29);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ===========================================================================
  // 🌈 CURATED MULTI-STOP VIBRANT GRADIENTS
  // ===========================================================================
  /// Iconic Northern Lights glow: Cyan -> Acid Green -> Electric Blue -> Plasma
  static const LinearGradient auroraBorealis = LinearGradient(
    colors: [neonCyan, acidGreen, electricBlue, plasmaViolet],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// High energy sunset: Neon Pink -> Hyper Orange -> Solar Yellow
  static const LinearGradient cyberSunset = LinearGradient(
    colors: [neonPink, hyperOrange, solarYellow],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cosmic deep dream: Plasma Violet -> Neon Pink -> Laser Aqua
  static const LinearGradient cosmicDream = LinearGradient(
    colors: [plasmaViolet, neonPink, laserAqua],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Electric pulse: Acid Green -> Electric Cyan -> Electric Blue
  static const LinearGradient electricPulse = LinearGradient(
    colors: [acidGreen, electricCyan, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Solar flare: Hyper Orange -> Solar Yellow -> Pastel Peach
  static const LinearGradient solarFlare = LinearGradient(
    colors: [hyperOrange, solarYellow, pastelPeach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Iridescent Glass Border Gradient
  static const LinearGradient iridescentBorder = LinearGradient(
    colors: [
      Color(0x9900F5D4),
      Color(0x33FF2A85),
      Color(0x997928CA),
      Color(0x33FEE440),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle dark glass card gradient
  static const LinearGradient darkCardGlass = LinearGradient(
    colors: [
      Color(0x401C2449),
      Color(0x200F1326),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle light glass card gradient
  static const LinearGradient lightCardGlass = LinearGradient(
    colors: [
      Color(0xB3FFFFFF),
      Color(0x80F8FAFC),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // ✨ GLOW & BOX-SHADOW HELPERS
  // ===========================================================================
  /// Single vibrant neon glow
  static List<BoxShadow> neonGlow(
    Color color, {
    double blur = 24,
    double spread = 0,
    double opacity = 0.5,
    Offset offset = Offset.zero,
  }) {
    return [
      BoxShadow(
        color: color.withAlpha((opacity * 255).round()),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  /// Multi-layered chromatic aurora glow (e.g. Cyan + Pink aura)
  static List<BoxShadow> multiGlow({
    Color primary = neonCyan,
    Color secondary = neonPink,
    double blur = 28,
  }) {
    return [
      BoxShadow(
        color: primary.withAlpha(90),
        blurRadius: blur,
        spreadRadius: -2,
        offset: const Offset(-4, -4),
      ),
      BoxShadow(
        color: secondary.withAlpha(70),
        blurRadius: blur + 8,
        spreadRadius: -2,
        offset: const Offset(4, 4),
      ),
    ];
  }
}
