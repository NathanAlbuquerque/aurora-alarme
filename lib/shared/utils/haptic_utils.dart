import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralized tactile haptic feedback system
class AppHaptics {
  /// Very light tick (chips, day pills, toggles)
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Medium solid tap (buttons, navigation)
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact (save, delete, alarm fire)
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Subtle click for scroll pickers and wheel selectors
  static void selectionTick() {
    HapticFeedback.selectionClick();
  }

  /// Double tap pattern for successful actions
  static Future<void> successPattern() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.heavyImpact();
  }

  /// Vibration for warnings or errors
  static void warningBuzz() {
    HapticFeedback.vibrate();
  }
}

/// Reusable micro-interaction wrapper that applies dynamic scale bounce
/// and haptic feedback when pressed.
class ScaleBounceFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final Duration duration;

  const ScaleBounceFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.94,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<ScaleBounceFeedback> createState() => _ScaleBounceFeedbackState();
}

class _ScaleBounceFeedbackState extends State<ScaleBounceFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      AppHaptics.lightTap();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap != null
          ? () {
              widget.onTap!();
            }
          : null,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
