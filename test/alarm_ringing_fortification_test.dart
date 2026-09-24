import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aurora_alarme/core/state/alarm_ringing_manager.dart';
import 'package:aurora_alarme/features/splash/presentation/screens/splash_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Animate.restartOnHotReload = false;
    AlarmRingingManager.instance.isRinging = false;
    AlarmRingingManager.instance.activeAlarmId = null;
    AlarmRingingManager.instance.onDismiss = null;
  });

  tearDown(() {
    AlarmRingingManager.instance.isRinging = false;
    AlarmRingingManager.instance.activeAlarmId = null;
    AlarmRingingManager.instance.onDismiss = null;
  });

  testWidgets('SplashScreen respects AlarmRingingManager and does not navigate when alarm is ringing',
      (WidgetTester tester) async {
    // Set alarm ringing flag to true before splash timer fires
    AlarmRingingManager.instance.isRinging = true;

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('AURORA ALARME'), findsOneWidget);

    // Pump past the 2200ms timer
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 500));

    // Because isRinging was true, SplashScreen did NOT pushReplacement to HomeScreen!
    // So SplashScreen should still be mounted and HomeScreen is NOT found
    expect(find.text('AURORA ALARME'), findsOneWidget);
    expect(find.text('Seus Alarmes'), findsNothing);

    // Clean up
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('AlarmRingingManager singleton stores state and notifies callbacks', () {
    expect(AlarmRingingManager.instance.isRinging, isFalse);
    expect(AlarmRingingManager.instance.activeAlarmId, isNull);

    AlarmRingingManager.instance.isRinging = true;
    AlarmRingingManager.instance.activeAlarmId = 42;

    expect(AlarmRingingManager.instance.isRinging, isTrue);
    expect(AlarmRingingManager.instance.activeAlarmId, 42);

    bool callbackFired = false;
    AlarmRingingManager.instance.onDismiss = () {
      callbackFired = true;
    };

    AlarmRingingManager.instance.onDismiss?.call();
    expect(callbackFired, isTrue);
  });
}
