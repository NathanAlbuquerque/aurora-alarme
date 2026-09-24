import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom Aurora page transition builder that injects cinematic scale,
/// slide, fade, and neon chromatic edge flares into all route navigations.
class AuroraPageTransitionsBuilder extends PageTransitionsBuilder {
  const AuroraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _AuroraTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Standalone custom PageRoute with Aurora celestial transitions.
class AuroraPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AuroraPageRoute({
    required this.page,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 450),
    super.reverseTransitionDuration = const Duration(milliseconds: 350),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _AuroraTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

class _AuroraTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _AuroraTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Primary Entrance Curves
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Primary Entrance Scale (from 0.94 to 1.0)
    final scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(curvedAnimation);

    // Primary Entrance Slide (subtle upward slide)
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.05),
      end: Offset.zero,
    ).animate(curvedAnimation);

    // Primary Entrance Fade
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Secondary Exit Transition (when a new route is pushed on top)
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final secondaryScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(secondaryCurved);

    final secondaryFade = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(secondaryCurved);

    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      builder: (context, _) {
        return Transform.scale(
          scale: secondaryScale.value,
          child: Opacity(
            opacity: secondaryFade.value,
            child: SlideTransition(
              position: slideAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: Stack(
                    children: [
                      child,

                      // Subtle Chromatic Edge Aura during entrance transition
                      if (animation.value < 0.95 && animation.value > 0.05)
                        IgnorePointer(
                          child: Opacity(
                            opacity: (1.0 - animation.value).clamp(0.0, 0.35),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.neonCyan.withAlpha(90),
                                    Colors.transparent,
                                    AppColors.neonPink.withAlpha(90),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
