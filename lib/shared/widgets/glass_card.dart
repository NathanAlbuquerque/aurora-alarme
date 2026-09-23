import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Modern Frosted Glass Card with Iridescent / Neon Gradient Border
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? fillColor;
  final Gradient? borderGradient;
  final double borderWidth;
  final List<BoxShadow>? glowShadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.blur = 18.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.fillColor,
    this.borderGradient,
    this.borderWidth = 1.5,
    this.glowShadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultFill = isDark
        ? AppColors.darkSurface.withAlpha(160)
        : AppColors.lightSurface.withAlpha(200);

    final defaultBorderGradient = borderGradient ??
        LinearGradient(
          colors: isDark
              ? [
                  AppColors.neonCyan.withAlpha(160),
                  AppColors.neonPink.withAlpha(90),
                  AppColors.plasmaViolet.withAlpha(140),
                ]
              : [
                  const Color(0xFF009688).withAlpha(120),
                  const Color(0xFFE0006C).withAlpha(80),
                  const Color(0xFF7928CA).withAlpha(90),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: glowShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: fillColor ?? defaultFill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
            ),
            child: CustomPaint(
              painter: _GradientBorderPainter(
                gradient: defaultBorderGradient,
                borderWidth: borderWidth,
                borderRadius: borderRadius,
              ),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: (isDark ? AppColors.neonCyan : const Color(0xFF009688))
              .withAlpha(30),
          highlightColor: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double borderWidth;
  final double borderRadius;

  _GradientBorderPainter({
    required this.gradient,
    required this.borderWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final rect = Rect.fromLTWH(
      borderWidth / 2,
      borderWidth / 2,
      size.width - borderWidth,
      size.height - borderWidth,
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius - borderWidth / 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.gradient != gradient ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderRadius != borderRadius;
  }
}
