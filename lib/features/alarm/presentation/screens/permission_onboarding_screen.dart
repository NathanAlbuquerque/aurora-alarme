import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/navigation/aurora_page_route.dart';
import '../../../../core/services/screen_control_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/haptic_utils.dart';
import '../../../../shared/utils/permission_utils.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';

/// Commercial-grade Permission Onboarding & OEM Configuration Screen.
/// Guides users on Xiaomi (HyperOS/MIUI), Samsung, Oppo, Vivo, Huawei, Motorola,
/// and Stock Android to enable lockscreen display, background window launch,
/// overlays, full-screen intents, and battery exemptions.
class PermissionOnboardingScreen extends StatefulWidget {
  final bool isManualOpen;

  const PermissionOnboardingScreen({
    super.key,
    this.isManualOpen = false,
  });

  /// Helper to push this screen using AuroraPageRoute.
  static Future<bool?> show(
    BuildContext context, {
    bool isManualOpen = false,
  }) {
    return Navigator.of(context).push<bool>(
      AuroraPageRoute(
        page: PermissionOnboardingScreen(isManualOpen: isManualOpen),
      ),
    );
  }

  @override
  State<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen>
    with WidgetsBindingObserver {
  PermissionsStatus _status = PermissionsStatus.allGrantedDefault();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PermissionUtils.setPermissionOnboardingSeen(true);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final status = await ScreenControlService.instance.getPermissionsStatus();
    if (!mounted) return;
    setState(() {
      _status = status;
      _isLoading = false;
    });

    if (status.allCriticalGranted && status.isBatteryOptimizationIgnored) {
      await PermissionUtils.setPermissionOnboardingCompleted(true);
    }
  }

  /// Smart handler for the primary "Abrir configurações e ativar" button.
  /// Opens the most relevant pending settings screen for the current device.
  Future<void> _handleOpenSmartSettings() async {
    AppHaptics.mediumImpact();

    // 1. Ensure standard runtime permissions (notifications / exact alarm) are requested first
    await PermissionUtils.requestBasicRuntimePermissions();

    // 2. If Xiaomi or OEM with special lockscreen/background locks, open the OEM Permission Editor
    if (_status.isXiaomi &&
        (!_status.xiaomiShowOnLockScreen ||
            !_status.xiaomiBackgroundStartActivity)) {
      await ScreenControlService.instance.openManufacturerPermissionSettings();
      return;
    }

    // 3. Android 14+ Full Screen Intent
    if (!_status.canUseFullScreenIntent) {
      await ScreenControlService.instance.openFullScreenIntentSettings();
      return;
    }

    // 4. SYSTEM_ALERT_WINDOW (Display over other apps / Pop-up window)
    if (!_status.canDrawOverlays) {
      if (_status.isXiaomi) {
        await ScreenControlService.instance
            .openManufacturerPermissionSettings();
      } else {
        await ScreenControlService.instance.openOverlaySettings();
      }
      return;
    }

    // 5. Battery optimization
    if (!_status.isBatteryOptimizationIgnored) {
      await ScreenControlService.instance.requestIgnoreBatteryOptimizations();
      return;
    }

    // 6. Default fallback: open OEM permission editor or App Details
    await ScreenControlService.instance.openManufacturerPermissionSettings();
  }

  Future<void> _handleCompleteOrContinue() async {
    AppHaptics.lightTap();
    await PermissionUtils.setPermissionOnboardingSeen(true);
    await PermissionUtils.setPermissionOnboardingCompleted(true);

    await _refreshPermissions();
    if (!mounted) return;

    final hasMissingCritical = !_status.allCriticalGranted;

    if (hasMissingCritical && !widget.isManualOpen) {
      final shouldExitAnyway = await _showPoliteWarningDialog();
      if (shouldExitAnyway != true || !mounted) return;
    }

    Navigator.of(context).pop(true);
  }

  Future<bool?> _showPoliteWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.solarYellow.withAlpha(110),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.solarYellow.withAlpha(35),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.solarYellow.withAlpha(25),
                    border: Border.all(
                      color: AppColors.solarYellow.withAlpha(120),
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.solarYellow,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Algumas permissões parecem desativadas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sem essas permissões, o sistema pode impedir que a tela do alarme apareça quando o celular estiver bloqueado.\n\nVocê pode continuar usando o app normalmente e ativar depois pelo ícone de escudo no topo da tela inicial.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: AppColors.darkTextSecondary.withAlpha(60),
                            ),
                          ),
                        ),
                        child: Text(
                          'Continuar assim',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(false);
                          _handleOpenSmartSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: AppColors.darkVoid,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Verificar agora',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkVoid,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allReady =
        _status.allCriticalGranted && _status.isBatteryOptimizationIgnored;

    return Scaffold(
      body: AnimatedGradientBackground(
        showParticles: true,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top bar with close button & manufacturer badge
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Manufacturer / OS pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated)
                              .withAlpha(200),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.neonCyan.withAlpha(90),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              size: 15,
                              color: AppColors.neonCyan,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _status.manufacturerDisplayName,
                              style: AppTypography.badge(
                                color: isDark
                                    ? AppColors.neonCyan
                                    : const Color(0xFF00796B),
                                size: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      IconButton(
                        onPressed: _handleCompleteOrContinue,
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Icon + Title + Explanation
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      // Glowing Shield / Lockscreen Icon
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: allReady
                                ? [
                                    AppColors.acidGreen.withAlpha(55),
                                    AppColors.neonCyan.withAlpha(30),
                                  ]
                                : [
                                    AppColors.neonCyan.withAlpha(50),
                                    AppColors.plasmaViolet.withAlpha(45),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: allReady
                                ? AppColors.acidGreen
                                : AppColors.neonCyan.withAlpha(160),
                            width: 1.8,
                          ),
                          boxShadow: AppColors.neonGlow(
                            allReady ? AppColors.acidGreen : AppColors.neonCyan,
                            blur: 24,
                            opacity: 0.35,
                          ),
                        ),
                        child: Icon(
                          allReady
                              ? Icons.verified_user_rounded
                              : Icons.screen_lock_portrait_rounded,
                          color: allReady
                              ? AppColors.acidGreen
                              : AppColors.neonCyan,
                          size: 38,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.04, 1.04),
                            duration: 1800.ms,
                          ),

                      const SizedBox(height: 18),

                      // Strong Title
                      Text(
                        'Configuração necessária para o alarme funcionar',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineBold(
                          size: 24,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 12),

                      // Honest & Clear Explanation
                      Text(
                        'Em alguns celulares (principalmente Xiaomi, Samsung e similares), o sistema bloqueia o alarme de aparecer na tela de bloqueio por segurança. Precisamos que você ative 2 ou 3 permissões especiais para o alarme funcionar corretamente mesmo com a tela desligada.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          height: 1.48,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),

              // Manufacturer-specific quick instruction banner (especially useful on Xiaomi / HyperOS)
              if (_status.isXiaomi)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.neonOrange.withAlpha(35),
                            AppColors.plasmaViolet.withAlpha(25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.neonOrange.withAlpha(110),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.tips_and_updates_rounded,
                            color: AppColors.solarYellow,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Dica Xiaomi / HyperOS: Ao abrir as configurações abaixo, ative as opções com ícone de cadeado e janela em segundo plano (mude de Negar para Sempre permitir).',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Visual Checklist of Important Permissions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: AppColors.neonCyan,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            // 1. Show on Lock Screen (Exibir na tela de bloqueio)
                            _PermissionItemCard(
                              icon: Icons.lock_open_rounded,
                              title: 'Exibir na tela de bloqueio',
                              subtitle: _status.isXiaomi
                                  ? 'Show on Lock screen (Permissão especial MIUI/HyperOS)'
                                  : 'Permite que o alarme apareça sobre a tela bloqueada',
                              isGranted: _status.isXiaomi
                                  ? _status.xiaomiShowOnLockScreen
                                  : _status.canUseFullScreenIntent,
                              accentColor: AppColors.neonCyan,
                              onTap: () {
                                AppHaptics.lightTap();
                                if (_status.isXiaomi ||
                                    _status.isOemWithSpecialLocks) {
                                  ScreenControlService.instance
                                      .openManufacturerPermissionSettings();
                                } else {
                                  ScreenControlService.instance
                                      .openFullScreenIntentSettings();
                                }
                              },
                            ),

                            const SizedBox(height: 10),

                            // 2. Background Start Activity (Abrir janelas em segundo plano)
                            _PermissionItemCard(
                              icon: Icons.open_in_new_rounded,
                              title: 'Abrir janelas em segundo plano',
                              subtitle: _status.isXiaomi
                                  ? 'Open new windows while running in the background'
                                  : 'Abre a tela de disparo imediatamente quando o tempo acaba',
                              isGranted: _status.isXiaomi
                                  ? _status.xiaomiBackgroundStartActivity
                                  : _status.canDrawOverlays,
                              accentColor: AppColors.neonPink,
                              onTap: () {
                                AppHaptics.lightTap();
                                if (_status.isXiaomi ||
                                    _status.isOemWithSpecialLocks) {
                                  ScreenControlService.instance
                                      .openManufacturerPermissionSettings();
                                } else {
                                  ScreenControlService.instance
                                      .openOverlaySettings();
                                }
                              },
                            ),

                            const SizedBox(height: 10),

                            // 3. Display pop-up windows / Draw over other apps (SYSTEM_ALERT_WINDOW)
                            _PermissionItemCard(
                              icon: Icons.layers_rounded,
                              title: 'Exibir janelas pop-up / sobre outros apps',
                              subtitle:
                                  'Display pop-up windows (Sobreposição de tela)',
                              isGranted: _status.canDrawOverlays,
                              accentColor: AppColors.electricBlue,
                              onTap: () {
                                AppHaptics.lightTap();
                                ScreenControlService.instance
                                    .openOverlaySettings();
                              },
                            ),

                            const SizedBox(height: 10),

                            // 4. Full-Screen Notifications (USE_FULL_SCREEN_INTENT)
                            _PermissionItemCard(
                              icon: Icons.fullscreen_rounded,
                              title: 'Notificações em tela cheia',
                              subtitle:
                                  'Full screen intent para acender e mostrar o alarme',
                              isGranted: _status.canUseFullScreenIntent,
                              accentColor: AppColors.solarYellow,
                              onTap: () {
                                AppHaptics.lightTap();
                                ScreenControlService.instance
                                    .openFullScreenIntentSettings();
                              },
                            ),

                            const SizedBox(height: 10),

                            // 5. Ignore Battery Optimization
                            _PermissionItemCard(
                              icon: Icons.battery_charging_full_rounded,
                              title: 'Ignorar otimização de bateria',
                              subtitle:
                                  'Impede que o sistema encerre o despertador à noite',
                              isGranted: _status.isBatteryOptimizationIgnored,
                              accentColor: AppColors.acidGreen,
                              onTap: () {
                                AppHaptics.lightTap();
                                ScreenControlService.instance
                                    .requestIgnoreBatteryOptimizations();
                              },
                            ),
                          ],
                        ),
                ),
              ),

              // Action Buttons & Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                  child: Column(
                    children: [
                      // Primary prominent button
                      NeonButton(
                        text: 'Abrir configurações e ativar',
                        icon: Icons.settings_suggest_rounded,
                        variant: NeonButtonVariant.primary,
                        isFullWidth: true,
                        onPressed: _handleOpenSmartSettings,
                      ),

                      if (_status.isXiaomi) ...[
                        const SizedBox(height: 10),
                        // Direct shortcut to Xiaomi "Outras permissões"
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppHaptics.lightTap();
                              ScreenControlService.instance
                                  .openManufacturerPermissionSettings();
                            },
                            icon: const Icon(
                              Icons.security_update_good_rounded,
                              size: 18,
                              color: AppColors.neonCyan,
                            ),
                            label: Text(
                              'Abrir "Outras permissões" (Xiaomi/HyperOS)',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.neonCyan
                                    : const Color(0xFF00796B),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: AppColors.neonCyan.withAlpha(110),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Secondary button: "Já ativei tudo" / "Continuar"
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _handleCompleteOrContinue,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                allReady
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                                color: allReady
                                    ? AppColors.acidGreen
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                allReady ? 'Já ativei tudo • Continuar' : 'Já ativei tudo',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: allReady
                                      ? AppColors.acidGreen
                                      : (isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Small reassurance text below
                      Text(
                        'Isso só precisa ser feito uma vez.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final Color accentColor;
  final VoidCallback onTap;

  const _PermissionItemCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isGranted ? AppColors.acidGreen : AppColors.solarYellow;

    return GlassCard(
      borderRadius: 20,
      blur: 14,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      borderGradient: LinearGradient(
        colors: isGranted
            ? [
                AppColors.acidGreen.withAlpha(140),
                AppColors.neonCyan.withAlpha(90),
              ]
            : [
                accentColor.withAlpha(130),
                AppColors.plasmaViolet.withAlpha(70),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.acidGreen : accentColor)
                  .withAlpha(28),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (isGranted ? AppColors.acidGreen : accentColor)
                    .withAlpha(90),
              ),
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: isGranted ? AppColors.acidGreen : accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    height: 1.3,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status Pill
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withAlpha(110),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isGranted ? 'ATIVADO' : 'ATIVAR',
                  style: AppTypography.badge(
                    color: statusColor,
                    size: 10,
                  ),
                ),
                if (!isGranted) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: statusColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
