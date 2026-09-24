import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive tactile Hold-to-Dismiss button with liquid energy fill,
/// escalating haptic feedback, and neon shockwave explosion on completion.
class HoldToDismissButton extends StatefulWidget {
  final VoidCallback onDismiss;
  final bool isLocked;
  final String? lockedMessage;
  final Duration holdDuration;

  const HoldToDismissButton({
    super.key,
    required this.onDismiss,
    this.isLocked = false,
    this.lockedMessage,
    this.holdDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<HoldToDismissButton> createState() => _HoldToDismissButtonState();
}

class _HoldToDismissButtonState extends State<HoldToDismissButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  int _lastHapticQuarter = 0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )
      ..addListener(_handleProgressChange)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDismiss();
        }
      });
  }

  void _handleProgressChange() {
    final progress = _progressController.value;
    final quarter = (progress * 4).floor();

    if (quarter > _lastHapticQuarter && quarter <= 4) {
      _lastHapticQuarter = quarter;
      if (quarter == 4) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    if (widget.isLocked) {
      HapticFeedback.vibrate();
      return;
    }
    _lastHapticQuarter = 0;
    HapticFeedback.lightImpact();
    _progressController.forward();
  }

  void _onHoldEnd() {
    if (_progressController.value < 1.0) {
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final progress = _progressController.value;
        final isPressing = progress > 0.05;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _onHoldStart(),
          onPointerUp: (_) => _onHoldEnd(),
          onPointerCancel: (_) => _onHoldEnd(),
          child: Transform.scale(
            scale: isPressing ? 1.02 : 1.0,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: widget.isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.neonPink
                              .withAlpha((100 + (progress * 155)).round()),
                          blurRadius: 18 + (progress * 24),
                          spreadRadius: 1 + (progress * 4),
                        ),
                        if (isPressing)
                          BoxShadow(
                            color: AppColors.hyperOrange
                                .withAlpha((progress * 200).round()),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background base
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isLocked
                            ? AppColors.darkSurfaceElevated.withAlpha(180)
                            : AppColors.darkSurfaceElevated,
                        border: Border.all(
                          color: widget.isLocked
                              ? AppColors.darkBorder
                              : AppColors.neonPink.withAlpha(180),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(34),
                      ),
                    ),

                    // Charging Progress Fill Bar
                    if (!widget.isLocked && progress > 0)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.neonPink,
                                AppColors.hyperOrange,
                                AppColors.neonYellow,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(34),
                          ),
                        ),
                      ),

                    // Particle shimmer spark on the charging head
                    if (progress > 0.02 && progress < 0.98)
                      Positioned(
                        left: (MediaQuery.of(context).size.width - 48) * progress - 16,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(220),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 14,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Centered Content
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isLocked
                                ? Icons.lock_rounded
                                : (progress > 0.5
                                    ? Icons.power_settings_new_rounded
                                    : Icons.alarm_off_rounded),
                            color: widget.isLocked
                                ? AppColors.darkTextMuted
                                : (progress > 0.4 ? Colors.black : Colors.white),
                            size: 26 + (progress * 4),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.isLocked
                                ? (widget.lockedMessage ?? 'DESAFIO PENDENTE')
                                : (progress > 0.05
                                    ? 'SEGURE... ${(progress * 100).toInt()}%'
                                    : 'SEGURE PARA DESLIGAR'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              height: 1.0,
                              color: widget.isLocked
                                  ? AppColors.darkTextMuted
                                  : (progress > 0.4
                                      ? Colors.black
                                      : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
