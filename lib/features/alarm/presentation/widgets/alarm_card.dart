import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/haptic_utils.dart';
import '../../../../shared/widgets/exaggerated_neon_switch.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../models/alarm_model.dart';

class AlarmCard extends StatefulWidget {
  final AlarmModel alarm;
  final int index;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final ValueChanged<int>? onToggleDay;
  final VoidCallback? onTap;
  final double parallaxOffset;
  final double glowMultiplier;

  const AlarmCard({
    super.key,
    required this.alarm,
    this.index = 0,
    required this.onToggle,
    required this.onDelete,
    this.onToggleDay,
    this.onTap,
    this.parallaxOffset = 0.0,
    this.glowMultiplier = 1.0,
  });

  @override
  State<AlarmCard> createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateTimeUtils.formatTimeOfDay(widget.alarm.timeOfDay);
    final isEnabled = widget.alarm.isEnabled;

    // Dynamically scaled glow shadows based on active state and scroll proximity
    final glowAlphaCyan = (50 * widget.glowMultiplier).clamp(0, 255).round();
    final glowAlphaPink = (35 * widget.glowMultiplier).clamp(0, 255).round();
    final glowRadiusCyan = 24.0 * widget.glowMultiplier;
    final glowRadiusPink = 28.0 * widget.glowMultiplier;

    return Dismissible(
      key: Key('alarm_${widget.alarm.id}'),
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
        widget.onDelete();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Listener(
          onPointerDown: (_) {
            setState(() => _isPressed = true);
          },
          onPointerUp: (_) {
            setState(() => _isPressed = false);
          },
          onPointerCancel: (_) {
            setState(() => _isPressed = false);
          },
          child: GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            borderRadius: 28,
            blur: 18,
            borderWidth: isEnabled ? 2.0 : 1.0,
            borderGradient: isEnabled
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
            glowShadows: isEnabled && isDark
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withAlpha(glowAlphaCyan),
                      blurRadius: glowRadiusCyan,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.neonPink.withAlpha(glowAlphaPink),
                      blurRadius: glowRadiusPink,
                      spreadRadius: -4,
                      offset: const Offset(2, 2),
                    ),
                  ]
                : null,
            onTap: () {
              AppHaptics.lightTap();
              widget.onTap?.call();
            },
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
                        // Animated Pulsing Status Dot
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isEnabled
                                ? (isDark
                                    ? AppColors.neonCyan
                                    : const Color(0xFF009688))
                                : AppColors.darkTextMuted,
                            boxShadow: isEnabled
                                ? AppColors.neonGlow(
                                    isDark
                                        ? AppColors.neonCyan
                                        : const Color(0xFF009688),
                                    blur: 10 * widget.glowMultiplier,
                                  )
                                : null,
                          ),
                        )
                            .animate(
                              target: isEnabled ? 1.0 : 0.0,
                              onPlay: (c) => isEnabled ? c.repeat(reverse: true) : null,
                            )
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.25, 1.25),
                              duration: 1200.ms,
                            ),
                        Text(
                          widget.alarm.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isEnabled
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
                      value: isEnabled,
                      onChanged: (val) {
                        AppHaptics.mediumImpact();
                        widget.onToggle(val);
                      },
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

                // Main Time Display with Multiplane Parallax Shift
                Transform.translate(
                  offset: Offset(0, widget.parallaxOffset * 0.45),
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      if (!isEnabled) {
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
                ),

                const SizedBox(height: 14),

                // Repeat Days Pills with Individual Tactile Spring Physics
                Row(
                  children: List.generate(7, (dayIdx) {
                    final dayNumber = dayIdx + 1; // 1 = Monday, 7 = Sunday
                    final isDayActive = widget.alarm.repeatDays.contains(dayNumber);
                    final dayText = DateTimeUtils.getDayAbbreviation(dayNumber);

                    return Expanded(
                      child: _AnimatedDayPill(
                        dayNumber: dayNumber,
                        dayText: dayText,
                        isActive: isDayActive,
                        isEnabled: isEnabled,
                        isDark: isDark,
                        onTap: widget.onToggleDay != null
                            ? () => widget.onToggleDay!(dayNumber)
                            : null,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        // Staggered entrance animation
        .animate()
        .fadeIn(
          duration: 350.ms,
          delay: (widget.index * 80).ms,
          curve: Curves.easeOutQuad,
        )
        .slideY(
          begin: 0.16,
          end: 0,
          duration: 400.ms,
          delay: (widget.index * 80).ms,
          curve: Curves.easeOutBack,
        )
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          delay: (widget.index * 80).ms,
          curve: Curves.easeOutBack,
        );
  }
}

/// Tactile day selector pill with squishy spring feedback and haptic tick
class _AnimatedDayPill extends StatefulWidget {
  final int dayNumber;
  final String dayText;
  final bool isActive;
  final bool isEnabled;
  final bool isDark;
  final VoidCallback? onTap;

  const _AnimatedDayPill({
    required this.dayNumber,
    required this.dayText,
    required this.isActive,
    required this.isEnabled,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AnimatedDayPill> createState() => _AnimatedDayPillState();
}

class _AnimatedDayPillState extends State<_AnimatedDayPill> {
  bool _isPillPressed = false;

  void _handleTap() {
    AppHaptics.selectionTick();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive && widget.isEnabled;

    return AnimatedScale(
      scale: _isPillPressed ? 0.88 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPillPressed = true),
        onTapUp: (_) => setState(() => _isPillPressed = false),
        onTapCancel: () => setState(() => _isPillPressed = false),
        onTap: widget.onTap != null ? _handleTap : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: widget.isDark
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
              color: active
                  ? (widget.isDark
                      ? AppColors.neonCyan.withAlpha(160)
                      : const Color(0xFF009688).withAlpha(140))
                  : (widget.isDark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder),
              width: 1.2,
            ),
            boxShadow: active && widget.isDark
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withAlpha(30),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.dayText,
            style: AppTypography.badge(
              color: active
                  ? (widget.isDark
                      ? AppColors.neonCyan
                      : const Color(0xFF00796B))
                  : (widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted),
              size: 11,
            ),
          ),
        ),
      ),
    );
  }
}
