import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onDelete,
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
      onDismissed: (_) => onDelete(),
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        borderRadius: 28,
        blur: 16,
        borderWidth: alarm.isEnabled ? 1.8 : 1.0,
        borderGradient: alarm.isEnabled
            ? LinearGradient(
                colors: isDark
                    ? [
                        AppColors.neonCyan,
                        AppColors.neonPink.withAlpha(160),
                        AppColors.plasmaViolet,
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
                  color: AppColors.neonCyan.withAlpha(40),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
        onTap: onTap,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Label & Neon Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
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
                                blur: 8,
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
                Switch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Time Display with Space Grotesk Bold Digits
            Text(
              timeStr,
              style: AppTypography.cardTime(
                color: alarm.isEnabled
                    ? (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary)
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
                size: 52,
              ),
            ),

            const SizedBox(height: 14),

            // Repeat Days Neon / Pastel Chips
            Row(
              children: List.generate(7, (index) {
                final dayNumber = index + 1; // 1 = Monday, 7 = Sunday
                final isDayActive = alarm.repeatDays.contains(dayNumber);
                final dayText = DateTimeUtils.getDayAbbreviation(dayNumber);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isDayActive && alarm.isEnabled
                          ? LinearGradient(
                              colors: isDark
                                  ? [
                                      AppColors.neonCyan.withAlpha(60),
                                      AppColors.neonPink.withAlpha(40),
                                    ]
                                  : [
                                      const Color(0xFF009688).withAlpha(45),
                                      const Color(0xFFE0006C).withAlpha(30),
                                    ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDayActive && alarm.isEnabled
                            ? (isDark
                                ? AppColors.neonCyan.withAlpha(140)
                                : const Color(0xFF009688).withAlpha(120))
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        width: 1,
                      ),
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
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.04, end: 0);
  }
}
