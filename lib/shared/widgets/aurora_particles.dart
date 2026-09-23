import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Floating Aurora Star/Particle
class _Particle {
  double x;
  double y;
  double radius;
  double speed;
  double angle;
  double opacity;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.angle,
    required this.opacity,
    required this.color,
  });
}

/// Dynamic cosmic particles and floating sparks painter
class AuroraParticles extends StatefulWidget {
  final int numberOfParticles;
  final bool isDark;

  const AuroraParticles({
    super.key,
    this.numberOfParticles = 24,
    this.isDark = true,
  });

  @override
  State<AuroraParticles> createState() => _AuroraParticlesState();
}

class _AuroraParticlesState extends State<AuroraParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _particles = List.generate(widget.numberOfParticles, (_) => _generateParticle());
  }

  _Particle _generateParticle() {
    final colors = widget.isDark
        ? [
            AppColors.neonCyan,
            AppColors.neonPink,
            AppColors.neonYellow,
            AppColors.neonPurple,
            AppColors.acidGreen,
          ]
        : [
            const Color(0xFF00B4D8),
            const Color(0xFFFF4D94),
            const Color(0xFF7928CA),
            const Color(0xFFFBBF24),
          ];

    return _Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      radius: _random.nextDouble() * 2.5 + 1.0,
      speed: _random.nextDouble() * 0.0008 + 0.0003,
      angle: _random.nextDouble() * math.pi * 2,
      opacity: _random.nextDouble() * 0.6 + 0.2,
      color: colors[_random.nextInt(colors.length)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _AuroraParticlePainter(
            particles: _particles,
            isDark: widget.isDark,
          ),
        );
      },
    );
  }
}

class _AuroraParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isDark;

  _AuroraParticlePainter({
    required this.particles,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      // Update position
      p.x += math.cos(p.angle) * p.speed;
      p.y += math.sin(p.angle) * p.speed;

      // Wrap around edges
      if (p.x < 0) p.x = 1.0;
      if (p.x > 1.0) p.x = 0;
      if (p.y < 0) p.y = 1.0;
      if (p.y > 1.0) p.y = 0;

      final paint = Paint()
        ..color = p.color.withAlpha((p.opacity * (isDark ? 220 : 160)).round())
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 0.8);

      final center = Offset(p.x * size.width, p.y * size.height);
      canvas.drawCircle(center, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraParticlePainter oldDelegate) => true;
}
