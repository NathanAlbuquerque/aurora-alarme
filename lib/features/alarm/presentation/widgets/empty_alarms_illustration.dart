import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';

import 'rive_empty_cosmos_animation.dart';

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
            // Kinetic Rive Vector Cosmos Animation Core
            RiveEmptyCosmosAnimation(
              size: 165,
              onTap: onAddAlarm,
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
