import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aurora_alarm/main.dart';

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

    // Pump a duration to allow flutter_animate scheduled timers to run
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Aurora Alarm title and alarms section header are present
    expect(find.text('Aurora Alarm'), findsOneWidget);
    expect(find.text('Seus Alarmes'), findsOneWidget);

    // Disposing the widget tree cancels timers in AuroraClockWidget
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
