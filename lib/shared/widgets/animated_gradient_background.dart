import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'aurora_particles.dart';

/// Animated Aurora Gradient Background with oscillating cosmic glow orbs
/// and drifting starry particles.
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Solid Deep Base
        Container(
          color: isDark ? AppColors.darkVoid : AppColors.lightBackground,
        ),

        // Animated Oscillating Aurora Plasma Orbs
        AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final t = _animController.value * 2 * math.pi;
            final dx1 = math.sin(t) * 45;
            final dy1 = math.cos(t) * 35;

            final dx2 = math.cos(t * 0.8) * 40;
            final dy2 = math.sin(t * 0.8) * 50;

            final dx3 = math.sin(t * 1.2) * 35;
            final dy3 = math.cos(t * 1.2) * 40;

            return Stack(
              children: [
                // Orb 1: Electric Cyan & Acid Green (Top-Left to Center)
                Positioned(
                  top: -80 + dy1,
                  left: -80 + dx1,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDark
                              ? AppColors.neonCyan.withAlpha(85)
                              : const Color(0xFF2DD4BF).withAlpha(60),
                          isDark
                              ? AppColors.acidGreen.withAlpha(40)
                              : const Color(0xFFA7F3D0).withAlpha(30),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Orb 2: Cyber Pink & Neon Orange (Top-Right / Mid)
                Positioned(
                  top: 80 + dy2,
                  right: -100 + dx2,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDark
                              ? AppColors.neonPink.withAlpha(80)
                              : const Color(0xFFFF2A85).withAlpha(50),
                          isDark
                              ? AppColors.hyperOrange.withAlpha(45)
                              : const Color(0xFFFED7AA).withAlpha(35),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Orb 3: Plasma Violet & Laser Aqua (Bottom-Left)
                Positioned(
                  bottom: -100 + dy3,
                  left: -60 + dx3,
                  child: Container(
                    width: 440,
                    height: 440,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDark
                              ? AppColors.plasmaViolet.withAlpha(95)
                              : const Color(0xFF8B5CF6).withAlpha(55),
                          isDark
                              ? AppColors.electricBlue.withAlpha(40)
                              : const Color(0xFFBAE6FD).withAlpha(30),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Orb 4: Solar Yellow Glow (Bottom-Right / Accent)
                Positioned(
                  bottom: 60 - dy1 * 0.7,
                  right: -80 - dx1 * 0.7,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          isDark
                              ? AppColors.neonYellow.withAlpha(55)
                              : const Color(0xFFFEF08A).withAlpha(50),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Optional Cosmic Dust / Aurora Particles
        if (widget.showParticles)
          Positioned.fill(
            child: AuroraParticles(
              numberOfParticles: isDark ? 28 : 16,
              isDark: isDark,
            ),
          ),

        // Foreground Content
        SafeArea(child: widget.child),
      ],
    );
  }
}
