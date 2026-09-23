import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Container wrapped with a dynamic breathing or rotating chromatic neon glow
class AnimatedGlowContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color? surfaceColor;
  final bool animateBorder;
  final double maxBlur;
  final double minBlur;
  final Duration duration;

  const AnimatedGlowContainer({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.padding,
    this.margin,
    this.primaryGlow = AppColors.neonCyan,
    this.secondaryGlow = AppColors.neonPink,
    this.surfaceColor,
    this.animateBorder = true,
    this.maxBlur = 32.0,
    this.minBlur = 14.0,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<AnimatedGlowContainer> createState() => _AnimatedGlowContainerState();
}

class _AnimatedGlowContainerState extends State<AnimatedGlowContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final progress = _glowController.value;
        final currentBlur =
            widget.minBlur + (widget.maxBlur - widget.minBlur) * progress;
        final glowOpacity = (0.35 + 0.35 * progress) * (isDark ? 1.0 : 0.6);

        // Calculate rotating border gradient alignment
        final angle = progress * math.pi;
        final alignStart = Alignment(math.cos(angle), math.sin(angle));
        final alignEnd = Alignment(-math.cos(angle), -math.sin(angle));

        return Container(
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              // Primary glow (e.g. Cyan)
              BoxShadow(
                color: widget.primaryGlow
                    .withAlpha((glowOpacity * 255).round()),
                blurRadius: currentBlur,
                spreadRadius: -1,
                offset: const Offset(-3, -3),
              ),
              // Secondary glow (e.g. Neon Pink)
              BoxShadow(
                color: widget.secondaryGlow
                    .withAlpha(((0.7 - 0.2 * progress) * 255 * (isDark ? 1.0 : 0.6)).round()),
                blurRadius: currentBlur * 1.1,
                spreadRadius: -2,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(1.5), // Border thickness
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: widget.animateBorder
                  ? LinearGradient(
                      colors: [
                        widget.primaryGlow,
                        widget.secondaryGlow,
                        AppColors.neonYellow,
                      ],
                      begin: alignStart,
                      end: alignEnd,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: widget.surfaceColor ??
                    (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius:
                    BorderRadius.circular(widget.borderRadius - 1.5),
              ),
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}
