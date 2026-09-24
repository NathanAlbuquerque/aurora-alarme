import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/utils/date_time_utils.dart';
import '../../../../shared/utils/haptic_utils.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/confetti_celebration.dart';
import '../../../../shared/widgets/exaggerated_neon_switch.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../models/alarm_model.dart';
import '../../providers/alarm_provider.dart';
import '../widgets/alarm_preview_dialog.dart';
import '../widgets/exploding_day_selector.dart';
import '../widgets/interactive_time_selector.dart';

/// Screen to create or edit an alarm with tactile micro-interactions,
/// exploding day selectors, sound/mission options, and celebratory save effects.
class AddEditAlarmScreen extends ConsumerStatefulWidget {
  final AlarmModel? initialAlarm;

  const AddEditAlarmScreen({
    super.key,
    this.initialAlarm,
  });

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  late TimeOfDay _time;
  late List<int> _days;
  late TextEditingController _labelController;
  late bool _vibrate;
  late String _sound;
  late int _snoozeMinutes;
  late String _mission;
  bool _isSaving = false;

  final List<String> _soundOptions = [
    'Aurora Celestial',
    'Neon Pulse',
    'Synthwave Sunrise',
    'Cosmic Bell',
    'Energia Solar',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAlarm;
    _time = initial != null
        ? initial.timeOfDay
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 15)));
    _days = initial != null ? List<int>.from(initial.repeatDays) : [1, 2, 3, 4, 5];
    _labelController = TextEditingController(
      text: initial?.label ?? 'Despertar Aurora',
    );
    _vibrate = initial?.vibrate ?? true;
    _sound = initial?.sound ?? _soundOptions.first;
    _snoozeMinutes = initial?.snoozeMinutes ?? 5;
    _mission = initial?.mission ?? 'none';
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _handleSave(ConfettiCelebrationState? confetti) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    AppHaptics.successPattern();

    // Trigger celebratory confetti explosion
    confetti?.blast(origin: const Offset(0.5, 0.8));

    final isEditing = widget.initialAlarm != null;
    final alarmToSave = AlarmModel(
      id: widget.initialAlarm?.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      hour: _time.hour,
      minute: _time.minute,
      label: _labelController.text.trim().isEmpty
          ? 'Alarme Aurora'
          : _labelController.text.trim(),
      isEnabled: true,
      repeatDays: _days,
      vibrate: _vibrate,
      sound: _sound,
      snoozeMinutes: _snoozeMinutes,
      mission: _mission,
    );

    if (isEditing) {
      await ref.read(alarmListProvider.notifier).updateAlarm(alarmToSave);
    } else {
      await ref.read(alarmListProvider.notifier).addAlarm(alarmToSave);
    }

    // Delay slightly so the user experiences the explosion & checkmark
    await Future.delayed(const Duration(milliseconds: 750));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _handlePreview() {
    AlarmPreviewDialog.show(
      context,
      time: DateTimeUtils.formatTimeOfDay(_time),
      label: _labelController.text.trim().isEmpty
          ? 'Alarme Aurora'
          : _labelController.text.trim(),
      sound: _sound,
      mission: _mission,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialAlarm != null;

    return ConfettiCelebration(
      child: Builder(
        builder: (innerContext) {
          final confetti = ConfettiCelebration.of(innerContext);

          return Scaffold(
            body: AnimatedGradientBackground(
              showParticles: true,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar with Save & Close Actions
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Container(
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightSurfaceElevated)
                            .withAlpha(isDark ? 160 : 220),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    title: Text(
                      isEditing ? 'EDITAR ALARME' : 'NOVO ALARME',
                      style: AppTypography.headlineBold(
                        size: 20,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    actions: [
                      // Preview Button in AppBar
                      IconButton(
                        tooltip: 'Testar Alarme',
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.neonCyan,
                          size: 28,
                        ),
                        onPressed: _handlePreview,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // ===========================================================
                  // 1. Interactive Modern Time Selector
                  // ===========================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: InteractiveTimeSelector(
                        hour: _time.hour,
                        minute: _time.minute,
                        onChanged: (newTime) {
                          setState(() => _time = newTime);
                        },
                      ),
                    ),
                  ),

                  // ===========================================================
                  // 2. Exploding Days of the Week Selector
                  // ===========================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: GlassCard(
                        borderRadius: 28,
                        blur: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Repetição Semanal',
                                  style: AppTypography.headlineBold(
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 18,
                                  color: AppColors.neonCyan,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ExplodingDaySelector(
                              selectedDays: _days,
                              onChanged: (days) {
                                setState(() => _days = days);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===========================================================
                  // 3. Label & Details Card
                  // ===========================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GlassCard(
                        borderRadius: 28,
                        blur: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label Textfield
                            Text(
                              'Nome do Alarme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _labelController,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ex: Treino, Trabalho, Foco...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                filled: true,
                                fillColor: (isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceElevated)
                                    .withAlpha(isDark ? 150 : 200),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.neonCyan
                                        : const Color(0xFF009688),
                                    width: 1.5,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.label_rounded,
                                  color: isDark
                                      ? AppColors.neonCyan
                                      : const Color(0xFF009688),
                                  size: 20,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Sound Selector
                            Text(
                              'Som do Alarme',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? AppColors.darkSurfaceElevated
                                        : AppColors.lightSurfaceElevated)
                                    .withAlpha(isDark ? 150 : 200),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sound,
                                  isExpanded: true,
                                  icon: const Icon(Icons.music_note_rounded),
                                  dropdownColor: isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  items: _soundOptions.map((sound) {
                                    return DropdownMenuItem<String>(
                                      value: sound,
                                      child: Text(
                                        sound,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      AppHaptics.selectionTick();
                                      setState(() => _sound = val);
                                    }
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Vibration Switch
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.vibration_rounded,
                                      size: 20,
                                      color: isDark
                                          ? AppColors.neonCyan
                                          : const Color(0xFF009688),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Vibração Tátil',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                ExaggeratedNeonSwitch(
                                  value: _vibrate,
                                  onChanged: (val) {
                                    setState(() => _vibrate = val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===========================================================
                  // 4. Wake-Up Challenge (Mission)
                  // ===========================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: GlassCard(
                        borderRadius: 28,
                        blur: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Desafio para Desligar',
                                  style: AppTypography.headlineBold(
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neonYellow.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'OPCIONAL',
                                    style: AppTypography.badge(
                                      color: AppColors.neonYellow,
                                      size: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Mission Selection Cards
                            Row(
                              children: [
                                _MissionCard(
                                  label: 'Nenhum',
                                  icon: Icons.notifications_active_rounded,
                                  isSelected: _mission == 'none',
                                  onTap: () => setState(() => _mission = 'none'),
                                ),
                                const SizedBox(width: 8),
                                _MissionCard(
                                  label: 'Matemática',
                                  icon: Icons.calculate_rounded,
                                  isSelected: _mission == 'math',
                                  onTap: () => setState(() => _mission = 'math'),
                                ),
                                const SizedBox(width: 8),
                                _MissionCard(
                                  label: 'Chacoalhar',
                                  icon: Icons.edgesensor_high_rounded,
                                  isSelected: _mission == 'shake',
                                  onTap: () => setState(() => _mission = 'shake'),
                                ),
                                const SizedBox(width: 8),
                                _MissionCard(
                                  label: 'Memória',
                                  icon: Icons.grid_view_rounded,
                                  isSelected: _mission == 'memory',
                                  onTap: () => setState(() => _mission = 'memory'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ===========================================================
                  // 5. Action Buttons: Preview & Save
                  // ===========================================================
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                      child: Column(
                        children: [
                          // Test Preview Button
                          NeonButton(
                            text: 'Testar Experiência de Disparo',
                            icon: Icons.play_arrow_rounded,
                            variant: NeonButtonVariant.outlined,
                            isFullWidth: true,
                            onPressed: _handlePreview,
                          ),
                          const SizedBox(height: 12),
                          // Save Button with Celebratory Morph
                          _isSaving
                              ? Container(
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.auroraBorealis,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: AppColors.neonGlow(
                                      AppColors.neonCyan,
                                      blur: 28,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF03221C),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'ALARME SALVO COM SUCESSO!',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF03221C),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                  .animate()
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.0, 1.0),
                                    curve: Curves.elasticOut,
                                  )
                              : NeonButton(
                                  text: isEditing ? 'SALVAR ALTERAÇÕES' : 'DEFINIR NOVO ALARME',
                                  icon: Icons.check_rounded,
                                  variant: NeonButtonVariant.primary,
                                  isFullWidth: true,
                                  onPressed: () => _handleSave(confetti),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MissionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: ScaleBounceFeedback(
        onTap: () {
          AppHaptics.lightTap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.neonCyan.withAlpha(40)
                    : const Color(0xFF009688).withAlpha(25))
                : (isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurfaceElevated),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected && isDark
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withAlpha(40),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? (isDark ? AppColors.neonCyan : const Color(0xFF009688))
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.neonCyan : const Color(0xFF00796B))
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
