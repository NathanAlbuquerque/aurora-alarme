import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/haptic_utils.dart';

/// Highly kinetic, aesthetic Rive-style Vector Animation for Empty Alarms State.
/// Renders a slumbering cosmic moon surrounded by multi-axis orbital rings,
/// floating twinkling constellation stardust, and touch-reactive gravitational ripples.
class RiveEmptyCosmosAnimation extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const RiveEmptyCosmosAnimation({
    super.key,
    this.size = 180,
    this.onTap,
  });

  @override
  State<RiveEmptyCosmosAnimation> createState() =>
      _RiveEmptyCosmosAnimationState();
}

class _RiveEmptyCosmosAnimationState extends State<RiveEmptyCosmosAnimation>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _breathingController;
  late AnimationController _starTwinkleController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();

    // 1. Orbital celestial rotation (smooth continuous revolution)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 2. Slumbering moon organic breathing rhythm (inhalation & exhalation)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // 3. Starlight twinkling shimmer (varied phase frequencies)
    _starTwinkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 4. Interactive touch ripple wave
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _breathingController.dispose();
    _starTwinkleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    AppHaptics.lightTap();
    _rippleController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _orbitController,
            _breathingController,
            _starTwinkleController,
            _rippleController,
          ]),
          builder: (context, _) {
            final orbitVal = _orbitController.value * 2 * math.pi;
            final breathVal = _breathingController.value;
            final twinkleVal = _starTwinkleController.value;
            final rippleVal = _rippleController.value;

            return RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Layer 1: Touch Reactive Gravitational Ripple Wave
                  if (_rippleController.isAnimating)
                    CustomPaint(
                      size: Size(widget.size * 1.3, widget.size * 1.3),
                      painter: _CosmicRipplePainter(progress: rippleVal),
                    ),

                  // Layer 2: Deep Ambient Nebula Glow Halo
                  Container(
                    width: widget.size * 0.75,
                    height: widget.size * 0.75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.neonCyan.withAlpha((70 + breathVal * 40).round()),
                          AppColors.plasmaViolet.withAlpha((50 + breathVal * 30).round()),
                          AppColors.neonPink.withAlpha(20),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Layer 3: Outer Planetary Gyroscope Ring (Clockwise)
                  Transform.rotate(
                    angle: orbitVal,
                    child: CustomPaint(
                      size: Size(widget.size * 0.95, widget.size * 0.95),
                      painter: _CosmicOrbitRingPainter(
                        colorA: AppColors.neonCyan,
                        colorB: AppColors.plasmaViolet,
                        tiltAngle: 0.35,
                        hasPlanets: true,
                        pulse: breathVal,
                      ),
                    ),
                  ),

                  // Layer 4: Inner Counter-Rotating Gyroscope Ring (Counter-Clockwise)
                  Transform.rotate(
                    angle: -orbitVal * 0.75,
                    child: CustomPaint(
                      size: Size(widget.size * 0.78, widget.size * 0.78),
                      painter: _CosmicOrbitRingPainter(
                        colorA: AppColors.neonPink,
                        colorB: AppColors.neonYellow,
                        tiltAngle: -0.4,
                        hasPlanets: false,
                        pulse: breathVal,
                      ),
                    ),
                  ),

                  // Layer 5: Twinkling Constellation Stardust
                  CustomPaint(
                    size: Size(widget.size * 0.9, widget.size * 0.9),
                    painter: _CosmicStardustPainter(
                      twinkle: twinkleVal,
                      orbit: orbitVal,
                    ),
                  ),

                  // Layer 6: Central Slumbering Crescent Moon & Sun Core
                  Transform.scale(
                    scale: 0.92 + (breathVal * 0.12),
                    child: Container(
                      width: widget.size * 0.46,
                      height: widget.size * 0.46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2E0854),
                            Color(0xFF14052B),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.neonCyan.withAlpha((140 + breathVal * 80).round()),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonCyan.withAlpha((90 + breathVal * 60).round()),
                            blurRadius: 18 + (breathVal * 12),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppColors.neonPink.withAlpha(70),
                            blurRadius: 24,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppColors.neonCyan,
                              AppColors.neonYellow.withAlpha(220),
                            ],
                          ).createShader(bounds),
                          child: Icon(
                            Icons.nights_stay_rounded,
                            size: widget.size * 0.24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Layer 7: Golden Solar Sparkle Node orbiting the moon
                  Transform.rotate(
                    angle: orbitVal * 1.3,
                    child: Transform.translate(
                      offset: Offset(widget.size * 0.32, 0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonYellow,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonYellow.withAlpha(220),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for glowing multi-axis celestial orbital rings with satellites
class _CosmicOrbitRingPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;
  final double tiltAngle;
  final bool hasPlanets;
  final double pulse;

  _CosmicOrbitRingPainter({
    required this.colorA,
    required this.colorB,
    required this.tiltAngle,
    required this.hasPlanets,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);
    canvas.scale(1.0, 0.72); // Elliptical 3D perspective

    // Sweeping gradient stroke for the orbit ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..shader = SweepGradient(
        colors: [
          colorA.withAlpha(220),
          colorB.withAlpha(60),
          colorA.withAlpha(20),
          colorB.withAlpha(220),
          colorA.withAlpha(220),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

    canvas.drawCircle(Offset.zero, radius, ringPaint);

    if (hasPlanets) {
      // Draw 2 glowing satellite nodes along the orbit
      final planetPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = colorA.withAlpha(180);

      for (int i = 0; i < 2; i++) {
        final angle = (i * math.pi) + (pulse * 0.2);
        final pos = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        canvas.drawCircle(pos, 5.0, glowPaint);
        canvas.drawCircle(pos, 2.5, planetPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CosmicOrbitRingPainter oldDelegate) => true;
}

/// Custom painter for shimmering constellation stardust particles
class _CosmicStardustPainter extends CustomPainter {
  final double twinkle;
  final double orbit;

  _CosmicStardustPainter({
    required this.twinkle,
    required this.orbit,
  });

  static final List<Offset> _fixedStarPositions = [
    const Offset(-0.35, -0.38),
    const Offset(0.38, -0.32),
    const Offset(-0.42, 0.22),
    const Offset(0.36, 0.35),
    const Offset(0.08, -0.44),
    const Offset(-0.18, 0.42),
    const Offset(0.44, -0.05),
    const Offset(-0.40, -0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    for (int i = 0; i < _fixedStarPositions.length; i++) {
      final base = _fixedStarPositions[i];
      final phase = (i * 0.7);
      final alpha = ((math.sin(twinkle * math.pi + phase).abs() * 180) + 75).clamp(0, 255).toInt();
      final starSize = (1.5 + math.sin(twinkle * math.pi * 2 + phase).abs() * 2.0);

      final pos = Offset(
        center.dx + base.dx * maxR,
        center.dy + base.dy * maxR,
      );

      final color = i % 3 == 0
          ? AppColors.neonCyan
          : (i % 2 == 0 ? AppColors.neonYellow : AppColors.neonPink);

      final paint = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, starSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicStardustPainter oldDelegate) => true;
}

/// Custom painter for outward expanding gravitational ripple when tapped
class _CosmicRipplePainter extends CustomPainter {
  final double progress;

  _CosmicRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final currentRadius = progress * maxRadius;
    final alpha = ((1.0 - progress) * 200).clamp(0, 255).toInt();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (1.0 - progress) * 3.0 + 1.0
      ..color = AppColors.neonCyan.withAlpha(alpha);

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _CosmicRipplePainter oldDelegate) => true;
}
