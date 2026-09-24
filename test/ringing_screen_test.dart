import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aurora_alarm/features/alarm/presentation/widgets/hold_to_dismiss_button.dart';
import 'package:aurora_alarm/features/alarm/presentation/widgets/ringing_challenge_widget.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    Animate.restartOnHotReload = false;
  });

  testWidgets('HoldToDismissButton renders correctly and triggers on dismiss',
      (WidgetTester tester) async {
    bool dismissed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HoldToDismissButton(
            onDismiss: () {
              dismissed = true;
            },
            holdDuration: const Duration(milliseconds: 300),
          ),
        ),
      ),
    );

    expect(find.text('SEGURE PARA DESLIGAR'), findsOneWidget);

    // Simulate hold
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(HoldToDismissButton)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.up();
    await tester.pump();

    expect(dismissed, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('RingingChallengeWidget handles math challenge',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RingingChallengeWidget(
            challengeType: 'math',
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
    expect(completed, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('RingingChallengeWidget handles shake challenge',
      (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RingingChallengeWidget(
            challengeType: 'shake',
            onCompleted: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('Agite ou toque'), findsOneWidget);

    // Tap repeated button
    for (int i = 0; i < 12; i++) {
      await tester.tap(find.text('Toque aqui repetidamente ⚡'));
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(completed, isTrue);

    // Let success animation finish
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
