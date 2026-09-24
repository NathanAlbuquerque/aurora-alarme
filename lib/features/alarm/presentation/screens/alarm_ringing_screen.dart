import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/alarm_service.dart';
import '../../../../core/services/audio_ringtone_service.dart';
import '../../../../core/services/screen_control_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/alarm_model.dart';
import '../widgets/hold_to_dismiss_button.dart';
import '../widgets/hypnotic_ringing_background.dart';
import '../widgets/ringing_challenge_widget.dart';

/// Full-Screen Alarm Screen displayed over lockscreen when alarm triggers.
/// Hyper-aesthetic, hypnotic visuals engineered to wake the user up with energy.
class AlarmRingingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingingScreen({
    super.key,
    required this.alarm,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen>
    with TickerProviderStateMixin {
  late DateTime _currentTime;
  late Timer _clockTimer;
  bool _isChallengeCompleted = false;
  late String _activeChallenge;
  bool _isDismissing = false;

  late AnimationController _equalizerController;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _activeChallenge = widget.alarm.mission;
    _isChallengeCompleted = widget.alarm.mission == 'none';

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // Ensure screen is awake and shown over lockscreen
    ScreenControlService.instance.wakeUpScreen();

    // Start looping audio and vibration
    AudioRingtoneService.instance.startAlarmRingtone(
      vibrate: widget.alarm.vibrate,
      soundName: widget.alarm.sound,
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _equalizerController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    HapticFeedback.heavyImpact();
    await AudioRingtoneService.instance.stop();
    await AlarmService.instance.cancelAlarm(widget.alarm.id);
    await ScreenControlService.instance.dismissLockscreen();

    // Brief supernova flash delay before exiting
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _handleSnooze() async {
    if (_isDismissing) return;
    setState(() => _isDismissing = true);

    HapticFeedback.mediumImpact();
    await AudioRingtoneService.instance.stop();
    await AlarmService.instance.snoozeAlarm(
      widget.alarm,
      minutes: widget.alarm.snoozeMinutes,
    );
    await ScreenControlService.instance.dismissLockscreen();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = DateFormat('HH').format(_currentTime);
    final minuteStr = DateFormat('mm').format(_currentTime);
    final secondsStr = DateFormat('ss').format(_currentTime);
    final dateStr = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_currentTime);
    final formattedDate = dateStr[0].toUpperCase() + dateStr.substring(1);

    return PopScope(
      canPop: false, // Prevent dismissing by accidental back gesture
      child: Scaffold(
        backgroundColor: AppColors.darkVoid,
        body: HypnoticRingingBackground(
          enableRumble: !_isDismissing,
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Beacon Header
                      _buildTopHeader(),

                      // Center Time & Audio Reactive Equalizer Core
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGiantPulsatingClock(hourStr, minuteStr, secondsStr),
                          const SizedBox(height: 16),
                          _buildAlarmLabelBadge(formattedDate),
                        ],
                      ),

                      // Wakeup Challenge Area
                      if (_activeChallenge != 'none')
                        RingingChallengeWidget(
                          challengeType: _activeChallenge,
                          onCompleted: () {
                            setState(() => _isChallengeCompleted = true);
                          },
                        )
                      else
                        _buildChallengePickerHint(),

                      // Bottom Action Controls
                      _buildBottomControls(),
                    ],
                  ),
                ),
              ),

              // Supernova flash overlay on dismissal
              if (_isDismissing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                  )
                      .animate()
                      .fadeIn(duration: 100.ms)
                      .fadeOut(duration: 250.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkSurfaceElevated.withAlpha(200),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.neonPink.withAlpha(180),
          width: 1.5,
        ),
        boxShadow: AppColors.neonGlow(AppColors.neonPink, blur: 24),
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
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.6, 1.6),
                duration: 500.ms,
              )
              .shimmer(duration: 700.ms, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            'ALARME TOCANDO • ACORDE!',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildGiantPulsatingClock(
      String hourStr, String minuteStr, String secondsStr) {
    return Column(
      children: [
        // Reactive Equalizer Bars on top of Clock
        SizedBox(
          height: 24,
          child: AnimatedBuilder(
            animation: _equalizerController,
            builder: (context, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(12, (index) {
                  final phase = (index / 12) * math.pi;
                  final heightFactor =
                      (math.sin(_equalizerController.value * math.pi * 2 + phase).abs() *
                              16 +
                          4)
                          .clamp(4.0, 24.0);

                  final colors = [
                    AppColors.neonCyan,
                    AppColors.plasmaViolet,
                    AppColors.neonPink,
                    AppColors.neonYellow,
                  ];
                  final barColor = colors[index % colors.length];

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 3.5,
                    height: heightFactor,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withAlpha(160),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Giant Double-Beating Neon Clock
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Hours & Minutes in Chromatic Gradient Text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppColors.neonCyan,
                  AppColors.neonPink,
                  AppColors.neonYellow,
                ],
                stops: [0.0, 0.55, 1.0],
              ).createShader(bounds),
              child: Text(
                '$hourStr:$minuteStr',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 88,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -4,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Seconds Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.neonCyan.withAlpha(120),
                  width: 1,
                ),
              ),
              child: Text(
                secondsStr,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neonCyan,
                ),
              ),
            ),
          ],
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 700.ms,
              curve: Curves.easeInOutBack,
            ),
      ],
    );
  }

  Widget _buildAlarmLabelBadge(String formattedDate) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkSurfaceElevated.withAlpha(190),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.neonCyan.withAlpha(140),
              width: 1.5,
            ),
            boxShadow: AppColors.neonGlow(AppColors.neonCyan, blur: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.label_important_rounded,
                  color: AppColors.neonCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.alarm.label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengePickerHint() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showChallengePreviewModal();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports_rounded,
                color: AppColors.neonYellow, size: 16),
            const SizedBox(width: 8),
            Text(
              'Testar mini-jogo para acordar ⚡',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.neonYellow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengePreviewModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha um mini-jogo para testar:',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calculate_rounded,
                    color: AppColors.neonYellow),
                title: const Text('Matemática Mental',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Resolva uma soma antes de desligar',
                    style: TextStyle(color: AppColors.darkTextMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeChallenge = 'math';
                    _isChallengeCompleted = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.vibration_rounded,
                    color: AppColors.neonCyan),
                title: const Text('Chacoalhar o Aparelho',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Agite seu telefone para despertar os sentidos',
                    style: TextStyle(color: AppColors.darkTextMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeChallenge = 'shake';
                    _isChallengeCompleted = false;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology_rounded,
                    color: AppColors.neonPink),
                title: const Text('Sequência de Cores (Memória)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Repita as luzes na ordem para ativar o cérebro',
                    style: TextStyle(color: AppColors.darkTextMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _activeChallenge = 'memory';
                    _isChallengeCompleted = false;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tactile Press & Hold To Dismiss Button
        HoldToDismissButton(
          onDismiss: _handleDismiss,
          isLocked: !_isChallengeCompleted,
          lockedMessage: 'RESOLVA O DESAFIO PRIMEIRO',
        ),

        const SizedBox(height: 16),

        // Snooze Button with Moon Aura
        GestureDetector(
          onTap: _handleSnooze,
          child: Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkSurfaceElevated.withAlpha(180),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.neonCyan.withAlpha(120),
                width: 1.5,
              ),
              boxShadow: AppColors.neonGlow(AppColors.neonCyan, blur: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bedtime_rounded,
                  color: AppColors.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Soneca (+${widget.alarm.snoozeMinutes} min)',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          'Segure o botão de desligar para silenciar o alarme',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.darkTextMuted,
          ),
        ),
      ],
    );
  }
}
