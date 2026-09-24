import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hypnotic, hyper-energetic ringing background with rotating plasma vortex,
/// expanding sonic shockwaves, and radiating cosmic sparks.
class HypnoticRingingBackground extends StatefulWidget {
  final Widget child;
  final bool enableRumble;

  const HypnoticRingingBackground({
    super.key,
    required this.child,
    this.enableRumble = true,
  });

  @override
  State<HypnoticRingingBackground> createState() =>
      _HypnoticRingingBackgroundState();
}

class _HypnoticRingingBackgroundState extends State<HypnoticRingingBackground>
    with TickerProviderStateMixin {
  late AnimationController _vortexController;
  late AnimationController _shockwaveController;
  late AnimationController _sparksController;
  late List<_RadiatingSpark> _sparks;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Rotating Plasma Vortex Controller
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 2. Rhythmic Sonic Shockwave Controller
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 3. Radiating Outward Sparks Controller
    _sparksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _sparks = List.generate(36, (_) => _createSpark());
  }

  _RadiatingSpark _createSpark() {
    final colors = [
      AppColors.neonCyan,
      AppColors.neonPink,
      AppColors.neonYellow,
      AppColors.neonOrange,
      AppColors.plasmaViolet,
      AppColors.neonLime,
    ];

    return _RadiatingSpark(
      angle: _random.nextDouble() * math.pi * 2,
      distanceProgress: _random.nextDouble(),
      speed: _random.nextDouble() * 0.007 + 0.004,
      size: _random.nextDouble() * 3.5 + 1.5,
      color: colors[_random.nextInt(colors.length)],
    );
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _shockwaveController.dispose();
    _sparksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_vortexController, _shockwaveController, _sparksController]),
      builder: (context, _) {
        final shockwaveProgress = _shockwaveController.value;
        final vortexAngle = _vortexController.value * 2 * math.pi;

        // Subtle camera rumble on rhythmic beats
        final rumbleOffset = widget.enableRumble
            ? Offset(
                math.sin(shockwaveProgress * math.pi * 4) * 1.5,
                math.cos(shockwaveProgress * math.pi * 4) * 1.5,
              )
            : Offset.zero;

        return Transform.translate(
          offset: rumbleOffset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Deep Void Base
              Container(color: AppColors.darkVoid),

              // 2. Rotating Hypnotic Plasma Vortex
              Transform.rotate(
                angle: vortexAngle,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        AppColors.neonCyan.withAlpha(55),
                        AppColors.plasmaViolet.withAlpha(70),
                        AppColors.neonPink.withAlpha(65),
                        AppColors.hyperOrange.withAlpha(50),
                        AppColors.neonYellow.withAlpha(45),
                        AppColors.neonCyan.withAlpha(55),
                      ],
                      stops: const [0.0, 0.25, 0.5, 0.72, 0.88, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Central Dark Radial Overlay (Softening center for clock readability)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.darkVoid.withAlpha(160),
                      AppColors.darkVoid.withAlpha(220),
                      AppColors.darkVoid.withAlpha(250),
                    ],
                    stops: const [0.2, 0.65, 1.0],
                  ),
                ),
              ),

              // 4. Expanding Sonic Shockwaves
              CustomPaint(
                painter: _SonicShockwavePainter(
                  progress: shockwaveProgress,
                ),
              ),

              // 5. Outward Bursting Star Sparks
              CustomPaint(
                painter: _RadiatingSparksPainter(
                  sparks: _sparks,
                ),
              ),

              // 6. Foreground UI Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _RadiatingSpark {
  double angle;
  double distanceProgress;
  double speed;
  double size;
  Color color;

  _RadiatingSpark({
    required this.angle,
    required this.distanceProgress,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _RadiatingSparksPainter extends CustomPainter {
  final List<_RadiatingSpark> sparks;

  _RadiatingSparksPainter({required this.sparks});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;

    for (var spark in sparks) {
      spark.distanceProgress += spark.speed;
      if (spark.distanceProgress > 1.0) {
        spark.distanceProgress = 0.05;
      }

      final dist = spark.distanceProgress * maxRadius;
      final x = center.dx + math.cos(spark.angle) * dist;
      final y = center.dy + math.sin(spark.angle) * dist;

      final opacity = (1.0 - spark.distanceProgress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = spark.color.withAlpha((opacity * 230).round())
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spark.size * 0.7);

      canvas.drawCircle(Offset(x, y), spark.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiatingSparksPainter oldDelegate) => true;
}

class _SonicShockwavePainter extends CustomPainter {
  final double progress;

  _SonicShockwavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.36);
    final maxRadius = size.width * 0.95;

    // 3 Staggered Concentric Shockwaves
    for (int i = 0; i < 3; i++) {
      final waveProgress = (progress + (i * 0.33)) % 1.0;
      final radius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0);

      final color = i == 0
          ? AppColors.neonCyan
          : (i == 1 ? AppColors.neonPink : AppColors.neonYellow);

      final paint = Paint()
        ..color = color.withAlpha((opacity * 140).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1.0 - waveProgress * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonicShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
