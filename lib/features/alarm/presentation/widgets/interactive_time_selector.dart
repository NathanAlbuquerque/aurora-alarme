import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/widgets/glass_card.dart';

enum _SelectedTimePart { hour, minute }

/// Modern, tactile, and animated interactive time selector with neon glowing focus,
/// vertical adjustments, and quick-add pills.
class InteractiveTimeSelector extends StatefulWidget {
  final int hour;
  final int minute;
  final ValueChanged<TimeOfDay> onChanged;

  const InteractiveTimeSelector({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  State<InteractiveTimeSelector> createState() => _InteractiveTimeSelectorState();
}

class _InteractiveTimeSelectorState extends State<InteractiveTimeSelector> {
  _SelectedTimePart _activePart = _SelectedTimePart.hour;

  void _adjustTime(int delta) {
    HapticFeedback.selectionClick();
    int newHour = widget.hour;
    int newMinute = widget.minute;

    if (_activePart == _SelectedTimePart.hour) {
      newHour = (newHour + delta) % 24;
      if (newHour < 0) newHour += 24;
    } else {
      newMinute = (newMinute + delta) % 60;
      if (newMinute < 0) newMinute += 60;
    }

    widget.onChanged(TimeOfDay(hour: newHour, minute: newMinute));
  }

  void _quickAdd(int minutes) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, now.day, widget.hour, widget.minute);
    final updated = current.add(Duration(minutes: minutes));
    widget.onChanged(TimeOfDay(hour: updated.hour, minute: updated.minute));
  }

  Future<void> _openNativePicker() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: widget.hour, minute: widget.minute),
      builder: (ctx, child) {
        return Theme(
          data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: child!,
        );
      },
    );
    if (picked != null) {
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hourStr = widget.hour.toString().padLeft(2, '0');
    final minuteStr = widget.minute.toString().padLeft(2, '0');
    final countdown = DateTimeUtils.getNextAlarmCountdown(
      TimeOfDay(hour: widget.hour, minute: widget.minute),
      const [],
    );

    return GlassCard(
      borderRadius: 32,
      blur: 20,
      borderWidth: 2.0,
      borderGradient: AppColors.auroraBorealis,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Countdown Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonCyan.withAlpha(isDark ? 40 : 25),
                  AppColors.neonPink.withAlpha(isDark ? 30 : 20),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                    .withAlpha(100),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timelapse_rounded,
                  size: 15,
                  color: isDark ? AppColors.neonCyan : const Color(0xFF00796B),
                ),
                const SizedBox(width: 8),
                Text(
                  countdown,
                  style: AppTypography.badge(
                    color: isDark ? AppColors.neonCyan : const Color(0xFF004D40),
                    size: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Central Time Digits & Steppers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Increment / Decrement Steppers (Left)
              Column(
                children: [
                  _StepperButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    onTap: () => _adjustTime(1),
                  ),
                  const SizedBox(height: 12),
                  _StepperButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    onTap: () => _adjustTime(-1),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Hour Box
              _TimeBox(
                value: hourStr,
                label: 'HORA',
                isSelected: _activePart == _SelectedTimePart.hour,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activePart = _SelectedTimePart.hour);
                },
              ),

              // Pulsing Colon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  ':',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.neonCyan : const Color(0xFF00796B),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.3, end: 1.0, duration: 800.ms),
              ),

              // Minute Box
              _TimeBox(
                value: minuteStr,
                label: 'MINUTO',
                isSelected: _activePart == _SelectedTimePart.minute,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _activePart = _SelectedTimePart.minute);
                },
              ),

              const SizedBox(width: 16),

              // Native Picker Shortcut Button
              GestureDetector(
                onTap: _openNativePicker,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated)
                        .withAlpha(isDark ? 160 : 220),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Icon(
                    Icons.dialpad_rounded,
                    size: 22,
                    color: isDark ? AppColors.neonYellow : const Color(0xFF7928CA),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Quick-Add Time Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuickChip(label: '+15 min', onTap: () => _quickAdd(15)),
                _QuickChip(label: '+30 min', onTap: () => _quickAdd(30)),
                _QuickChip(label: '+1 hora', onTap: () => _quickAdd(60)),
                _QuickChip(
                  label: 'Agora',
                  onTap: () {
                    final now = TimeOfDay.now();
                    widget.onChanged(now);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeBox({
    required this.value,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.neonCyan.withAlpha(40)
                  : const Color(0xFF009688).withAlpha(30))
              : (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected && isDark
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withAlpha(60),
                    blurRadius: 18,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 68,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF004D40))
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
            Text(
              label,
              style: AppTypography.badge(
                color: isSelected
                    ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                size: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated)
              .withAlpha(isDark ? 160 : 200),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated)
              .withAlpha(isDark ? 140 : 180),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.neonCyan : const Color(0xFF00796B),
          ),
        ),
      ),
    );
  }
}
