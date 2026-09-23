import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';

/// Animated cosmic empty-state illustration with pulsating auroras,
/// glowing celestial spheres, and motivational awakening copy.
class EmptyAlarmsIllustration extends StatelessWidget {
  final VoidCallback onAddAlarm;

  const EmptyAlarmsIllustration({
    super.key,
    required this.onAddAlarm,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: GlassCard(
        borderRadius: 36,
        blur: 20,
        borderGradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.neonCyan.withAlpha(140),
                  AppColors.neonPink.withAlpha(120),
                  AppColors.neonYellow.withAlpha(80),
                ]
              : [
                  const Color(0xFF009688).withAlpha(100),
                  const Color(0xFFE0006C).withAlpha(80),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Celestial Graphic
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Pulsing Neon Ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (isDark ? AppColors.neonPink : const Color(0xFFE0006C))
                            .withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        end: const Offset(1.15, 1.15),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      )
                      .fadeIn(duration: 800.ms),

                  // Middle Glowing Aurora Ring
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                              .withAlpha(70),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                            .withAlpha(120),
                        width: 2,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.05, 1.05),
                        end: const Offset(0.92, 0.92),
                        duration: 1800.ms,
                        curve: Curves.easeInOut,
                      ),

                  // Central Glowing Core (Alarm & Sun Fusion)
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDark
                          ? AppColors.cyberSunset
                          : const LinearGradient(
                              colors: [Color(0xFFFF5400), Color(0xFFFEE440)],
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonPink.withAlpha(160),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .shimmer(
                        delay: 1000.ms,
                        duration: 1800.ms,
                        color: Colors.white.withAlpha(120),
                      ),

                  // Orbiting Sparkles
                  Positioned(
                    top: 10,
                    right: 20,
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.neonYellow,
                      size: 20,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1.3, 1.3),
                          duration: 1200.ms,
                        )
                        .fade(begin: 0.4, end: 1.0),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 20,
                    child: const Icon(
                      Icons.star_rounded,
                      color: AppColors.neonCyan,
                      size: 18,
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.2, 1.2),
                          end: const Offset(0.6, 0.6),
                          duration: 1500.ms,
                        )
                        .fade(begin: 0.3, end: 1.0),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Motivational Headline
            Text(
              'O Silêncio da Noite',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 10),

            // Motivational Body Text
            Text(
              'A aurora aguarda sua jornada. Crie seu primeiro alarme para despertar com a vibração máxima de um novo dia!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 350.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 26),

            // Call to Action Neon Button
            NeonButton(
              text: 'Criar Meu Alarme',
              icon: Icons.add_alarm_rounded,
              variant: NeonButtonVariant.primary,
              height: 52,
              onPressed: onAddAlarm,
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 500.ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    );
  }
}
