import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aurora_alarme/main.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Animate.restartOnHotReload = false;
  });

  testWidgets('AuroraAlarmApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AuroraAlarmApp(),
      ),
    );

    // Pump a duration to verify SplashScreen is rendered
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('AURORA ALARME'), findsOneWidget);
    expect(find.text('ACORDE COM ENERGIA'), findsOneWidget);

    // Pump past splash duration to reach HomeScreen
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 700));

    // Verify HomeScreen elements
    expect(find.text('Seus Alarmes'), findsOneWidget);
    expect(find.text('NOVO ALARME'), findsOneWidget);

    // Disposing the widget tree cancels timers in background and clock
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
