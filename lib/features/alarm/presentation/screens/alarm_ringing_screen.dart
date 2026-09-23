import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/audio_ringtone_service.dart';
import '../../../../core/services/screen_control_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../models/alarm_model.dart';

/// Full-Screen Alarm Screen displayed over lockscreen when alarm triggers
class AlarmRingingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingingScreen({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  late DateTime _currentTime;
  late Timer _clockTimer;

  // Math challenge state
  int _num1 = 24;
  int _num2 = 19;
  int? _selectedMathAnswer;
  late List<int> _mathOptions;

  // Shake challenge state
  int _shakeCount = 0;
  static const int _targetShakes = 15;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    // Ensure screen is awake and shown over lockscreen
    ScreenControlService.instance.wakeUpScreen();

    // Start looping audio and vibration
    AudioRingtoneService.instance.startAlarmRingtone(
      vibrate: widget.alarm.vibrate,
      soundName: widget.alarm.sound,
    );

    // Initialize math challenge if enabled
    if (widget.alarm.mission == 'math') {
      _num1 = 15 + DateTime.now().minute % 30;
      _num2 = 12 + DateTime.now().second % 25;
      final correct = _num1 + _num2;
      _mathOptions = [correct, correct - 3, correct + 5, correct + 10]..shuffle();
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    HapticFeedback.heavyImpact();
    await AudioRingtoneService.instance.stop();
    await AlarmService.instance.cancelAlarm(widget.alarm.id);
    await ScreenControlService.instance.dismissLockscreen();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSnooze() async {
    HapticFeedback.mediumImpact();
    await AlarmService.instance.snoozeAlarm(
      widget.alarm,
      minutes: widget.alarm.snoozeMinutes,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(_currentTime);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_currentTime);

    return PopScope(
      canPop: false, // Prevent dismissing by accidental back button
      child: Scaffold(
        body: AnimatedGradientBackground(
          showParticles: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Banner: Live Alarm Beacon
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonPink.withAlpha(50),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.neonPink,
                        width: 2,
                      ),
                      boxShadow: AppColors.neonGlow(AppColors.neonPink, blur: 20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.neonPink,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1.5, 1.5),
                              duration: 500.ms,
                            ),
                        const SizedBox(width: 10),
                        Text(
                          'DESPERTANDO • AURORA ALARM',
                          style: AppTypography.badge(
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center: Ringing Time Display with Soundwave Halo
                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Pulsating Soundwave
                          Container(
                            width: 280,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppColors.neonCyan.withAlpha(70),
                                width: 2,
                              ),
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.18, 1.18),
                                duration: 1000.ms,
                                curve: Curves.easeInOut,
                              ),

                          // Inner Time Core
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.auroraBorealis,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: AppColors.multiGlow(
                                primary: AppColors.neonCyan,
                                secondary: AppColors.neonPink,
                                blur: 32,
                              ),
                            ),
                            child: Text(
                              timeStr,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 80,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -3,
                                color: const Color(0xFF02261E),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        widget.alarm.label,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr[0].toUpperCase() + dateStr.substring(1),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Middle: Mission Challenge / Wake-up Verification
                  if (widget.alarm.mission == 'math')
                    _buildMathChallengeCard()
                  else if (widget.alarm.mission == 'shake')
                    _buildShakeChallengeCard()
                  else
                    const SizedBox(height: 20),

                  // Bottom Action Buttons: Snooze & Turn Off
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NeonButton(
                              text: 'Soneca (${widget.alarm.snoozeMinutes}m)',
                              icon: Icons.snooze_rounded,
                              variant: NeonButtonVariant.outlined,
                              height: 56,
                              onPressed: _handleSnooze,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: NeonButton(
                              text: 'DESLIGAR',
                              icon: Icons.alarm_off_rounded,
                              variant: NeonButtonVariant.secondary,
                              height: 56,
                              onPressed: (widget.alarm.mission == 'math' &&
                                          _selectedMathAnswer != (_num1 + _num2)) ||
                                      (widget.alarm.mission == 'shake' &&
                                          _shakeCount < _targetShakes)
                                  ? null
                                  : _handleDismiss,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Toque em desligar para iniciar seu dia',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.darkTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMathChallengeCard() {
    final correct = _num1 + _num2;

    return GlassCard(
      borderRadius: 28,
      blur: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.neonYellow),
              const SizedBox(width: 8),
              Text(
                'Resolva para desbloquear: $_num1 + $_num2 = ?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _mathOptions.map((opt) {
              final isChosen = _selectedMathAnswer == opt;
              final isRight = isChosen && opt == correct;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedMathAnswer = opt);
                  if (opt == correct) {
                    HapticFeedback.heavyImpact();
                  }
                },
                child: Container(
                  width: 60,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isChosen
                        ? (isRight ? AppColors.neonCyan : Colors.red)
                        : AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChosen
                          ? Colors.white
                          : AppColors.darkBorder,
                    ),
                  ),
                  child: Text(
                    opt.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isChosen ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShakeChallengeCard() {
    return GlassCard(
      borderRadius: 28,
      blur: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vibration_rounded, color: AppColors.neonCyan),
              const SizedBox(width: 8),
              Text(
                'Chacoalhe o celular! ($_shakeCount/$_targetShakes)',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _shakeCount / _targetShakes,
            backgroundColor: AppColors.darkSurfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (_shakeCount < _targetShakes) {
                setState(() => _shakeCount++);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Toque ou chacoalhe para avançar',
                style: TextStyle(fontSize: 12, color: AppColors.neonCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
