import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/neon_button.dart';

/// Full-screen animated simulation dialog of the alarm ringing experience
class AlarmPreviewDialog extends StatefulWidget {
  final String time;
  final String label;
  final String sound;
  final String mission;

  const AlarmPreviewDialog({
    super.key,
    required this.time,
    required this.label,
    required this.sound,
    required this.mission,
  });

  static Future<void> show(
    BuildContext context, {
    required String time,
    required String label,
    required String sound,
    required String mission,
  }) {
    HapticFeedback.heavyImpact();
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AlarmPreview',
      barrierColor: Colors.black.withAlpha(210),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return AlarmPreviewDialog(
          time: time,
          label: label,
          sound: sound,
          mission: mission,
        );
      },
    );
  }

  @override
  State<AlarmPreviewDialog> createState() => _AlarmPreviewDialogState();
}

class _AlarmPreviewDialogState extends State<AlarmPreviewDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: AppColors.neonCyan.withAlpha(160),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withAlpha(120),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.neonPink.withAlpha(90),
                blurRadius: 50,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live Beacon Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonPink.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neonPink.withAlpha(180),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonPink,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1.4, 1.4),
                            duration: 600.ms,
                          ),
                      const SizedBox(width: 8),
                      Text(
                        'DISPARO DE ALARME',
                        style: AppTypography.badge(
                          color: AppColors.neonPink,
                          size: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pulsating Sonic Rings around Time
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ripple
                    Container(
                      width: 210,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.neonCyan.withAlpha(60),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.95, 0.95),
                          end: const Offset(1.15, 1.15),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Inner Soundwave Core
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.auroraBorealis,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.neonGlow(
                          AppColors.neonCyan,
                          blur: 24,
                        ),
                      ),
                      child: Text(
                        widget.time,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 60,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          color: const Color(0xFF02261E),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Alarm Label
                Text(
                  widget.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A0F29),
                  ),
                ),

                const SizedBox(height: 8),

                // Sound & Equalizer Visualizer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: AppColors.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.sound,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini Equalizer Bars
                    ...List.generate(4, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.neonCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleY(
                            begin: 0.3,
                            end: 1.2,
                            duration: (400 + i * 150).ms,
                            curve: Curves.easeInOut,
                          );
                    }),
                  ],
                ),

                // Mission Challenge Badge (if any)
                if (widget.mission != 'none') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonYellow.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.neonYellow.withAlpha(140),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology_rounded,
                          size: 16,
                          color: AppColors.neonYellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Missão: ${_getMissionName(widget.mission)}',
                          style: AppTypography.badge(
                            color: AppColors.neonYellow,
                            size: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Action Buttons: Snooze & Dismiss
                Row(
                  children: [
                    Expanded(
                      child: NeonButton(
                        text: 'Soneca 5m',
                        icon: Icons.snooze_rounded,
                        variant: NeonButtonVariant.outlined,
                        height: 50,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeonButton(
                        text: 'Desligar',
                        icon: Icons.alarm_off_rounded,
                        variant: NeonButtonVariant.secondary,
                        height: 50,
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMissionName(String mission) {
    switch (mission) {
      case 'math':
        return 'Matemática';
      case 'shake':
        return 'Chacoalhar';
      case 'memory':
        return 'Memória';
      default:
        return 'Normal';
    }
  }
}
