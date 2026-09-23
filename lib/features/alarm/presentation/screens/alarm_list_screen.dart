import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/permission_utils.dart';
import '../../../../shared/widgets/aurora_background.dart';
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
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.neonCyan,
                    onPrimary: Color(0xFF032B25),
                    surface: AppColors.darkSurface,
                    onSurface: AppColors.darkTextPrimary,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF00897B),
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                    onSurface: AppColors.lightTextPrimary,
                  ),
          ),
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
          backgroundColor: AppColors.darkSurfaceElevated,
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
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.neonCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text('Aurora Alarm'),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Alternar Tema',
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                ),
                const SizedBox(width: 8),
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
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seus Alarmes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${alarms.length} ${alarms.length == 1 ? 'alarme' : 'alarmes'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
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
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alarm_off_outlined,
                        size: 64,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum alarme configurado',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
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
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleAddNewAlarm,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text(
          'Novo Alarme',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
