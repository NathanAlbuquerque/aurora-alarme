import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/services/alarm_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/screen_control_service.dart';
import 'core/state/alarm_ringing_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/alarm/models/alarm_model.dart';
import 'features/alarm/presentation/screens/alarm_ringing_screen.dart';
import 'features/alarm/presentation/screens/home_screen.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

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

    // 1. Listen for notification payload taps
    NotificationService.instance.onNotificationPayload.stream.listen((payload) {
      if (payload != null && payload.isNotEmpty) {
        _navigateToRingingScreen(payload);
      }
    });

    // 2. Listen for native Android onAlarmTriggered (e.g. from onNewIntent / Full-Screen Intent)
    ScreenControlService.instance.onAlarmTriggered.listen((payload) {
      if (payload.isNotEmpty) {
        _navigateToRingingScreen(payload);
      }
    });

    // 3. Check if app was launched directly by notification or native full-screen intent
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialNotificationPayload =
          await NotificationService.instance.getInitialPayload();
      if (initialNotificationPayload != null &&
          initialNotificationPayload.isNotEmpty) {
        _navigateToRingingScreen(initialNotificationPayload);
        return;
      }

      final initialNativePayload =
          await ScreenControlService.instance.getInitialAlarmPayload();
      if (initialNativePayload != null && initialNativePayload.isNotEmpty) {
        _navigateToRingingScreen(initialNativePayload);
      }
    });
  }

  Future<void> _navigateToRingingScreen(String payload) async {
    final alarmId = int.tryParse(payload) ?? 1;

    // Prevent duplicate triggers if the exact alarm is already ringing on screen
    if (AlarmRingingManager.instance.isRinging &&
        AlarmRingingManager.instance.activeAlarmId == alarmId) {
      return;
    }

    AlarmRingingManager.instance.isRinging = true;
    AlarmRingingManager.instance.activeAlarmId = alarmId;

    // Ensure Navigator is mounted
    while (appNavigatorKey.currentState == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

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
            id: alarmId,
            hour: DateTime.now().hour,
            minute: DateTime.now().minute,
          ),
        );
      }
    } catch (_) {}

    targetAlarm ??= AlarmModel(
      id: alarmId,
      hour: DateTime.now().hour,
      minute: DateTime.now().minute,
    );

    // FORTIFIED STACK:
    // 1. pushAndRemoveUntil puts HomeScreen as the base and completely removes
    //    SplashScreen (and any pending timers) from the navigator tree.
    // 2. Pushes AlarmRingingScreen as top route.
    // 3. When AlarmRingingScreen is popped by user, they smoothly arrive at HomeScreen.
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );

    await appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AlarmRingingScreen(alarm: targetAlarm!),
      ),
    );

    AlarmRingingManager.instance.isRinging = false;
    AlarmRingingManager.instance.activeAlarmId = null;
    await ScreenControlService.instance.clearAlarmPayload();
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
      home: const SplashScreen(),
    );
  }
}
