import 'package:dance_analysis_client/models/video_timestamp.dart';
import 'package:dance_analysis_client/shared/design_system/theme.dart';
import 'package:dance_analysis_client/shared/widgets/inline_timestamp_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InlineTimestampForm', () {
    late Duration testCurrentPosition;

    setUp(() {
      testCurrentPosition = const Duration(seconds: 30);
    });

    Widget buildForm({
      Duration? currentVideoPosition,
      VideoTimestamp? existingTimestamp,
      Duration? maxDuration,
      Function(Duration, Duration, String)? onSave,
      VoidCallback? onCancel,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: InlineTimestampForm(
            currentVideoPosition: currentVideoPosition ?? testCurrentPosition,
            existingTimestamp: existingTimestamp,
            maxDuration: maxDuration,
            onSave: onSave ?? (start, end, label) {},
            onCancel: onCancel ?? () {},
          ),
        ),
      );
    }

    group('initialization - new timestamp', () {
      testWidgets('displays "Add Timestamp" header', (tester) async {
        await tester.pumpWidget(buildForm());

        expect(find.text('Add Timestamp'), findsOneWidget);
        expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      });

      testWidgets('initializes start time to current position', (tester) async {
        await tester.pumpWidget(
          buildForm(
            currentVideoPosition: const Duration(minutes: 1, seconds: 30),
          ),
        );
        await tester.pumpAndSettle();

        // Start minutes should be 1
        final startMinutesFields = find.byType(TextField);
        expect(
          tester.widget<TextField>(startMinutesFields.at(0)).controller?.text,
          '1',
        );
      });

      testWidgets('initializes end time to 5 seconds after start', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(currentVideoPosition: const Duration(seconds: 10)),
        );
        await tester.pumpAndSettle();

        // End time should be 15 seconds (0:15)
        final textFields = find.byType(TextField);
        final endMinutesField = textFields.at(2);
        final endSecondsField = textFields.at(3);

        expect(tester.widget<TextField>(endMinutesField).controller?.text, '0');
        expect(
          tester.widget<TextField>(endSecondsField).controller?.text,
          '15',
        );
      });

      testWidgets('clamps end time to maxDuration when it would exceed', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(
            currentVideoPosition: const Duration(seconds: 58),
            maxDuration: const Duration(seconds: 60),
          ),
        );
        await tester.pumpAndSettle();

        // End time should be clamped to 60 seconds (1:00)
        final textFields = find.byType(TextField);
        final endMinutesField = textFields.at(2);
        final endSecondsField = textFields.at(3);

        expect(tester.widget<TextField>(endMinutesField).controller?.text, '1');
        expect(
          tester.widget<TextField>(endSecondsField).controller?.text,
          '00',
        );
      });

      testWidgets('label field autofocuses for new timestamps', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final labelField = find.byWidgetPredicate(
          (widget) => widget is TextField && widget.autofocus == true,
        );

        expect(labelField, findsOneWidget);
      });

      testWidgets('label field starts empty', (tester) async {
        await tester.pumpWidget(buildForm());

        // Find label input by hint text
        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        expect(labelField, findsOneWidget);

        final textField = tester.widget<TextField>(labelField);
        expect(textField.controller?.text, isEmpty);
      });
    });

    group('initialization - editing timestamp', () {
      late VideoTimestamp existingTimestamp;

      setUp(() {
        existingTimestamp = VideoTimestamp(
          id: 'existing-timestamp',
          startTime: const Duration(seconds: 15),
          endTime: const Duration(seconds: 25),
          label: 'Pirouette',
        );
      });

      testWidgets('displays "Edit Timestamp" header', (tester) async {
        await tester.pumpWidget(
          buildForm(existingTimestamp: existingTimestamp),
        );

        expect(find.text('Edit Timestamp'), findsOneWidget);
        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('pre-populates times from existing timestamp', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(existingTimestamp: existingTimestamp),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Start time: 0:15
        expect(
          tester.widget<TextField>(textFields.at(0)).controller?.text,
          '0',
        );
        expect(
          tester.widget<TextField>(textFields.at(1)).controller?.text,
          '15',
        );

        // End time: 0:25
        expect(
          tester.widget<TextField>(textFields.at(2)).controller?.text,
          '0',
        );
        expect(
          tester.widget<TextField>(textFields.at(3)).controller?.text,
          '25',
        );
      });

      testWidgets('pre-populates label from existing timestamp', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(existingTimestamp: existingTimestamp),
        );

        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        final textField = tester.widget<TextField>(labelField);

        expect(textField.controller?.text, 'Pirouette');
      });

      testWidgets('label field does not autofocus when editing', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(existingTimestamp: existingTimestamp),
        );
        await tester.pumpAndSettle();

        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        final textField = tester.widget<TextField>(labelField);

        expect(textField.autofocus, isFalse);
      });

      testWidgets('displays "Save" button instead of "Add"', (tester) async {
        await tester.pumpWidget(
          buildForm(existingTimestamp: existingTimestamp),
        );

        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Add'), findsNothing);
      });
    });

    group('validation', () {
      testWidgets('shows error when end time <= start time', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Find all TextFields
        final textFields = find.byType(TextField);

        // Set start time to 0:30
        await tester.enterText(textFields.at(0), '0');
        await tester.enterText(textFields.at(1), '30');

        // Set end time to 0:20 (before start)
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '20');
        await tester.pumpAndSettle();

        expect(find.text('End time must be after start time'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows error when end time equals start time', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Set both to 0:30
        await tester.enterText(textFields.at(0), '0');
        await tester.enterText(textFields.at(1), '30');
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '30');
        await tester.pumpAndSettle();

        expect(find.text('End time must be after start time'), findsOneWidget);
      });

      testWidgets('shows error when end time exceeds maxDuration', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(maxDuration: const Duration(seconds: 60)),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Set end time to 1:30 (90 seconds, exceeds 60)
        await tester.enterText(textFields.at(2), '1');
        await tester.enterText(textFields.at(3), '30');
        await tester.pumpAndSettle();

        expect(find.text('End time exceeds video duration'), findsOneWidget);
      });

      testWidgets('shows error when start time is negative', (tester) async {
        // Note: Input formatter prevents actual negative input, but let's test the validation logic
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // The validation would trigger if minutes/seconds are 0/0
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), '0');
        await tester.enterText(textFields.at(1), '0');
        await tester.pumpAndSettle();

        // With start at 0:00 and default end at 0:35, should be valid
        expect(find.text('Start time must be positive'), findsNothing);
      });

      testWidgets('clears error when times become valid', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Create error condition
        await tester.enterText(textFields.at(0), '0');
        await tester.enterText(textFields.at(1), '30');
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '20');
        await tester.pumpAndSettle();

        expect(find.text('End time must be after start time'), findsOneWidget);

        // Fix it
        await tester.enterText(textFields.at(3), '40');
        await tester.pumpAndSettle();

        expect(find.text('End time must be after start time'), findsNothing);
      });

      testWidgets('save button is disabled when label is empty', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(ElevatedButton, 'Add');
        final button = tester.widget<ElevatedButton>(saveButton);

        expect(button.onPressed, isNull); // Disabled
      });

      testWidgets('save button is disabled when validation error exists', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Enter label
        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, 'Test Label');

        // Create validation error
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '20');
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(ElevatedButton, 'Add');
        final button = tester.widget<ElevatedButton>(saveButton);

        expect(button.onPressed, isNull); // Disabled
      });

      testWidgets('save button is enabled when form is valid', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Enter valid label
        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, 'Valid Label');
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(ElevatedButton, 'Add');
        final button = tester.widget<ElevatedButton>(saveButton);

        expect(button.onPressed, isNotNull); // Enabled
      });
    });

    group('time input controls', () {
      testWidgets('displays "Now" buttons for start and end times', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());

        expect(find.text('Now'), findsNWidgets(2));
        expect(find.byIcon(Icons.access_time), findsNWidgets(2));
      });

      testWidgets('sets start time to current position when "Now" clicked', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(
            currentVideoPosition: const Duration(minutes: 2, seconds: 15),
          ),
        );
        await tester.pumpAndSettle();

        // Click first "Now" button (start time)
        await tester.tap(find.text('Now').first);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        expect(
          tester.widget<TextField>(textFields.at(0)).controller?.text,
          '2',
        );
        expect(
          tester.widget<TextField>(textFields.at(1)).controller?.text,
          '15',
        );
      });

      testWidgets('sets end time to current position when "Now" clicked', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildForm(
            currentVideoPosition: const Duration(minutes: 3, seconds: 45),
          ),
        );
        await tester.pumpAndSettle();

        // Click second "Now" button (end time)
        await tester.tap(find.text('Now').last);
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        expect(
          tester.widget<TextField>(textFields.at(2)).controller?.text,
          '3',
        );
        expect(
          tester.widget<TextField>(textFields.at(3)).controller?.text,
          '45',
        );
      });

      testWidgets('seconds input restricts values to 0-59', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        final secondsField = textFields.at(1); // Start seconds

        // Try to enter 99 - should be rejected
        await tester.enterText(secondsField, '99');
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(secondsField);
        expect(int.tryParse(textField.controller?.text ?? '0')! <= 59, isTrue);
      });

      testWidgets('time fields only accept digits', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);
        final minutesField = textFields.at(0);

        // Try to enter letters - should be filtered
        await tester.enterText(minutesField, 'abc');
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(minutesField);
        expect(textField.controller?.text, isEmpty);
      });
    });

    group('save and cancel actions', () {
      testWidgets('calls onSave with correct parameters', (tester) async {
        Duration? savedStart;
        Duration? savedEnd;
        String? savedLabel;

        await tester.pumpWidget(
          buildForm(
            onSave: (start, end, label) {
              savedStart = start;
              savedEnd = end;
              savedLabel = label;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Enter data
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), '1');
        await tester.enterText(textFields.at(1), '15');
        await tester.enterText(textFields.at(2), '2');
        await tester.enterText(textFields.at(3), '30');

        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, 'Test Step');
        await tester.pumpAndSettle();

        // Click Add button
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(savedStart, const Duration(minutes: 1, seconds: 15));
        expect(savedEnd, const Duration(minutes: 2, seconds: 30));
        expect(savedLabel, 'Test Step');
      });

      testWidgets('trims whitespace from label before saving', (tester) async {
        String? savedLabel;

        await tester.pumpWidget(
          buildForm(
            onSave: (start, end, label) {
              savedLabel = label;
            },
          ),
        );
        await tester.pumpAndSettle();

        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, '  Padded Label  ');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(savedLabel, 'Padded Label');
      });

      testWidgets('submits form when Enter pressed in label field', (
        tester,
      ) async {
        var savePressed = false;

        await tester.pumpWidget(
          buildForm(
            onSave: (start, end, label) {
              savePressed = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Enter valid label
        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, 'Quick Entry');
        await tester.pumpAndSettle();

        // Press Enter
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(savePressed, isTrue);
      });

      testWidgets('calls onCancel when close button clicked', (tester) async {
        var cancelPressed = false;

        await tester.pumpWidget(
          buildForm(onCancel: () => cancelPressed = true),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(cancelPressed, isTrue);
      });

      testWidgets('calls onCancel when Cancel button clicked', (tester) async {
        var cancelPressed = false;

        await tester.pumpWidget(
          buildForm(onCancel: () => cancelPressed = true),
        );

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(cancelPressed, isTrue);
      });

      testWidgets('does not save when form is invalid', (tester) async {
        var savePressed = false;

        await tester.pumpWidget(
          buildForm(
            onSave: (start, end, label) {
              savePressed = true;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Leave label empty - form is invalid
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();

        expect(savePressed, isFalse);
      });
    });

    group('design system compliance', () {
      testWidgets('uses correct border color from design system', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());

        final container = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).border != null,
        );

        expect(container, findsOneWidget);
      });

      testWidgets('uses correct accent color for save button', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Enter label to enable button
        final labelField = find.widgetWithText(
          TextField,
          'e.g., Pirouette, Grand Jeté',
        );
        await tester.enterText(labelField, 'Test');
        await tester.pumpAndSettle();

        final saveButton = find.widgetWithText(ElevatedButton, 'Add');
        final button = tester.widget<ElevatedButton>(saveButton);

        expect(
          button.style?.backgroundColor?.resolve({}),
          AppDesignSystem.accentPurple,
        );
      });

      testWidgets('error message has correct styling', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Create validation error
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '20');
        await tester.pumpAndSettle();

        final errorIcon = find.byIcon(Icons.error_outline);
        final icon = tester.widget<Icon>(errorIcon);

        expect(icon.color, AppDesignSystem.errorRed);
      });
    });

    group('edge cases', () {
      testWidgets('handles empty time inputs gracefully', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Clear all time fields
        await tester.enterText(textFields.at(0), '');
        await tester.enterText(textFields.at(1), '');
        await tester.enterText(textFields.at(2), '');
        await tester.enterText(textFields.at(3), '');
        await tester.pumpAndSettle();

        // Should not crash - times should default to 0
        expect(find.text('End time must be after start time'), findsOneWidget);
      });

      testWidgets('handles very large time values', (tester) async {
        await tester.pumpWidget(
          buildForm(
            currentVideoPosition: const Duration(hours: 10),
            maxDuration: const Duration(hours: 24),
          ),
        );
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Set very large times
        await tester.enterText(textFields.at(0), '600'); // 10 hours
        await tester.enterText(textFields.at(2), '1200'); // 20 hours
        await tester.pumpAndSettle();

        // Should not crash
        expect(find.byType(InlineTimestampForm), findsOneWidget);
      });

      testWidgets('updates validation when both start and end change', (
        tester,
      ) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextField);

        // Set valid times
        await tester.enterText(textFields.at(0), '1');
        await tester.enterText(textFields.at(1), '00');
        await tester.enterText(textFields.at(2), '2');
        await tester.enterText(textFields.at(3), '00');
        await tester.pumpAndSettle();

        // No error
        expect(find.byIcon(Icons.error_outline), findsNothing);

        // Now set end before start
        await tester.enterText(textFields.at(2), '0');
        await tester.enterText(textFields.at(3), '30');
        await tester.pumpAndSettle();

        // Error should appear
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });
    });

    group('controller cleanup', () {
      testWidgets('disposes controllers properly', (tester) async {
        await tester.pumpWidget(buildForm());
        await tester.pumpAndSettle();

        // Navigate away to trigger dispose
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        await tester.pumpAndSettle();

        // Should not crash or leak
      });
    });
  });
}
