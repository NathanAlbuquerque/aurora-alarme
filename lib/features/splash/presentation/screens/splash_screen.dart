import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/aurora_page_route.dart';
import '../../../../core/state/alarm_ringing_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../alarm/presentation/screens/home_screen.dart';

/// Cinematic animated splash screen for Aurora Alarm.
/// Awakens the app with an aurora core condensation, rotating chromatic halo,
/// and smooth handoff into the main interface.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _navigationTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      // CRITICAL: If an alarm is ringing, DO NOT navigate or replace the route!
      if (AlarmRingingManager.instance.isRinging) return;

      Navigator.of(context).pushReplacement(
        AuroraPageRoute(
          page: const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkVoid,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Void Base
          Container(color: AppColors.darkVoid),

          // 2. Rotating Aurora Chromatic Halo
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: SweepGradient(
                      colors: [
                        AppColors.neonCyan.withAlpha(60),
                        AppColors.plasmaViolet.withAlpha(80),
                        AppColors.neonPink.withAlpha(70),
                        AppColors.neonYellow.withAlpha(50),
                        AppColors.neonCyan.withAlpha(60),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Central Darkening Radial Gradient for contrast
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.darkVoid.withAlpha(140),
                  AppColors.darkVoid.withAlpha(230),
                  AppColors.darkVoid,
                ],
                stops: const [0.2, 0.65, 1.0],
              ),
            ),
          ),

          // 4. Center Logo & Typography Core
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon Core with Ripple Rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ripple
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.neonCyan.withAlpha(80),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.85, 0.85),
                          end: const Offset(1.15, 1.15),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),

                    // Inner Emblem Card
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.auroraBorealis,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: AppColors.multiGlow(
                          primary: AppColors.neonCyan,
                          secondary: AppColors.neonPink,
                          blur: 36,
                        ),
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        size: 54,
                        color: Color(0xFF03221C),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1.0, 1.0),
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                        )
                        .shimmer(
                          delay: 800.ms,
                          duration: 1000.ms,
                          color: Colors.white,
                        ),
                  ],
                ),

                const SizedBox(height: 32),

                // Stylized Title with Chromatic ShaderMask
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.neonCyan,
                      AppColors.pastelPink,
                      AppColors.neonYellow,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'AURORA ALARME',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 12),

                // Glowing Subtitle Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.neonPink.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.neonPink.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.neonPink,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.8, 1.8),
                            duration: 500.ms,
                          ),
                      const SizedBox(width: 8),
                      Text(
                        'ACORDE COM ENERGIA',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideY(begin: 0.4, end: 0),
              ],
            ),
          ),

          // 5. Version label at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v${AppConstants.appVersion} • DESIGN SYSTEM 2026',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: AppColors.darkTextMuted,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 900.ms),
        ],
      ),
    );
  }
}
