import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/alarm/models/alarm_model.dart';
import 'features/alarm/presentation/screens/alarm_ringing_screen.dart';
import 'features/alarm/presentation/screens/home_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services
  await NotificationService.instance.initialize();
  await AlarmService.instance.initialize();

  runApp(
    const ProviderScope(
      child: AuroraAlarmApp(),
    ),
  );
}

class AuroraAlarmApp extends ConsumerStatefulWidget {
  const AuroraAlarmApp({super.key});

  @override
  ConsumerState<AuroraAlarmApp> createState() => _AuroraAlarmAppState();
}

class _AuroraAlarmAppState extends ConsumerState<AuroraAlarmApp> {
  @override
  void initState() {
    super.initState();

    // Listen for alarm notification clicks or background triggers
    NotificationService.instance.onNotificationPayload.stream.listen((payload) {
      if (payload != null) {
        _navigateToRingingScreen(payload);
      }
    });

    // Check if app was launched directly by tapping a notification
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialPayload =
          await NotificationService.instance.getInitialPayload();
      if (initialPayload != null) {
        _navigateToRingingScreen(initialPayload);
      }
    });
  }

  Future<void> _navigateToRingingScreen(String payload) async {
    final alarmId = int.tryParse(payload);
    AlarmModel? targetAlarm;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString(AppConstants.keyAlarms);
      if (alarmsJson != null) {
        final List<dynamic> list = jsonDecode(alarmsJson);
        final alarms = list.map((e) => AlarmModel.fromJson(e)).toList();
        targetAlarm = alarms.firstWhere(
          (a) => a.id == alarmId,
          orElse: () => AlarmModel(
            id: alarmId ?? 1,
            hour: DateTime.now().hour,
            minute: DateTime.now().minute,
          ),
        );
      }
    } catch (_) {}

    targetAlarm ??= AlarmModel(
      id: alarmId ?? 1,
      hour: DateTime.now().hour,
      minute: DateTime.now().minute,
    );

    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlarmRingingScreen(alarm: targetAlarm!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      home: const HomeScreen(),
    );
  }
}
