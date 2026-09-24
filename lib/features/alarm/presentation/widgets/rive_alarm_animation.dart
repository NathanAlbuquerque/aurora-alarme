import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Highly kinetic, aesthetic Rive-style Vector Alarm Animation widget.
/// Renders a cybernetic holographic alarm artboard with oscillating ringing bell,
/// 3D orbital gyroscope rings, and reactive neon shockwaves.
class RiveAlarmAnimation extends StatefulWidget {
  final double size;
  final bool isRinging;
  final Color primaryGlow;

  const RiveAlarmAnimation({
    super.key,
    this.size = 200,
    this.isRinging = true,
    this.primaryGlow = AppColors.neonCyan,
  });

  @override
  State<RiveAlarmAnimation> createState() => _RiveAlarmAnimationState();
}

class _RiveAlarmAnimationState extends State<RiveAlarmAnimation>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _bellWobbleController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // 1. Orbital gyroscope rotation (continuous smooth spin)
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // 2. Heartbeat core pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    // 3. Fast ringing bell oscillation (sways left-right like an alarm bell)
    _bellWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    if (widget.isRinging) {
      _bellWobbleController.repeat(reverse: true);
    }

    // 4. Expanding sonic ripple shockwaves
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant RiveAlarmAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRinging != oldWidget.isRinging) {
      if (widget.isRinging) {
        _bellWobbleController.repeat(reverse: true);
      } else {
        _bellWobbleController.animateTo(0.5);
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _bellWobbleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildKineticArtboard();
  }

  Widget _buildKineticArtboard() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationController,
          _pulseController,
          _bellWobbleController,
          _waveController,
        ]),
        builder: (context, _) {
          final pulseVal = _pulseController.value;
          final wobbleAngle =
              (math.sin(_bellWobbleController.value * math.pi * 2) * 0.22);
          final rotAngle = _rotationController.value * 2 * math.pi;
          final waveProgress = _waveController.value;

          return RepaintBoundary(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Layer 1: Concentric Sonic Waves Painter
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RiveShockwavePainter(
                    progress: waveProgress,
                    isRinging: widget.isRinging,
                    color: widget.primaryGlow,
                  ),
                ),

                // Layer 2: 3D Holographic Gyroscope Orbit Rings
                Transform.rotate(
                  angle: rotAngle,
                  child: CustomPaint(
                    size: Size(widget.size * 0.88, widget.size * 0.88),
                    painter: _RiveOrbitRingsPainter(
                      pulse: pulseVal,
                    ),
                  ),
                ),

                // Layer 3: Counter-rotating Particle Dust Ring
                Transform.rotate(
                  angle: -rotAngle * 0.7,
                  child: CustomPaint(
                    size: Size(widget.size * 0.76, widget.size * 0.76),
                    painter: _RiveStarDustPainter(
                      pulse: pulseVal,
                    ),
                  ),
                ),

                // Layer 4: Central Pulsing Reactor Core
                Transform.scale(
                  scale: 0.92 + (pulseVal * 0.16),
                  child: Container(
                    width: widget.size * 0.52,
                    height: widget.size * 0.52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.primaryGlow.withAlpha(200),
                          AppColors.plasmaViolet.withAlpha(160),
                          AppColors.neonPink.withAlpha(100),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 0.75, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryGlow.withAlpha(140),
                          blurRadius: 28 + (pulseVal * 16),
                          spreadRadius: 2 + (pulseVal * 6),
                        ),
                      ],
                    ),
                  ),
                ),

                // Layer 5: Dynamic Tilting Alarm Bell Hero Vector Icon
                Transform.rotate(
                  angle: widget.isRinging ? wobbleAngle : 0.0,
                  alignment: const Alignment(0.0, -0.6),
                  child: Transform.scale(
                    scale: 1.0 + (pulseVal * 0.08),
                    child: Container(
                      width: widget.size * 0.44,
                      height: widget.size * 0.44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkSurface.withAlpha(210),
                        border: Border.all(
                          color: Colors.white.withAlpha(200),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonYellow.withAlpha(180),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppColors.neonYellow,
                              AppColors.hyperOrange,
                            ],
                          ).createShader(bounds),
                          child: Icon(
                            Icons.alarm_on_rounded,
                            size: widget.size * 0.26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for sonic ripple waves expanding outwards from the alarm core
class _RiveShockwavePainter extends CustomPainter {
  final double progress;
  final bool isRinging;
  final Color color;

  _RiveShockwavePainter({
    required this.progress,
    required this.isRinging,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRinging) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final currentRadius = waveProgress * maxRadius;
      final alpha = ((1.0 - waveProgress) * 180).clamp(0, 255).toInt();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - waveProgress) * 3.5 + 1.0
        ..color = (i % 2 == 0 ? color : AppColors.neonPink).withAlpha(alpha);

      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveShockwavePainter oldDelegate) => true;
}

/// Custom painter for rotating holographic orbital rings
class _RiveOrbitRingsPainter extends CustomPainter {
  final double pulse;

  _RiveOrbitRingsPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer segmented dashed ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: [
          AppColors.neonCyan.withAlpha(220),
          AppColors.plasmaViolet.withAlpha(200),
          AppColors.neonPink.withAlpha(220),
          AppColors.neonCyan.withAlpha(220),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, ringPaint);

    // Orbiting Satellite Nodes
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.neonCyan.withAlpha(160);

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2);
      final nodePos = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      canvas.drawCircle(nodePos, 6.0, glowPaint);
      canvas.drawCircle(nodePos, 3.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveOrbitRingsPainter oldDelegate) => true;
}

/// Custom painter for glowing cosmic particles circling the core
class _RiveStarDustPainter extends CustomPainter {
  final double pulse;

  _RiveStarDustPainter({required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final colors = [
      AppColors.neonYellow,
      AppColors.hyperOrange,
      AppColors.neonCyan,
      AppColors.neonPink,
    ];

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3);
      final r = radius * (0.85 + (math.sin(pulse * math.pi + i) * 0.15));
      final pos = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );

      final paint = Paint()
        ..color = colors[i % colors.length].withAlpha(200)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, 2.5 + (pulse * 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiveStarDustPainter oldDelegate) => true;
}
