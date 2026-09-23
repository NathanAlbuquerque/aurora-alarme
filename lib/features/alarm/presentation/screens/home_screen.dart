import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/permission_utils.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/pulsing_fab.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../widgets/alarm_card.dart';
import '../widgets/aurora_clock_widget.dart';
import '../widgets/empty_alarms_illustration.dart';
import 'add_edit_alarm_screen.dart';

/// Primary Flagship Screen for Aurora Alarm
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.requestAlarmPermissions();
    });
  }

  void _handleAddNewAlarm() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const AddEditAlarmScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleEditAlarm(AlarmModel alarm) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) =>
            AddEditAlarmScreen(initialAlarm: alarm),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _handleToggleDay(AlarmModel alarm, int day) {
    HapticFeedback.selectionClick();
    final days = List<int>.from(alarm.repeatDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
      days.sort();
    }
    ref.read(alarmListProvider.notifier).updateAlarm(alarm.copyWith(repeatDays: days));
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmListProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Next upcoming active alarm countdown
    String? nextAlarmText;
    final activeAlarms = alarms.where((a) => a.isEnabled).toList();
    if (activeAlarms.isNotEmpty) {
      final firstActive = activeAlarms.first;
      nextAlarmText = DateTimeUtils.getNextAlarmCountdown(
        firstActive.timeOfDay,
        firstActive.repeatDays,
      );
    }

    return Scaffold(
      body: AnimatedGradientBackground(
        showParticles: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // =================================================================
            // 🌟 Animated Header with Glowing Logo & Theme Switcher
            // =================================================================
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  // Glowing Pulsing Orb
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDark
                          ? AppColors.auroraBorealis
                          : AppColors.cyberSunset,
                      boxShadow: AppColors.neonGlow(
                        isDark ? AppColors.neonCyan : const Color(0xFFE0006C),
                        blur: 14,
                        spread: 1,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(0.85, 0.85),
                        end: const Offset(1.2, 1.2),
                        duration: 1200.ms,
                      ),

                  // Animated Title with Gradient Shimmer
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return (isDark
                              ? AppColors.auroraBorealis
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF00796B),
                                    Color(0xFFE0006C),
                                  ],
                                ))
                          .createShader(bounds);
                    },
                    child: Text(
                      'AURORA ALARM',
                      style: AppTypography.headlineBold(
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideX(begin: -0.15, end: 0, curve: Curves.easeOutCubic)
                      .shimmer(
                        delay: 1500.ms,
                        duration: 2000.ms,
                        color: Colors.white.withAlpha(120),
                      ),
                ],
              ),
              actions: [
                // Theme Toggle with Rotation & Scale Micro-Interaction
                Container(
                  margin: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface)
                        .withAlpha(isDark ? 180 : 220),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.neonCyan : const Color(0xFF7928CA))
                            .withAlpha(isDark ? 40 : 25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: IconButton(
                    tooltip: 'Alternar Tema',
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          RotationTransition(turns: anim, child: child),
                      child: Icon(
                        themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        key: ValueKey(themeMode),
                        color: isDark
                            ? AppColors.neonYellow
                            : const Color(0xFF7928CA),
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
              ],
            ),

            // =================================================================
            // ⏰ Live Pulsating Clock Header
            // =================================================================
            SliverToBoxAdapter(
              child: AuroraClockWidget(
                nextAlarmCountdown: nextAlarmText,
              ),
            ),

            // =================================================================
            // 📋 Section Title: "Seus Alarmes" with Status Pill
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Seus Alarmes',
                          style: AppTypography.headlineBold(
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.neonCyan,
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .fade(begin: 0.3, end: 1.0, duration: 800.ms),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                                .withAlpha(isDark ? 35 : 25),
                            (isDark ? AppColors.neonPink : const Color(0xFFE0006C))
                                .withAlpha(isDark ? 25 : 15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                              .withAlpha(isDark ? 100 : 70),
                        ),
                      ),
                      child: Text(
                        '${activeAlarms.length} ativos',
                        style: AppTypography.badge(
                          color: isDark
                              ? AppColors.neonCyan
                              : const Color(0xFF00796B),
                          size: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // 📭 Empty State with Animated Illustration OR Super Animated Cards
            // =================================================================
            if (alarms.isEmpty)
              SliverToBoxAdapter(
                child: EmptyAlarmsIllustration(
                  onAddAlarm: _handleAddNewAlarm,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alarm = alarms[index];
                    return AlarmCard(
                      key: ValueKey(alarm.id),
                      alarm: alarm,
                      index: index,
                      onTap: () => _handleEditAlarm(alarm),
                      onToggle: (_) {
                        ref
                            .read(alarmListProvider.notifier)
                            .toggleAlarm(alarm.id);
                      },
                      onDelete: () {
                        ref
                            .read(alarmListProvider.notifier)
                            .deleteAlarm(alarm.id);
                      },
                      onToggleDay: (day) => _handleToggleDay(alarm, day),
                    );
                  },
                  childCount: alarms.length,
                ),
              ),

            // Bottom Spacing for Pulsing FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
      floatingActionButton: PulsingFab(
        onPressed: _handleAddNewAlarm,
        label: 'NOVO ALARME',
        icon: Icons.add_alarm_rounded,
      ),
    );
  }
}
