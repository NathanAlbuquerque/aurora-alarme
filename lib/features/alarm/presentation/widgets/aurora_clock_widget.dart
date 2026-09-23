import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Next Alarm Pill
          if (widget.nextAlarmCountdown != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonCyan.withAlpha(isDark ? 40 : 30),
                    AppColors.cosmicMagenta.withAlpha(isDark ? 30 : 20),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.neonCyan.withAlpha(isDark ? 100 : 70),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm,
                    size: 16,
                    color: isDark ? AppColors.neonCyan : const Color(0xFF00897B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.nextAlarmCountdown!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.neonCyan : const Color(0xFF00695C),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),

          // Main Digital Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return (isDark
                          ? AppColors.auroraPrimaryGradient
                          : const LinearGradient(
                              colors: [Color(0xFF00695C), Color(0xFF0284C7)],
                            ))
                      .createShader(bounds);
                },
                child: Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                secondsStr,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Capitalized Date in Portuguese
          Text(
            dateStr[0].toUpperCase() + dateStr.substring(1),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
