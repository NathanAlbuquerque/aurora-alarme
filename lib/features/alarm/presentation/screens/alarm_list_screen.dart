import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/permission_utils.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../widgets/alarm_card.dart';
import '../widgets/aurora_clock_widget.dart';

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionUtils.requestAlarmPermissions();
    });
  }

  Future<void> _handleAddNewAlarm() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Theme(
          data: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final newAlarm = AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        hour: pickedTime.hour,
        minute: pickedTime.minute,
        label: 'Alarme',
        isEnabled: true,
        repeatDays: const [1, 2, 3, 4, 5],
      );

      await ref.read(alarmListProvider.notifier).addAlarm(newAlarm);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarme definido para ${DateTimeUtils.formatTimeOfDay(pickedTime)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarms = ref.watch(alarmListProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find the next upcoming active alarm for the header countdown
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
      body: AuroraBackground(
        child: CustomScrollView(
          slivers: [
            // App Bar with glowing neon orb indicator
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDark
                          ? AppColors.auroraBorealis
                          : AppColors.cyberSunset,
                      boxShadow: AppColors.neonGlow(
                        isDark ? AppColors.neonCyan : const Color(0xFFE0006C),
                        blur: 10,
                      ),
                    ),
                  ),
                  Text(
                    'Aurora Alarm',
                    style: AppTypography.headlineBold(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface)
                        .withAlpha(isDark ? 160 : 200),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Alternar Tema',
                    icon: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: isDark
                          ? AppColors.neonYellow
                          : const Color(0xFF7928CA),
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
              ],
            ),

            // Live Clock Header with Countdown
            SliverToBoxAdapter(
              child: AuroraClockWidget(
                nextAlarmCountdown: nextAlarmText,
              ),
            ),

            // Alarms Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.neonCyan
                                : const Color(0xFF009688))
                            .withAlpha(isDark ? 30 : 20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${alarms.length} ${alarms.length == 1 ? 'ativo' : 'itens'}',
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

            // Alarm Cards List
            if (alarms.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassCard(
                    borderRadius: 32,
                    blur: 20,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.alarm_off_rounded,
                            size: 64,
                            color: isDark
                                ? AppColors.neonPink.withAlpha(150)
                                : const Color(0xFFE0006C).withAlpha(120),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum alarme configurado',
                            style: AppTypography.headlineBold(
                              size: 18,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Comece adicionando seu primeiro alarme vibrante.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          NeonButton(
                            text: 'Criar Alarme',
                            icon: Icons.add_alarm_rounded,
                            onPressed: _handleAddNewAlarm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alarm = alarms[index];
                    return AlarmCard(
                      alarm: alarm,
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
                    );
                  },
                  childCount: alarms.length,
                ),
              ),

            // Bottom Spacing for Floating Action Button
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),
      floatingActionButton: NeonButton(
        text: 'Novo Alarme',
        icon: Icons.add_alarm_rounded,
        variant: NeonButtonVariant.primary,
        onPressed: _handleAddNewAlarm,
      ),
    );
  }
}
