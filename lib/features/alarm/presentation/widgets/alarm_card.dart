import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_time_utils.dart';
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(180),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: alarm.isEnabled
                ? (isDark
                    ? AppColors.neonCyan.withAlpha(60)
                    : const Color(0xFF00897B).withAlpha(60))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: alarm.isEnabled ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Label & Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.label_outline,
                          size: 16,
                          color: alarm.isEnabled
                              ? (isDark
                                  ? AppColors.neonCyan
                                  : const Color(0xFF00897B))
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alarm.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

                const SizedBox(height: 8),

                // Main Time Display
                Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: alarm.isEnabled
                        ? (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  ),
                ),

                const SizedBox(height: 12),

                // Repeat Days Chips
                Row(
                  children: List.generate(7, (index) {
                    final dayNumber = index + 1; // 1 = Monday, 7 = Sunday
                    final isDayActive = alarm.repeatDays.contains(dayNumber);
                    final dayText = DateTimeUtils.getDayAbbreviation(dayNumber);

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDayActive && alarm.isEnabled
                              ? (isDark
                                  ? AppColors.neonCyan.withAlpha(40)
                                  : const Color(0xFF00897B).withAlpha(30))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDayActive && alarm.isEnabled
                                ? (isDark
                                    ? AppColors.neonCyan.withAlpha(120)
                                    : const Color(0xFF00897B))
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          dayText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isDayActive
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isDayActive && alarm.isEnabled
                                ? (isDark
                                    ? AppColors.neonCyan
                                    : const Color(0xFF00897B))
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }
}
