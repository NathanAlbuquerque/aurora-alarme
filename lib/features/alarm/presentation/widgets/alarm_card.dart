import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/haptic_utils.dart';
import '../../../../shared/widgets/exaggerated_neon_switch.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final ValueChanged<int>? onToggleDay;
  final VoidCallback? onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    this.index = 0,
    required this.onToggle,
    required this.onDelete,
    this.onToggleDay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateTimeUtils.formatTimeOfDay(alarm.timeOfDay);

    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0x00FF2A85), Color(0xFFFF2A85)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.delete_sweep_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      onDismissed: (_) {
        AppHaptics.heavyImpact();
        onDelete();
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        borderRadius: 28,
        blur: 18,
        borderWidth: alarm.isEnabled ? 2.0 : 1.0,
        borderGradient: alarm.isEnabled
            ? LinearGradient(
                colors: isDark
                    ? [
                        AppColors.neonCyan,
                        AppColors.neonPink.withAlpha(180),
                        AppColors.plasmaViolet,
                        AppColors.neonYellow.withAlpha(160),
                      ]
                    : [
                        const Color(0xFF009688),
                        const Color(0xFFE0006C),
                        const Color(0xFF7928CA),
                      ],
              )
            : null,
        glowShadows: alarm.isEnabled && isDark
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withAlpha(50),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: AppColors.neonPink.withAlpha(35),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(2, 2),
                ),
              ]
            : null,
        onTap: onTap,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Status Dot, Label & Exaggerated Neon Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: alarm.isEnabled
                            ? (isDark
                                ? AppColors.neonCyan
                                : const Color(0xFF009688))
                            : AppColors.darkTextMuted,
                        boxShadow: alarm.isEnabled
                            ? AppColors.neonGlow(
                                isDark
                                    ? AppColors.neonCyan
                                    : const Color(0xFF009688),
                                blur: 10,
                              )
                            : null,
                      ),
                    ),
                    Text(
                      alarm.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        color: alarm.isEnabled
                            ? (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary)
                            : (isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                      ),
                    ),
                  ],
                ),
                // Exaggerated Neon Switch
                ExaggeratedNeonSwitch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                  activeColor: isDark
                      ? AppColors.neonCyan
                      : const Color(0xFF009688),
                  activeTrackColor: isDark
                      ? AppColors.plasmaViolet
                      : const Color(0xFF7928CA),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Main Time Display (Space Grotesk Bold Digits with Glow)
            ShaderMask(
              shaderCallback: (bounds) {
                if (!alarm.isEnabled) {
                  return const LinearGradient(
                    colors: [Colors.grey, Colors.blueGrey],
                  ).createShader(bounds);
                }
                return (isDark
                        ? AppColors.auroraBorealis
                        : const LinearGradient(
                            colors: [
                              Color(0xFF00796B),
                              Color(0xFF0284C7),
                              Color(0xFF7928CA),
                            ],
                          ))
                    .createShader(bounds);
              },
              child: Text(
                timeStr,
                style: AppTypography.cardTime(
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Repeat Days Pills with animated feedback
            Row(
              children: List.generate(7, (dayIdx) {
                final dayNumber = dayIdx + 1; // 1 = Monday, 7 = Sunday
                final isDayActive = alarm.repeatDays.contains(dayNumber);
                final dayText = DateTimeUtils.getDayAbbreviation(dayNumber);

                return Expanded(
                  child: GestureDetector(
                    onTap: onToggleDay != null ? () => onToggleDay!(dayNumber) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: isDayActive && alarm.isEnabled
                            ? LinearGradient(
                                colors: isDark
                                    ? [
                                        AppColors.neonCyan.withAlpha(70),
                                        AppColors.neonPink.withAlpha(50),
                                      ]
                                    : [
                                        const Color(0xFF009688).withAlpha(45),
                                        const Color(0xFFE0006C).withAlpha(35),
                                      ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDayActive && alarm.isEnabled
                              ? (isDark
                                  ? AppColors.neonCyan.withAlpha(160)
                                  : const Color(0xFF009688).withAlpha(140))
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                          width: 1.2,
                        ),
                        boxShadow: isDayActive && alarm.isEnabled && isDark
                            ? [
                                BoxShadow(
                                  color: AppColors.neonCyan.withAlpha(30),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        dayText,
                        style: AppTypography.badge(
                          color: isDayActive && alarm.isEnabled
                              ? (isDark
                                  ? AppColors.neonCyan
                                  : const Color(0xFF00796B))
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    )
        // Super animated entrance: Slide + Scale + Fade with staggered delay
        .animate()
        .fadeIn(
          duration: 350.ms,
          delay: (index * 80).ms,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: 0.16,
          end: 0,
          duration: 400.ms,
          delay: (index * 80).ms,
          curve: Curves.easeOutBack,
        )
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          delay: (index * 80).ms,
          curve: Curves.easeOutBack,
        );
  }
}
