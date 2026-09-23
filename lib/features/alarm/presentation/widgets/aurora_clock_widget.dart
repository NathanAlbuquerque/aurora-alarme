import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_glow_container.dart';

class AuroraClockWidget extends StatefulWidget {
  final String? nextAlarmCountdown;

  const AuroraClockWidget({
    super.key,
    this.nextAlarmCountdown,
  });

  @override
  State<AuroraClockWidget> createState() => _AuroraClockWidgetState();
}

class _AuroraClockWidgetState extends State<AuroraClockWidget> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final secondsStr = DateFormat('ss').format(_currentTime);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_currentTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Next Alarm Pill with vibrant neon aura
          if (widget.nextAlarmCountdown != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                        .withAlpha(isDark ? 50 : 35),
                    (isDark ? AppColors.neonPink : const Color(0xFFE0006C))
                        .withAlpha(isDark ? 40 : 25),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                      .withAlpha(isDark ? 160 : 100),
                  width: 1.5,
                ),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AppColors.neonCyan.withAlpha(50),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm_on_rounded,
                    size: 16,
                    color: isDark ? AppColors.neonCyan : const Color(0xFF00796B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.nextAlarmCountdown!,
                    style: AppTypography.badge(
                      color: isDark ? AppColors.neonCyan : const Color(0xFF004D40),
                      size: 12,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Main Clock Card wrapped in AnimatedGlowContainer
          AnimatedGlowContainer(
            borderRadius: 32,
            primaryGlow: isDark ? AppColors.neonCyan : const Color(0xFF009688),
            secondaryGlow: isDark ? AppColors.neonPink : const Color(0xFFE0006C),
            surfaceColor: isDark
                ? AppColors.darkSurface.withAlpha(200)
                : AppColors.lightSurface.withAlpha(230),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              children: [
                // Live Digital Time with Space Grotesk Bold Digits & Gradient Mask
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
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
                        style: AppTypography.clockDisplay(
                          color: Colors.white,
                          size: 78,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.neonCyan
                                : const Color(0xFF009688))
                            .withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        secondsStr,
                        style: AppTypography.clockSeconds(
                          color: isDark
                              ? AppColors.neonCyan
                              : const Color(0xFF00796B),
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Formatted Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonYellow,
                      ),
                    ),
                    Text(
                      dateStr[0].toUpperCase() + dateStr.substring(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
