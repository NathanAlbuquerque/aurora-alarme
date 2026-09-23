import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum NeonButtonVariant {
  primary, // Neon Cyan & Emerald
  secondary, // Cyber Pink & Sunset
  purple, // Plasma Violet & Laser Aqua
  outlined, // Frosted glass with glowing border
}

/// High-impact tactile neon button with radiant glow
class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final NeonButtonVariant variant;
  final IconData? icon;
  final double height;
  final double borderRadius;
  final bool isFullWidth;
  final Gradient? customGradient;

  const NeonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = NeonButtonVariant.primary,
    this.icon,
    this.height = 56.0,
    this.borderRadius = 24.0,
    this.isFullWidth = false,
    this.customGradient,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;

  Gradient _getGradient(bool isDark) {
    if (widget.customGradient != null) return widget.customGradient!;

    switch (widget.variant) {
      case NeonButtonVariant.primary:
        return AppColors.auroraBorealis;
      case NeonButtonVariant.secondary:
        return AppColors.cyberSunset;
      case NeonButtonVariant.purple:
        return AppColors.cosmicDream;
      case NeonButtonVariant.outlined:
        return LinearGradient(
          colors: isDark
              ? [
                  AppColors.neonCyan.withAlpha(40),
                  AppColors.neonPink.withAlpha(20),
                ]
              : [
                  const Color(0xFF009688).withAlpha(30),
                  const Color(0xFFE0006C).withAlpha(15),
                ],
        );
    }
  }

  Color _getGlowColor() {
    switch (widget.variant) {
      case NeonButtonVariant.primary:
        return AppColors.neonCyan;
      case NeonButtonVariant.secondary:
        return AppColors.neonPink;
      case NeonButtonVariant.purple:
        return AppColors.plasmaViolet;
      case NeonButtonVariant.outlined:
        return AppColors.neonCyan.withAlpha(100);
    }
  }

  Color _getTextColor(bool isDark) {
    if (widget.variant == NeonButtonVariant.outlined) {
      return isDark ? AppColors.neonCyan : const Color(0xFF009688);
    }
    if (widget.variant == NeonButtonVariant.primary) {
      return const Color(0xFF02261E); // Deep dark contrast for bright cyan
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _getGradient(isDark);
    final glowColor = _getGlowColor();
    final textColor = _getTextColor(isDark);
    final isOutlined = widget.variant == NeonButtonVariant.outlined;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        height: widget.height,
        width: widget.isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.onPressed != null
              ? [
                  BoxShadow(
                    color: glowColor.withAlpha(_isPressed ? 180 : 110),
                    blurRadius: _isPressed ? 16 : 24,
                    spreadRadius: _isPressed ? -2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            onHighlightChanged: (pressed) {
              setState(() => _isPressed = pressed);
            },
            onTap: widget.onPressed,
            child: Ink(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: isOutlined
                    ? Border.all(
                        color: isDark ? AppColors.neonCyan : const Color(0xFF009688),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisSize:
                      widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: textColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      widget.text,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
