import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

/// Highly striking Floating Action Button with breathing pulse aura,
/// dynamic particle sparks, and iridescent neon gradients.
class PulsingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  const PulsingFab({
    super.key,
    required this.onPressed,
    this.label = 'NOVO ALARME',
    this.icon = Icons.add_alarm_rounded,
  });

  @override
  State<PulsingFab> createState() => _PulsingFabState();
}

class _PulsingFabState extends State<PulsingFab>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particlesController;
  late Animation<double> _pulseScale;
  late Animation<double> _glowBlur;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _particlesController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowBlur = Tween<double>(begin: 20.0, end: 38.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particlesController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _particlesController]),
      builder: (context, child) {
        final scale = _isPressed ? 0.94 : _pulseScale.value;
        final currentBlur = _glowBlur.value;

        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Orbiting Spark Particles around the button
              ...List.generate(6, (index) {
                final angle =
                    _particlesController.value * 2 * math.pi + (index * (math.pi / 3));
                final dist = 36.0 + math.sin(_pulseController.value * math.pi + index) * 6;
                final sparkX = math.cos(angle) * (85 + dist);
                final sparkY = math.sin(angle) * (20 + dist * 0.4);
                final sparkColor = index % 2 == 0
                    ? AppColors.neonCyan
                    : (index % 3 == 0 ? AppColors.neonYellow : AppColors.neonPink);

                return Positioned(
                  left: sparkX + 90,
                  top: sparkY + 22,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sparkColor,
                      boxShadow: [
                        BoxShadow(
                          color: sparkColor,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Button Body with Multi-Layered Neon Glow Aura
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withAlpha(isDark ? 160 : 120),
                      blurRadius: currentBlur,
                      spreadRadius: -2,
                      offset: const Offset(-2, -2),
                    ),
                    BoxShadow(
                      color: AppColors.neonPink.withAlpha(isDark ? 140 : 100),
                      blurRadius: currentBlur + 6,
                      spreadRadius: -3,
                      offset: const Offset(3, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onHighlightChanged: (pressed) {
                      setState(() => _isPressed = pressed);
                    },
                    onTap: _handleTap,
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.auroraBorealis,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withAlpha(160),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: const Color(0xFF03221C),
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: const Color(0xFF03221C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
