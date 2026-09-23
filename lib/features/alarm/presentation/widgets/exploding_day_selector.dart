import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';

/// Interactive Day Selector with bursting particle explosions upon selection
class ExplodingDaySelector extends StatefulWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const ExplodingDaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  State<ExplodingDaySelector> createState() => _ExplodingDaySelectorState();
}

class _ExplodingDaySelectorState extends State<ExplodingDaySelector> {
  void _toggleDay(int day) {
    HapticFeedback.mediumImpact();
    final updated = List<int>.from(widget.selectedDays);
    if (updated.contains(day)) {
      updated.remove(day);
    } else {
      updated.add(day);
      updated.sort();
    }
    widget.onChanged(updated);
  }

  void _applyPreset(List<int> preset) {
    HapticFeedback.mediumImpact();
    widget.onChanged(List<int>.from(preset)..sort());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Presets Header Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetButton(
                label: 'Dias Úteis',
                isSelected: _isEqual(widget.selectedDays, [1, 2, 3, 4, 5]),
                onTap: () => _applyPreset([1, 2, 3, 4, 5]),
              ),
              _PresetButton(
                label: 'Fim de Semana',
                isSelected: _isEqual(widget.selectedDays, [6, 7]),
                onTap: () => _applyPreset([6, 7]),
              ),
              _PresetButton(
                label: 'Todos os Dias',
                isSelected: _isEqual(widget.selectedDays, [1, 2, 3, 4, 5, 6, 7]),
                onTap: () => _applyPreset([1, 2, 3, 4, 5, 6, 7]),
              ),
              _PresetButton(
                label: 'Uma Vez',
                isSelected: widget.selectedDays.isEmpty,
                onTap: () => _applyPreset([]),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 7 Days Exploding Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayNumber = index + 1; // 1 = Monday, 7 = Sunday
            final isSelected = widget.selectedDays.contains(dayNumber);
            final dayName = DateTimeUtils.getDayAbbreviation(dayNumber);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: _ExplodingDayButton(
                  dayNumber: dayNumber,
                  dayName: dayName,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => _toggleDay(dayNumber),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  bool _isEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = List<int>.from(a)..sort();
    final sortedB = List<int>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}

class _ExplodingDayButton extends StatefulWidget {
  final int dayNumber;
  final String dayName;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ExplodingDayButton({
    required this.dayNumber,
    required this.dayName,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ExplodingDayButton> createState() => _ExplodingDayButtonState();
}

class _ExplodingDayButtonState extends State<_ExplodingDayButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _explosionController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_explosionController);
  }

  @override
  void didUpdateWidget(covariant _ExplodingDayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSelected && widget.isSelected) {
      _explosionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _explosionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _explosionController,
      builder: (context, _) {
        final scale = _scaleAnimation.value;
        final explosionProgress = _explosionController.value;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Particle Burst Painter on Selection
            if (_explosionController.isAnimating)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DayBurstPainter(
                    progress: explosionProgress,
                    isDark: widget.isDark,
                  ),
                ),
              ),

            // Main Day Button
            Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  if (!widget.isSelected) {
                    _explosionController.forward(from: 0.0);
                  }
                  widget.onTap();
                },
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: widget.isSelected
                        ? (widget.isDark
                            ? AppColors.auroraBorealis
                            : const LinearGradient(
                                colors: [
                                  Color(0xFF009688),
                                  Color(0xFFE0006C),
                                ],
                              ))
                        : null,
                    color: widget.isSelected
                        ? null
                        : (widget.isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? (widget.isDark
                              ? AppColors.neonCyan
                              : const Color(0xFF009688))
                          : (widget.isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
                      width: widget.isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: (widget.isDark
                                      ? AppColors.neonCyan
                                      : const Color(0xFF009688))
                                  .withAlpha(widget.isDark ? 140 : 80),
                              blurRadius: 16,
                              spreadRadius: -1,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    widget.dayName,
                    style: AppTypography.badge(
                      color: widget.isSelected
                          ? (widget.isDark
                              ? const Color(0xFF02261E)
                              : Colors.white)
                          : (widget.isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                      size: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DayBurstPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _DayBurstPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final count = 8;
    final maxDist = 32.0 * progress;
    final sparkRadius = 3.0 * (1.0 - progress);

    final colors = [
      AppColors.neonCyan,
      AppColors.neonPink,
      AppColors.neonYellow,
      AppColors.neonPurple,
    ];

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count + (progress * 0.5);
      final dist = maxDist + (i % 2 == 0 ? 6 : 0);
      final sparkCenter = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist,
      );

      final paint = Paint()
        ..color = colors[i % colors.length].withAlpha(((1.0 - progress) * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(sparkCenter, sparkRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DayBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.neonCyan.withAlpha(45)
                  : const Color(0xFF009688).withAlpha(30))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
