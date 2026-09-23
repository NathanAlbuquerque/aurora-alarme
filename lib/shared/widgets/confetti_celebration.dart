import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Single Confetti Particle with physics
class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  double size;
  Color color;
  double opacity = 1.0;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

/// Dynamic Confetti & Particle Explosion Controller and Widget
class ConfettiCelebration extends StatefulWidget {
  final Widget child;

  const ConfettiCelebration({
    super.key,
    required this.child,
  });

  static ConfettiCelebrationState? of(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiCelebrationState>();
  }

  @override
  State<ConfettiCelebration> createState() => ConfettiCelebrationState();
}

class ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..addListener(_updateParticles)
     ..addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         setState(() {
           _isPlaying = false;
           _particles.clear();
         });
       }
     });
  }

  void blast({Offset? origin}) {
    final colors = [
      AppColors.neonCyan,
      AppColors.neonPink,
      AppColors.neonYellow,
      AppColors.neonPurple,
      AppColors.neonOrange,
      AppColors.neonLime,
      Colors.white,
    ];

    _particles.clear();
    final startX = origin?.dx ?? 0.5;
    final startY = origin?.dy ?? 0.5;

    for (int i = 0; i < 75; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = _random.nextDouble() * 12 + 6;
      _particles.add(
        _ConfettiParticle(
          x: startX,
          y: startY,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 6, // Initial upward burst
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.3,
          size: _random.nextDouble() * 10 + 6,
          color: colors[_random.nextInt(colors.length)],
        ),
      );
    }

    setState(() {
      _isPlaying = true;
    });
    _controller.forward(from: 0.0);
  }

  void _updateParticles() {
    if (!_isPlaying) return;
    for (var p in _particles) {
      p.x += p.vx * 0.04;
      p.y += p.vy * 0.04;
      p.vy += 0.45; // Gravity
      p.vx *= 0.98; // Air resistance
      p.rotation += p.rotationSpeed;
      p.opacity = (1.0 - _controller.value).clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isPlaying)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withAlpha((p.opacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.save();
      // Particles coordinate is normalized or relative to screen size
      final px = p.x * size.width;
      final py = p.y * size.height;
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      // Draw confetti rectangle with rounded corners
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * 0.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
