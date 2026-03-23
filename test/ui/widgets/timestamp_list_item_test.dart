import 'package:dance_analysis_client/models/video_timestamp.dart';
import 'package:dance_analysis_client/shared/design_system/theme.dart';
import 'package:dance_analysis_client/shared/widgets/timestamp_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TimestampListItem', () {
    late VideoTimestamp testTimestamp;

    setUp(() {
      testTimestamp = VideoTimestamp(
        id: 'test-timestamp-1',
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 15),
        label: 'Pirouette',
      );
    });

    Widget buildTimestampListItem({
      VideoTimestamp? timestamp,
      VoidCallback? onTap,
      VoidCallback? onDelete,
      VoidCallback? onEdit,
      bool isEditing = false,
      Widget? editForm,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TimestampListItem(
            timestamp: timestamp ?? testTimestamp,
            onTap: onTap,
            onDelete: onDelete,
            onEdit: onEdit,
            isEditing: isEditing,
            editForm: editForm,
          ),
        ),
      );
    }

    group('basic rendering', () {
      testWidgets('displays timestamp time range', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        expect(find.text('0:10 - 0:15'), findsOneWidget);
      });

      testWidgets('displays timestamp label', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        expect(find.text('Pirouette'), findsOneWidget);
      });

      testWidgets('displays bookmark icon', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        expect(find.byIcon(Icons.bookmark), findsOneWidget);
      });

      testWidgets('displays divider', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        // Verify divider container exists with correct decoration color
        final dividerContainer = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color ==
                  AppDesignSystem.dividerLight,
        );

        expect(dividerContainer, findsOneWidget);
      });

      testWidgets('formats time range correctly for different durations', (
        tester,
      ) async {
        final timestamp = VideoTimestamp(
          id: 'test-timestamp-2',
          startTime: const Duration(minutes: 1, seconds: 30),
          endTime: const Duration(minutes: 2, seconds: 45),
          label: 'Grand Jeté',
        );

        await tester.pumpWidget(buildTimestampListItem(timestamp: timestamp));

        expect(find.text('1:30 - 2:45'), findsOneWidget);
      });
    });

    group('tap handling', () {
      testWidgets('calls onTap when item is tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          buildTimestampListItem(onTap: () => tapped = true),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      });

      testWidgets('does not crash when onTap is null', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();

        // Should not throw
      });
    });

    group('action buttons', () {
      testWidgets('displays edit button when onEdit is provided', (
        tester,
      ) async {
        await tester.pumpWidget(buildTimestampListItem(onEdit: () {}));

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      });

      testWidgets('does not display edit button when onEdit is null', (
        tester,
      ) async {
        await tester.pumpWidget(buildTimestampListItem());

        expect(find.byIcon(Icons.edit_outlined), findsNothing);
      });

      testWidgets('calls onEdit when edit button is pressed', (tester) async {
        var editPressed = false;
        await tester.pumpWidget(
          buildTimestampListItem(onEdit: () => editPressed = true),
        );

        await tester.tap(find.byIcon(Icons.edit_outlined));
        await tester.pumpAndSettle();

        expect(editPressed, isTrue);
      });

      testWidgets('displays delete button when onDelete is provided', (
        tester,
      ) async {
        await tester.pumpWidget(buildTimestampListItem(onDelete: () {}));

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('does not display delete button when onDelete is null', (
        tester,
      ) async {
        await tester.pumpWidget(buildTimestampListItem());

        expect(find.byIcon(Icons.delete_outline), findsNothing);
      });

      testWidgets('calls onDelete when delete button is pressed', (
        tester,
      ) async {
        var deletePressed = false;
        await tester.pumpWidget(
          buildTimestampListItem(onDelete: () => deletePressed = true),
        );

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle();

        expect(deletePressed, isTrue);
      });

      testWidgets('displays both edit and delete buttons when both provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTimestampListItem(onEdit: () {}, onDelete: () {}),
        );

        expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('delete button has error red color', (tester) async {
        await tester.pumpWidget(buildTimestampListItem(onDelete: () {}));

        final deleteButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.delete_outline),
        );
        expect(deleteButton.color, AppDesignSystem.errorRed);
      });

      testWidgets('edit button has secondary text color', (tester) async {
        await tester.pumpWidget(buildTimestampListItem(onEdit: () {}));

        final editButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.edit_outlined),
        );
        expect(editButton.color, AppDesignSystem.textSecondary);
      });
    });

    group('editing mode', () {
      testWidgets(
        'shows edit form when isEditing is true and editForm provided',
        (tester) async {
          const editFormKey = Key('edit-form');
          await tester.pumpWidget(
            buildTimestampListItem(
              isEditing: true,
              editForm: const Text('Edit Form', key: editFormKey),
            ),
          );

          expect(find.byKey(editFormKey), findsOneWidget);
          expect(find.text('Edit Form'), findsOneWidget);

          // Normal content should not be visible
          expect(find.text('Pirouette'), findsNothing);
          expect(find.byIcon(Icons.bookmark), findsNothing);
        },
      );

      testWidgets('shows normal view when isEditing is false', (tester) async {
        await tester.pumpWidget(
          buildTimestampListItem(
            isEditing: false,
            editForm: const Text('Edit Form'),
          ),
        );

        expect(find.text('Edit Form'), findsNothing);
        expect(find.text('Pirouette'), findsOneWidget);
      });

      testWidgets(
        'shows normal view when isEditing is true but editForm is null',
        (tester) async {
          await tester.pumpWidget(
            buildTimestampListItem(isEditing: true, editForm: null),
          );

          expect(find.text('Pirouette'), findsOneWidget);
          expect(find.byIcon(Icons.bookmark), findsOneWidget);
        },
      );
    });

    group('text overflow', () {
      testWidgets('truncates long labels with ellipsis', (tester) async {
        final longLabel = 'A' * 200;
        final timestamp = VideoTimestamp(
          id: 'test-timestamp-3',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 15),
          label: longLabel,
        );

        await tester.pumpWidget(buildTimestampListItem(timestamp: timestamp));

        final textWidget = tester.widget<Text>(find.text(longLabel));
        expect(textWidget.overflow, TextOverflow.ellipsis);
      });
    });

    group('accessibility', () {
      testWidgets('has proper widget tree for screen readers', (tester) async {
        await tester.pumpWidget(
          buildTimestampListItem(onEdit: () {}, onDelete: () {}),
        );

        // Verify semantic structure - InkWell is used within MaterialApp scaffolding
        expect(find.byType(IconButton), findsNWidgets(2));
        expect(find.byType(TimestampListItem), findsOneWidget);
      });
    });

    group('design system compliance', () {
      testWidgets('uses correct colors from design system', (tester) async {
        await tester.pumpWidget(
          buildTimestampListItem(onEdit: () {}, onDelete: () {}),
        );

        // Bookmark icon color
        final bookmarkIcon = tester.widget<Icon>(find.byIcon(Icons.bookmark));
        expect(bookmarkIcon.color, AppDesignSystem.accentPurple);

        // Timestamp text color
        final timestampText = tester.widget<Text>(find.text('0:10 - 0:15'));
        expect(timestampText.style?.color, AppDesignSystem.textPrimary);

        // Label text color
        final labelText = tester.widget<Text>(find.text('Pirouette'));
        expect(labelText.style?.color, AppDesignSystem.textSecondary);
      });

      testWidgets('uses correct spacing from design system', (tester) async {
        await tester.pumpWidget(buildTimestampListItem());

        final padding = tester.widget<Padding>(find.byType(Padding).first);
        expect(
          padding.padding,
          const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingXs,
            vertical: AppDesignSystem.spacingXs,
          ),
        );
      });
    });

    group('edge cases', () {
      testWidgets('handles zero duration timestamps', (tester) async {
        final timestamp = VideoTimestamp(
          id: 'test-timestamp-4',
          startTime: Duration.zero,
          endTime: Duration.zero,
          label: 'Start',
        );

        await tester.pumpWidget(buildTimestampListItem(timestamp: timestamp));

        expect(find.text('0:00 - 0:00'), findsOneWidget);
        expect(find.text('Start'), findsOneWidget);
      });

      testWidgets('handles empty label', (tester) async {
        final timestamp = VideoTimestamp(
          id: 'test-timestamp-5',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 15),
          label: '',
        );

        await tester.pumpWidget(buildTimestampListItem(timestamp: timestamp));

        expect(find.text('0:10 - 0:15'), findsOneWidget);
        // Empty label should still render (even if empty)
        final labelFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data == '' &&
              widget.style?.color == AppDesignSystem.textSecondary,
        );
        expect(labelFinder, findsOneWidget);
      });

      testWidgets('handles very long time ranges', (tester) async {
        final timestamp = VideoTimestamp(
          id: 'test-timestamp-6',
          startTime: const Duration(hours: 2, minutes: 30, seconds: 15),
          endTime: const Duration(hours: 3, minutes: 45, seconds: 30),
          label: 'Long sequence',
        );

        await tester.pumpWidget(buildTimestampListItem(timestamp: timestamp));

        expect(find.text('150:15 - 225:30'), findsOneWidget);
      });

      testWidgets('handles multiple timestamps in list', (tester) async {
        final timestamps = [
          VideoTimestamp(
            id: 'test-timestamp-7',
            startTime: const Duration(seconds: 10),
            endTime: const Duration(seconds: 15),
            label: 'First',
          ),
          VideoTimestamp(
            id: 'test-timestamp-8',
            startTime: const Duration(seconds: 20),
            endTime: const Duration(seconds: 25),
            label: 'Second',
          ),
          VideoTimestamp(
            id: 'test-timestamp-9',
            startTime: const Duration(seconds: 30),
            endTime: const Duration(seconds: 35),
            label: 'Third',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: timestamps.length,
                itemBuilder: (context, index) => TimestampListItem(
                  timestamp: timestamps[index],
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('First'), findsOneWidget);
        expect(find.text('Second'), findsOneWidget);
        expect(find.text('Third'), findsOneWidget);
      });
    });
  });
}
