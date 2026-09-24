import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_alarme/features/alarm/presentation/widgets/interactive_time_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InteractiveTimeSelector Widget Tests', () {
    testWidgets(
        'renders correctly with initial hour and minute and shows keyboard entry button',
        (tester) async {
      TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 30);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveTimeSelector(
                hour: selectedTime.hour,
                minute: selectedTime.minute,
                onChanged: (newTime) {
                  selectedTime = newTime;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify hour and minute text boxes
      expect(find.text('07'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('HORA'), findsOneWidget);
      expect(find.text('MINUTO'), findsOneWidget);

      // Verify numeric keyboard button is present and visible
      expect(find.text('DIGITAR'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_alt_rounded), findsOneWidget);

      // Verify steppers exist
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsWidgets);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsWidgets);
    });

    testWidgets('vertical drag on hours increments and decrements by 1',
        (tester) async {
      TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 30);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: InteractiveTimeSelector(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    onChanged: (newTime) {
                      setState(() {
                        selectedTime = newTime;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final hourBox = find.text('07');
      expect(hourBox, findsOneWidget);

      // Drag UP on hour box -> should increment hour from 7 to 8
      await tester.drag(hourBox, const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.hour, equals(8));
      expect(find.text('08'), findsOneWidget);

      // Drag DOWN on hour box -> should decrement hour from 8 back to 7
      final updatedHourBox = find.text('08');
      await tester.drag(updatedHourBox, const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.hour, equals(7));
      expect(find.text('07'), findsOneWidget);
    });

    testWidgets('vertical drag on minutes jumps by 10s (00, 10, 20, 30, 40, 50)',
        (tester) async {
      TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 30);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: InteractiveTimeSelector(
                    hour: selectedTime.hour,
                    minute: selectedTime.minute,
                    onChanged: (newTime) {
                      setState(() {
                        selectedTime = newTime;
                      });
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final minuteBox = find.text('30');
      expect(minuteBox, findsOneWidget);

      // Drag UP on minute box -> jumps from 30 to 40
      await tester.drag(minuteBox, const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.minute, equals(40));
      expect(find.text('40'), findsOneWidget);

      // Drag UP again -> jumps from 40 to 50
      await tester.drag(find.text('40'), const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.minute, equals(50));
      expect(find.text('50'), findsOneWidget);

      // Drag UP again -> wraps around to 00
      await tester.drag(find.text('50'), const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.minute, equals(0));
      expect(find.text('00'), findsOneWidget);

      // Drag DOWN on 00 -> wraps backward to 50
      await tester.drag(find.text('00'), const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedTime.minute, equals(50));
      expect(find.text('50'), findsOneWidget);
    });

    testWidgets('tapping numeric keyboard button opens time picker input dialog',
        (tester) async {
      TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 15);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveTimeSelector(
                hour: selectedTime.hour,
                minute: selectedTime.minute,
                onChanged: (newTime) {
                  selectedTime = newTime;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the keyboard button 'DIGITAR'
      final keyboardBtn = find.text('DIGITAR');
      expect(keyboardBtn, findsOneWidget);

      await tester.tap(keyboardBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // TimePicker dialog should now be displayed
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.text('Digitar horário'), findsOneWidget);
      expect(find.text('CONFIRMAR'), findsOneWidget);
      expect(find.text('CANCELAR'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('CANCELAR'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TimePickerDialog), findsNothing);
    });
  });
}
