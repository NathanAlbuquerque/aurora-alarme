import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_alarme/features/alarm/presentation/widgets/empty_alarms_illustration.dart';
import 'package:aurora_alarme/features/alarm/presentation/widgets/parallax_alarm_scroll_wrapper.dart';
import 'package:aurora_alarme/features/alarm/presentation/widgets/rive_empty_cosmos_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Advanced Animations & Widgets Tests', () {
    testWidgets('RiveEmptyCosmosAnimation renders properly and responds to tap',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RiveEmptyCosmosAnimation(
                size: 180,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byType(RiveEmptyCosmosAnimation), findsOneWidget);
      expect(find.byIcon(Icons.nights_stay_rounded), findsOneWidget);

      // Tap on the cosmos animation
      await tester.tap(find.byType(RiveEmptyCosmosAnimation));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
    });

    testWidgets(
        'EmptyAlarmsIllustration embeds RiveEmptyCosmosAnimation and triggers onAddAlarm',
        (tester) async {
      bool addPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyAlarmsIllustration(
              onAddAlarm: () {
                addPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.byType(EmptyAlarmsIllustration), findsOneWidget);
      expect(find.byType(RiveEmptyCosmosAnimation), findsOneWidget);
      expect(find.text('O Silêncio da Noite'), findsOneWidget);
      expect(find.text('Criar Meu Alarme'), findsOneWidget);

      // Tap the action button
      await tester.tap(find.text('Criar Meu Alarme'));
      await tester.pump(const Duration(seconds: 1));

      expect(addPressed, isTrue);
    });

    testWidgets('ParallaxAlarmScrollWrapper renders child in scrollable view',
        (tester) async {
      double? receivedParallax;
      double? receivedGlow;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ParallaxAlarmScrollWrapper(
                builder: (context, parallaxOffset, glowIntensity) {
                  receivedParallax = parallaxOffset;
                  receivedGlow = glowIntensity;
                  return const SizedBox(
                    height: 120,
                    key: Key('parallax_child'),
                    child: Text('Parallax Child'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('parallax_child')), findsOneWidget);
      expect(receivedParallax, isNotNull);
      expect(receivedGlow, isNotNull);
    });
  });
}
