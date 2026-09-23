import 'package:flutter/material.dart';
import 'animated_gradient_background.dart';

/// Aurora Background: seamlessly delegates to [AnimatedGradientBackground]
/// providing fluid cosmic plasma orbs, multi-chromatic neon lighting, and stardust particles.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  final bool showParticles;

  const AuroraBackground({
    super.key,
    required this.child,
    this.showParticles = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedGradientBackground(
      showParticles: showParticles,
      child: child,
    );
  }
}
