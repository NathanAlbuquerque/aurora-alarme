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
/// vertical drag gestures (hours by 1, minutes by 10), steppers, and numeric keyboard entry.
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

  void _adjustHour(int direction) {
    HapticFeedback.selectionClick();
    int newHour = (widget.hour + direction) % 24;
    if (newHour < 0) newHour += 24;
    widget.onChanged(TimeOfDay(hour: newHour, minute: widget.minute));
  }

  void _adjustMinute(int direction, {required bool isDrag}) {
    HapticFeedback.selectionClick();
    int newMinute;

    if (isDrag) {
      // Drag rule: Jump by 10s (00, 10, 20, 30, 40, 50)
      if (direction > 0) {
        // Dragging UP -> increment to next multiple of 10
        newMinute = ((widget.minute ~/ 10) + 1) * 10;
        if (newMinute >= 60) newMinute = 0;
      } else {
        // Dragging DOWN -> decrement to previous multiple of 10
        if (widget.minute % 10 != 0) {
          newMinute = (widget.minute ~/ 10) * 10;
        } else {
          newMinute = widget.minute - 10;
          if (newMinute < 0) newMinute = 50;
        }
      }
    } else {
      // Steppers: adjust by 1 normally
      newMinute = (widget.minute + direction) % 60;
      if (newMinute < 0) newMinute += 60;
    }

    widget.onChanged(TimeOfDay(hour: widget.hour, minute: newMinute));
  }

  void _adjustTime(int delta) {
    if (_activePart == _SelectedTimePart.hour) {
      _adjustHour(delta);
    } else {
      _adjustMinute(delta, isDrag: false);
    }
  }

  void _quickAdd(int minutes) {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final current =
        DateTime(now.year, now.month, now.day, widget.hour, widget.minute);
    final updated = current.add(Duration(minutes: minutes));
    widget.onChanged(TimeOfDay(hour: updated.hour, minute: updated.minute));
  }

  Future<void> _openNativePicker() async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: widget.hour, minute: widget.minute),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Digitar horário',
      hourLabelText: 'Hora',
      minuteLabelText: 'Minuto',
      confirmText: 'CONFIRMAR',
      cancelText: 'CANCELAR',
      errorInvalidText: 'Horário inválido (00:00 - 23:59)',
      builder: (ctx, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? theme.colorScheme.copyWith(
                    primary: AppColors.neonCyan,
                    onPrimary: const Color(0xFF022922),
                    surface: AppColors.darkSurfaceElevated,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : theme.colorScheme.copyWith(
                    primary: const Color(0xFF009688),
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                  ),
            timePickerTheme: theme.timePickerTheme.copyWith(
              backgroundColor:
                  isDark ? AppColors.darkSurface : AppColors.lightSurface,
              hourMinuteColor: isDark
                  ? AppColors.darkSurfaceElevated
                  : const Color(0xFFE2E8F0),
              hourMinuteTextColor:
                  isDark ? AppColors.neonCyan : const Color(0xFF004D40),
              dayPeriodTextColor:
                  isDark ? AppColors.neonCyan : const Color(0xFF004D40),
              entryModeIconColor:
                  isDark ? AppColors.neonCyan : const Color(0xFF009688),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? AppColors.neonCyan : const Color(0xFF009688),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      HapticFeedback.selectionClick();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
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

          const SizedBox(height: 18),

          // Central Time Digits & Controls
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Steppers Column (Left)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepperButton(
                      icon: Icons.keyboard_arrow_up_rounded,
                      tooltip: 'Aumentar',
                      onTap: () => _adjustTime(1),
                    ),
                    const SizedBox(height: 10),
                    _StepperButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      tooltip: 'Diminuir',
                      onTap: () => _adjustTime(-1),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Hour Box with Vertical Drag
                _TimeBox(
                  value: hourStr,
                  label: 'HORA',
                  stepHint: '±1h',
                  isSelected: _activePart == _SelectedTimePart.hour,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activePart = _SelectedTimePart.hour);
                  },
                  onDragStep: (direction) => _adjustHour(direction),
                ),

                // Pulsing Colon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    ':',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color:
                          isDark ? AppColors.neonCyan : const Color(0xFF00796B),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fade(begin: 0.3, end: 1.0, duration: 800.ms),
                ),

                // Minute Box with Vertical Drag
                _TimeBox(
                  value: minuteStr,
                  label: 'MINUTO',
                  stepHint: '±10m',
                  isSelected: _activePart == _SelectedTimePart.minute,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activePart = _SelectedTimePart.minute);
                  },
                  onDragStep: (direction) =>
                      _adjustMinute(direction, isDrag: true),
                ),

                const SizedBox(width: 12),

                // Keyboard Entry Button (Right, beautifully styled and functional)
                _KeyboardEntryButton(
                  onTap: _openNativePicker,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Micro gesture helper pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                    .withAlpha(90),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 15,
                  color: isDark ? AppColors.neonCyan : const Color(0xFF00796B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Arraste vertical: horas 1 em 1 • minutos 10 em 10',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

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

class _TimeBox extends StatefulWidget {
  final String value;
  final String label;
  final String stepHint;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(int direction) onDragStep;

  const _TimeBox({
    required this.value,
    required this.label,
    required this.stepHint,
    required this.isSelected,
    required this.onTap,
    required this.onDragStep,
  });

  @override
  State<_TimeBox> createState() => _TimeBoxState();
}

class _TimeBoxState extends State<_TimeBox> {
  double _accumulatedDelta = 0.0;
  double _visualOffset = 0.0;
  int _lastDirection = 0;
  static const double _kDragThreshold = 24.0;

  void _handleDragStart(DragStartDetails details) {
    widget.onTap();
    _accumulatedDelta = 0.0;
    setState(() => _visualOffset = 0.0);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _accumulatedDelta += details.delta.dy;
    setState(() {
      _visualOffset = (-_accumulatedDelta * 0.28).clamp(-12.0, 12.0);
    });

    // Drag UP (negative dy) -> increment
    while (_accumulatedDelta <= -_kDragThreshold) {
      _lastDirection = 1;
      widget.onDragStep(1);
      _accumulatedDelta += _kDragThreshold;
    }

    // Drag DOWN (positive dy) -> decrement
    while (_accumulatedDelta >= _kDragThreshold) {
      _lastDirection = -1;
      widget.onDragStep(-1);
      _accumulatedDelta -= _kDragThreshold;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _visualOffset = 0.0;
      _accumulatedDelta = 0.0;
    });
  }

  void _handleDragCancel() {
    setState(() {
      _visualOffset = 0.0;
      _accumulatedDelta = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: _handleDragCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? (isDark
                  ? AppColors.neonCyan.withAlpha(45)
                  : const Color(0xFF009688).withAlpha(35))
              : (isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isSelected
                ? (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: widget.isSelected ? 2.0 : 1.0,
          ),
          boxShadow: widget.isSelected && isDark
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withAlpha(70),
                    blurRadius: 18,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Chevron Indicator
            Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 16,
              color: widget.isSelected
                  ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                  : Colors.transparent,
            ),

            // Number with Slide/Fade animation and interactive Drag Offset
            Transform.translate(
              offset: Offset(0, _visualOffset),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) {
                  final inFromBottom = _lastDirection >= 0;
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, inFromBottom ? 0.3 : -0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.value,
                  key: ValueKey(widget.value),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    color: widget.isSelected
                        ? (isDark ? Colors.white : const Color(0xFF004D40))
                        : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ),

            // Bottom Drag Chevron Indicator
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: widget.isSelected
                  ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                  : Colors.transparent,
            ),

            const SizedBox(height: 2),

            // Label & Step Hint (e.g. HORA ±1h or MINUTO ±10m)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: AppTypography.badge(
                    color: widget.isSelected
                        ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                    size: 10,
                  ),
                ),
                if (widget.isSelected) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.neonCyan
                              : const Color(0xFF00796B))
                          .withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.stepHint,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.neonCyan
                            : const Color(0xFF00796B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.neonCyan.withAlpha(40),
          child: Container(
            width: 40,
            height: 38,
            alignment: Alignment.center,
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
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardEntryButton extends StatelessWidget {
  final VoidCallback onTap;

  const _KeyboardEntryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Digitar horário com teclado numérico',
      child: Tooltip(
        message: 'Digitar com teclado numérico',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: AppColors.neonCyan.withAlpha(50),
            highlightColor: AppColors.neonCyan.withAlpha(25),
            child: Container(
              width: 52,
              height: 86,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: (isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated)
                    .withAlpha(isDark ? 180 : 220),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? AppColors.neonCyan.withAlpha(140)
                      : const Color(0xFF009688).withAlpha(140),
                  width: 1.5,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.neonCyan.withAlpha(45),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.keyboard_alt_rounded,
                    size: 24,
                    color: isDark
                        ? AppColors.neonCyan
                        : const Color(0xFF00796B),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'DIGITAR',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isDark
                          ? AppColors.neonCyan
                          : const Color(0xFF00796B),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
