import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Hypnotic, hyper-energetic ringing background with dual counter-rotating
/// plasma vortexes, rhythmic strobe flashes, expanding sonic shockwaves,
/// and radiating cosmic sparks.
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
  late AnimationController _counterVortexController;
  late AnimationController _strobeController;
  late AnimationController _shockwaveController;
  late AnimationController _sparksController;
  late List<_RadiatingSpark> _sparks;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Primary Rapid Plasma Vortex (Clockwise)
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // 2. Counter Plasma Vortex (Counter-Clockwise)
    _counterVortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // 3. Heartbeat Strobe Pulse
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    // 4. Rhythmic Sonic Shockwave Controller
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    // 5. Radiating Outward Sparks Controller
    _sparksController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _sparks = List.generate(54, (_) => _createSpark());
  }

  _RadiatingSpark _createSpark() {
    final colors = [
      AppColors.neonCyan,
      AppColors.neonPink,
      AppColors.neonYellow,
      AppColors.hyperOrange,
      AppColors.plasmaViolet,
      AppColors.neonLime,
      Colors.white,
    ];

    return _RadiatingSpark(
      angle: _random.nextDouble() * math.pi * 2,
      distanceProgress: _random.nextDouble(),
      speed: _random.nextDouble() * 0.012 + 0.006,
      size: _random.nextDouble() * 4.0 + 1.5,
      color: colors[_random.nextInt(colors.length)],
    );
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _counterVortexController.dispose();
    _strobeController.dispose();
    _shockwaveController.dispose();
    _sparksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _vortexController,
        _counterVortexController,
        _strobeController,
        _shockwaveController,
        _sparksController,
      ]),
      builder: (context, _) {
        final shockwaveProgress = _shockwaveController.value;
        final vortexAngle = _vortexController.value * 2 * math.pi;
        final counterVortexAngle =
            -_counterVortexController.value * 2 * math.pi;
        final strobe = _strobeController.value;

        // Dynamic rumble vibration offset
        final rumbleOffset = widget.enableRumble
            ? Offset(
                math.sin(shockwaveProgress * math.pi * 6) * (1.8 + (strobe * 1.2)),
                math.cos(shockwaveProgress * math.pi * 6) * (1.8 + (strobe * 1.2)),
              )
            : Offset.zero;

        return Transform.translate(
          offset: rumbleOffset,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Deep Void Base
              Container(color: AppColors.darkVoid),

              // 2. Primary Rotating Plasma Vortex
              Transform.rotate(
                angle: vortexAngle,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        AppColors.neonCyan.withAlpha(70),
                        AppColors.plasmaViolet.withAlpha(85),
                        AppColors.neonPink.withAlpha(80),
                        AppColors.hyperOrange.withAlpha(65),
                        AppColors.neonYellow.withAlpha(55),
                        AppColors.neonCyan.withAlpha(70),
                      ],
                      stops: const [0.0, 0.22, 0.48, 0.70, 0.88, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Counter-rotating Chromatic Nebula Sweep
              Transform.rotate(
                angle: counterVortexAngle,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        AppColors.neonPink.withAlpha(50),
                        Colors.transparent,
                        AppColors.neonCyan.withAlpha(55),
                        Colors.transparent,
                        AppColors.plasmaViolet.withAlpha(60),
                        AppColors.neonPink.withAlpha(50),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Strobe Light Pulse (Heartbeat of the alarm)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, -0.2),
                      radius: 1.1,
                      colors: [
                        AppColors.neonPink.withAlpha((strobe * 60).round()),
                        AppColors.neonCyan.withAlpha((strobe * 35).round()),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // 5. Central Dark Radial Overlay (keeps clock & UI perfectly legible)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.darkVoid.withAlpha(140),
                      AppColors.darkVoid.withAlpha(210),
                      AppColors.darkVoid.withAlpha(245),
                    ],
                    stops: const [0.15, 0.60, 1.0],
                  ),
                ),
              ),

              // 6. Expanding Sonic Shockwaves
              CustomPaint(
                painter: _SonicShockwavePainter(
                  progress: shockwaveProgress,
                  strobe: strobe,
                ),
              ),

              // 7. Outward Bursting Star Sparks
              CustomPaint(
                painter: _RadiatingSparksPainter(
                  sparks: _sparks,
                ),
              ),

              // 8. Foreground UI Content
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
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    for (var spark in sparks) {
      spark.distanceProgress += spark.speed;
      if (spark.distanceProgress > 1.0) {
        spark.distanceProgress = 0.04;
      }

      final dist = spark.distanceProgress * maxRadius;
      final x = center.dx + math.cos(spark.angle) * dist;
      final y = center.dy + math.sin(spark.angle) * dist;

      final opacity = (1.0 - spark.distanceProgress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = spark.color.withAlpha((opacity * 250).round())
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spark.size * 0.6);

      canvas.drawCircle(Offset(x, y), spark.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadiatingSparksPainter oldDelegate) => true;
}

class _SonicShockwavePainter extends CustomPainter {
  final double progress;
  final double strobe;

  _SonicShockwavePainter({required this.progress, required this.strobe});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);
    final maxRadius = size.width * 1.1;

    // 4 Staggered Concentric Shockwaves
    for (int i = 0; i < 4; i++) {
      final waveProgress = (progress + (i * 0.25)) % 1.0;
      final radius = waveProgress * maxRadius;
      final opacity = (1.0 - waveProgress).clamp(0.0, 1.0);

      final colors = [
        AppColors.neonCyan,
        AppColors.neonPink,
        AppColors.neonYellow,
        AppColors.plasmaViolet,
      ];
      final color = colors[i % colors.length];

      final paint = Paint()
        ..color = color.withAlpha((opacity * (130 + strobe * 50)).round())
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.2 * (1.0 - waveProgress * 0.65)).clamp(1.0, 4.0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SonicShockwavePainter oldDelegate) => true;
}
