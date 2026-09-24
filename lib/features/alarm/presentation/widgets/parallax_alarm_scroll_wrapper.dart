import 'package:flutter/material.dart';

typedef ParallaxCardBuilder = Widget Function(
  BuildContext context,
  double parallaxOffset,
  double glowIntensity,
);

/// A viewport-reactive 3D scroll physics wrapper.
/// Automatically binds to the parent Scrollable's position and calculates the item's
/// exact distance from the viewport center, applying:
/// - 3D Perspective Tilt (rotateX + rotateZ)
/// - Proportional Scaling (scale down smoothly towards viewport edges)
/// - Edge Opacity Fading (avoids abrupt cutoffs at screen edges)
/// - Multiplane Parallax Offset for inner contents
/// - Dynamic Neon Glow Flare (intensifies when centered in focal sweet spot)
class ParallaxAlarmScrollWrapper extends StatefulWidget {
  final ParallaxCardBuilder builder;

  const ParallaxAlarmScrollWrapper({
    super.key,
    required this.builder,
  });

  @override
  State<ParallaxAlarmScrollWrapper> createState() =>
      _ParallaxAlarmScrollWrapperState();
}

class _ParallaxAlarmScrollWrapperState extends State<ParallaxAlarmScrollWrapper> {
  ScrollPosition? _scrollPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final newPosition = Scrollable.of(context).position;
      if (_scrollPosition != newPosition) {
        _scrollPosition = newPosition;
      }
    } catch (_) {
      // Outside a scrollable context fallback
      _scrollPosition = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollPosition == null) {
      return widget.builder(context, 0.0, 1.0);
    }

    return AnimatedBuilder(
      animation: _scrollPosition!,
      builder: (context, _) {
        double normalizedOffset = 0.0;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize && renderBox.attached) {
          try {
            final viewportBox =
                Scrollable.of(context).context.findRenderObject() as RenderBox?;
            if (viewportBox != null && viewportBox.hasSize) {
              final itemPos =
                  renderBox.localToGlobal(Offset.zero, ancestor: viewportBox);
              final viewportHeight = viewportBox.size.height;
              final itemCenter = itemPos.dy + (renderBox.size.height / 2);
              final viewportCenter = viewportHeight / 2;

              // Normalized value: -1.0 (top edge) to 0.0 (center) to +1.0 (bottom edge)
              normalizedOffset =
                  ((itemCenter - viewportCenter) / (viewportHeight / 2))
                      .clamp(-1.5, 1.5);
            }
          } catch (_) {
            normalizedOffset = 0.0;
          }
        }

        final absOffset = normalizedOffset.abs();

        // 1. Proportional Scale: 1.0 at center, down to 0.93 near edges
        final scale = (1.0 - (absOffset * 0.055)).clamp(0.92, 1.01);

        // 2. 3D Perspective Rotation X: tilts gently toward camera as it scrolls
        final tiltX = (normalizedOffset * -0.055).clamp(-0.10, 0.10);

        // 3. Subtle 3D Perspective Rotation Z: organic dynamic drift
        final tiltZ = (normalizedOffset * 0.010).clamp(-0.02, 0.02);

        // 4. Edge Fade: 1.0 at center, down to ~0.72 at extreme borders
        final opacity = (1.0 - (absOffset * 0.16)).clamp(0.72, 1.0);

        // 5. Parallax Vertical Offset for inner layered children (-22px to +22px)
        final parallaxOffset = normalizedOffset * -20.0;

        // 6. Glow intensity multiplier: 1.2x at center, down to 0.5x near edges
        final glowIntensity = (1.2 - (absOffset * 0.5)).clamp(0.4, 1.25);

        return Opacity(
          opacity: opacity,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective depth
              ..scaleByDouble(scale, scale, 1.0, 1.0)
              ..rotateX(tiltX)
              ..rotateZ(tiltZ),
            child: widget.builder(context, parallaxOffset, glowIntensity),
          ),
        );
      },
    );
  }
}
