import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AuroraBackground extends StatelessWidget {
  final Widget child;

  const AuroraBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Background Color
        Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        ),

        // Glowing Aurora Blobs
        if (isDark) ...[
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.neonCyan.withAlpha(45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.luminousPurple.withAlpha(50),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cosmicMagenta.withAlpha(35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ] else ...[
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2DD4BF).withAlpha(30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFF472B6).withAlpha(25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],

        // Foreground Content
        SafeArea(child: child),
      ],
    );
  }
}
