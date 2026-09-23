import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

/// Exaggerated, high-energy neon switch with spring physics, glowing aura,
/// and squash-and-stretch thumb micro-interactions.
class ExaggeratedNeonSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final Color activeTrackColor;
  final double width;
  final double height;

  const ExaggeratedNeonSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.neonCyan,
    this.activeTrackColor = AppColors.plasmaViolet,
    this.width = 68.0,
    this.height = 36.0,
  });

  @override
  State<ExaggeratedNeonSwitch> createState() => _ExaggeratedNeonSwitchState();
}

class _ExaggeratedNeonSwitchState extends State<ExaggeratedNeonSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _squashAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: widget.value ? 1.0 : 0.0,
    );

    _slideAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeOutBack,
    );

    // Squash & Stretch: peaks halfway through transition
    _squashAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant ExaggeratedNeonSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thumbSize = widget.height - 8;
    final maxSlide = widget.width - thumbSize - 8;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = _slideAnimation.value;
          final squash = _squashAnimation.value;
          final thumbX = progress * maxSlide;

          // Interpolated track gradient
          final trackGradient = LinearGradient(
            colors: [
              Color.lerp(
                isDark ? AppColors.darkSurfaceHighlight : const Color(0xFFE2E8F0),
                widget.activeTrackColor.withAlpha(isDark ? 160 : 120),
                progress,
              )!,
              Color.lerp(
                isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                widget.activeColor.withAlpha(isDark ? 220 : 180),
                progress,
              )!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

          // Dynamic glow shadow based on switch state
          final glowShadows = progress > 0.1
              ? [
                  BoxShadow(
                    color: widget.activeColor.withAlpha((progress * (isDark ? 140 : 90)).round()),
                    blurRadius: 16 * progress,
                    spreadRadius: 2 * progress,
                  ),
                  BoxShadow(
                    color: AppColors.neonPink.withAlpha((progress * (isDark ? 90 : 50)).round()),
                    blurRadius: 20 * progress,
                    spreadRadius: -2,
                    offset: const Offset(2, 2),
                  ),
                ]
              : <BoxShadow>[];

          return Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: trackGradient,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: Color.lerp(
                  isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                  widget.activeColor,
                  progress,
                )!,
                width: 1.5,
              ),
              boxShadow: glowShadows,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Thumb
                Positioned(
                  left: thumbX,
                  top: 0,
                  bottom: 0,
                  child: Transform.scale(
                    scaleX: squash,
                    scaleY: 1.0 / (squash * 0.85),
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.lerp(
                          isDark ? AppColors.darkTextMuted : Colors.white,
                          widget.activeColor,
                          progress,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withAlpha(
                              (progress * (isDark ? 220 : 160)).round(),
                            ),
                            blurRadius: 10 * progress + 2,
                            spreadRadius: 1 * progress,
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: progress,
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: const Color(0xFF03221C),
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
