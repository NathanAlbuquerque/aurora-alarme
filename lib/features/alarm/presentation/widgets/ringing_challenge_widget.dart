import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';

/// Modular, plug-and-play Wakeup Challenge Widget.
/// Supports 'math', 'shake', and 'memory' mini-games.
class RingingChallengeWidget extends StatefulWidget {
  final String challengeType; // 'math', 'shake', 'memory', 'none'
  final VoidCallback onCompleted;

  const RingingChallengeWidget({
    super.key,
    required this.challengeType,
    required this.onCompleted,
  });

  @override
  State<RingingChallengeWidget> createState() => _RingingChallengeWidgetState();
}

class _RingingChallengeWidgetState extends State<RingingChallengeWidget> {
  // Math Challenge State
  late int _mathNum1;
  late int _mathNum2;
  int? _selectedMathOption;
  late List<int> _mathOptions;

  // Shake Challenge State
  int _shakeCounter = 0;
  static const int _targetShakes = 12;

  // Memory Challenge State
  final List<int> _memorySequence = [0, 2, 1]; // Sequence of color indices
  final List<int> _playerMemoryInput = [];
  bool _memoryShowingSequence = true;
  int? _memoryHighlightedIndex;

  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initChallenge();
  }

  void _initChallenge() {
    _isSuccess = false;

    if (widget.challengeType == 'math') {
      final rand = math.Random();
      _mathNum1 = 15 + rand.nextInt(35);
      _mathNum2 = 12 + rand.nextInt(28);
      final correct = _mathNum1 + _mathNum2;
      _mathOptions = [
        correct,
        correct - (rand.nextInt(4) + 1),
        correct + (rand.nextInt(5) + 1),
        correct + 10,
      ]..shuffle();
      _selectedMathOption = null;
    } else if (widget.challengeType == 'shake') {
      _shakeCounter = 0;
    } else if (widget.challengeType == 'memory') {
      _playerMemoryInput.clear();
      _playMemorySequencePreview();
    }
  }

  Future<void> _playMemorySequencePreview() async {
    setState(() => _memoryShowingSequence = true);
    await Future.delayed(const Duration(milliseconds: 600));

    for (int step in _memorySequence) {
      if (!mounted) return;
      setState(() => _memoryHighlightedIndex = step);
      HapticFeedback.selectionClick();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _memoryHighlightedIndex = null);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (mounted) {
      setState(() => _memoryShowingSequence = false);
    }
  }

  void _markSuccess() {
    setState(() => _isSuccess = true);
    HapticFeedback.heavyImpact();
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.challengeType == 'none') {
      return const SizedBox.shrink();
    }

    return GlassCard(
      borderRadius: 24,
      blur: 24,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderGradient: LinearGradient(
        colors: _isSuccess
            ? [AppColors.neonLime, AppColors.neonCyan]
            : [AppColors.neonPink.withAlpha(120), AppColors.neonCyan.withAlpha(120)],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isSuccess
            ? _buildSuccessBanner()
            : _buildActiveChallengeContent(),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonLime,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.black, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          'DESAFIO CONCLUÍDO! LIBERADO',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.neonLime,
            letterSpacing: 1.0,
          ),
        ),
      ],
    )
        .animate()
        .scale(duration: 400.ms, curve: Curves.elasticOut)
        .shimmer(duration: 800.ms, color: Colors.white);
  }

  Widget _buildActiveChallengeContent() {
    switch (widget.challengeType) {
      case 'math':
        return _buildMathView();
      case 'shake':
        return _buildShakeView();
      case 'memory':
        return _buildMemoryView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMathView() {
    final correct = _mathNum1 + _mathNum2;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calculate_rounded, color: AppColors.neonYellow, size: 20),
            const SizedBox(width: 8),
            Text(
              'Resolva: $_mathNum1 + $_mathNum2 = ?',
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
            final isChosen = _selectedMathOption == opt;
            final isCorrectAnswer = isChosen && opt == correct;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedMathOption = opt);
                if (opt == correct) {
                  _markSuccess();
                } else {
                  HapticFeedback.vibrate();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isChosen
                      ? (isCorrectAnswer ? AppColors.neonLime : Colors.redAccent)
                      : AppColors.darkSurfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isChosen ? Colors.white : AppColors.darkBorder,
                    width: 1.5,
                  ),
                  boxShadow: isChosen
                      ? [
                          BoxShadow(
                            color: (isCorrectAnswer ? AppColors.neonLime : Colors.redAccent)
                                .withAlpha(140),
                            blurRadius: 12,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  '$opt',
                  style: GoogleFonts.spaceGrotesk(
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
    );
  }

  Widget _buildShakeView() {
    final progress = (_shakeCounter / _targetShakes).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vibration_rounded, color: AppColors.neonCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              'Agite ou toque rápido! ($_shakeCounter/$_targetShakes)',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.darkSurfaceElevated,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _shakeCounter++;
              if (_shakeCounter >= _targetShakes) {
                _markSuccess();
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonCyan.withAlpha(40),
                  AppColors.plasmaViolet.withAlpha(40),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonCyan.withAlpha(100)),
            ),
            child: Text(
              'Toque aqui repetidamente ⚡',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.neonCyan,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryView() {
    final colors = [AppColors.neonCyan, AppColors.neonPink, AppColors.neonYellow];
    final labels = ['Azul', 'Rosa', 'Amarelo'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_rounded, color: AppColors.neonPink, size: 20),
            const SizedBox(width: 8),
            Text(
              _memoryShowingSequence
                  ? 'Memorize a sequência...'
                  : 'Repita a ordem das cores!',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final isLit = _memoryHighlightedIndex == index;
            final color = colors[index];

            return GestureDetector(
              onTap: _memoryShowingSequence
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _playerMemoryInput.add(index);
                      });

                      // Check correctness
                      final currentIndex = _playerMemoryInput.length - 1;
                      if (_playerMemoryInput[currentIndex] != _memorySequence[currentIndex]) {
                        // Mistake: reset and show sequence again
                        HapticFeedback.vibrate();
                        _initChallenge();
                        return;
                      }

                      if (_playerMemoryInput.length == _memorySequence.length) {
                        _markSuccess();
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isLit ? color : color.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isLit ? Colors.white : color,
                    width: isLit ? 3 : 1.5,
                  ),
                  boxShadow: isLit
                      ? [
                          BoxShadow(
                            color: color,
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      : [],
                ),
                child: Text(
                  labels[index],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isLit ? Colors.black : Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
