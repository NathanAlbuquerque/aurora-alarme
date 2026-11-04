import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../utils/haptic_utils.dart';
import '../utils/permission_utils.dart';
import 'neon_button.dart';

/// Elegant cosmic dialog that educates the user about Full-Screen Intent permission
/// without forcing or interrupting navigation repeatedly.
class FullScreenIntentDialog extends StatelessWidget {
  const FullScreenIntentDialog({super.key});

  /// Displays the dialog if needed.
  static Future<bool?> show(BuildContext context) {
    AppHaptics.mediumImpact();
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'FullScreenIntentDialog',
      barrierColor: Colors.black.withAlpha(200),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const FullScreenIntentDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.neonCyan.withAlpha(70),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withAlpha(isDark ? 35 : 20),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Radiant Alarm Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonCyan.withAlpha(40),
                          AppColors.plasmaViolet.withAlpha(40),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.neonCyan.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.screen_lock_portrait_rounded,
                      color: AppColors.neonCyan,
                      size: 38,
                    ),
                  )
                      .animate()
                      .scale(duration: 400.ms, curve: Curves.easeOutBack)
                      .shimmer(
                        duration: 1800.ms,
                        color: AppColors.neonCyan.withAlpha(80),
                      ),

                  const SizedBox(height: 20),

                  // 2. Title
                  Text(
                    'Alarmes na Tela de Bloqueio',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 3. Educational Description
                  Text(
                    'Para que o alarme toque e apareça diretamente sobre a tela de bloqueio quando você estiver dormindo, o Android precisa da permissão de notificações em tela cheia.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Sem essa permissão, o alarme pode apenas vibrar ou exibir um banner simples.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.solarYellow,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. Action: Ativar Permissão
                  NeonButton(
                    text: 'ATIVAR PERMISSÃO',
                    variant: NeonButtonVariant.primary,
                    icon: Icons.check_circle_outline_rounded,
                    isFullWidth: true,
                    onPressed: () async {
                      AppHaptics.selectionTick();
                      Navigator.of(context).pop(true);
                      await PermissionUtils.openFullScreenIntentSettings();
                    },
                  ),

                  const SizedBox(height: 12),

                  // 5. Action: Agora Não
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        AppHaptics.lightTap();
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'Agora não',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
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
