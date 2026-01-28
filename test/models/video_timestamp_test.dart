import 'package:dance_analysis_client/models/video_timestamp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoTimestamp', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Pirouette',
        );

        expect(timestamp.id, 'test-id');
        expect(timestamp.startTime, const Duration(seconds: 5));
        expect(timestamp.endTime, const Duration(seconds: 10));
        expect(timestamp.label, 'Pirouette');
      });
    });

    group('formattedStartTime', () {
      test('formats seconds correctly', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 45),
          endTime: Duration(seconds: 50),
          label: 'Test',
        );

        expect(timestamp.formattedStartTime, '0:45');
      });

      test('formats minutes and seconds correctly', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(minutes: 2, seconds: 30),
          endTime: Duration(minutes: 2, seconds: 35),
          label: 'Test',
        );

        expect(timestamp.formattedStartTime, '2:30');
      });

      test('pads seconds with zero', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 8),
          endTime: Duration(seconds: 15),
          label: 'Test',
        );

        expect(timestamp.formattedStartTime, '0:08');
      });

      test('does not pad minutes with zero', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(minutes: 3, seconds: 5),
          endTime: Duration(minutes: 3, seconds: 10),
          label: 'Test',
        );

        expect(timestamp.formattedStartTime, '3:05');
      });
    });

    group('formattedEndTime', () {
      test('formats correctly', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(minutes: 1, seconds: 15),
          label: 'Test',
        );

        expect(timestamp.formattedEndTime, '1:15');
      });

      test('pads seconds with zero', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 9),
          label: 'Test',
        );

        expect(timestamp.formattedEndTime, '0:09');
      });
    });

    group('formattedTimeRange', () {
      test('combines start and end times', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        expect(timestamp.formattedTimeRange, '0:05 - 0:10');
      });

      test('formats multi-minute ranges correctly', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(minutes: 1, seconds: 20),
          endTime: Duration(minutes: 2, seconds: 5),
          label: 'Test',
        );

        expect(timestamp.formattedTimeRange, '1:20 - 2:05');
      });
    });

    group('duration', () {
      test('calculates correct duration', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 15),
          label: 'Test',
        );

        expect(timestamp.duration, const Duration(seconds: 10));
      });

      test('handles multi-minute durations', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(minutes: 1, seconds: 30),
          endTime: Duration(minutes: 3, seconds: 15),
          label: 'Test',
        );

        expect(timestamp.duration, const Duration(minutes: 1, seconds: 45));
      });

      test('handles zero duration', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        expect(timestamp.duration, Duration.zero);
      });
    });

    group('copyWith', () {
      test('creates copy with updated id', () {
        const original = VideoTimestamp(
          id: 'old-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        final updated = original.copyWith(id: 'new-id');

        expect(updated.id, 'new-id');
        expect(updated.startTime, original.startTime);
        expect(updated.endTime, original.endTime);
        expect(updated.label, original.label);
      });

      test('creates copy with updated startTime', () {
        const original = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        final updated = original.copyWith(
          startTime: const Duration(seconds: 8),
        );

        expect(updated.startTime, const Duration(seconds: 8));
        expect(updated.id, original.id);
      });

      test('creates copy with updated endTime', () {
        const original = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        final updated = original.copyWith(endTime: const Duration(seconds: 15));

        expect(updated.endTime, const Duration(seconds: 15));
        expect(updated.id, original.id);
      });

      test('creates copy with updated label', () {
        const original = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Original',
        );

        final updated = original.copyWith(label: 'Updated');

        expect(updated.label, 'Updated');
        expect(updated.id, original.id);
      });

      test('creates copy with multiple updated fields', () {
        const original = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Original',
        );

        final updated = original.copyWith(
          startTime: const Duration(seconds: 3),
          endTime: const Duration(seconds: 12),
          label: 'Updated',
        );

        expect(updated.startTime, const Duration(seconds: 3));
        expect(updated.endTime, const Duration(seconds: 12));
        expect(updated.label, 'Updated');
        expect(updated.id, original.id);
      });

      test('returns equivalent instance when no fields updated', () {
        const original = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        final updated = original.copyWith();

        expect(updated.id, original.id);
        expect(updated.startTime, original.startTime);
        expect(updated.endTime, original.endTime);
        expect(updated.label, original.label);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Pirouette',
        );

        final json = timestamp.toJson();

        expect(json['id'], 'test-id');
        expect(json['start_time_seconds'], 5);
        expect(json['end_time_seconds'], 10);
        expect(json['label'], 'Pirouette');
      });

      test('converts durations to seconds', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(minutes: 2, seconds: 30),
          endTime: Duration(minutes: 3, seconds: 15),
          label: 'Test',
        );

        final json = timestamp.toJson();

        expect(json['start_time_seconds'], 150); // 2:30
        expect(json['end_time_seconds'], 195); // 3:15
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'id': 'test-id',
          'start_time_seconds': 5,
          'end_time_seconds': 10,
          'label': 'Pirouette',
        };

        final timestamp = VideoTimestamp.fromJson(json);

        expect(timestamp.id, 'test-id');
        expect(timestamp.startTime, const Duration(seconds: 5));
        expect(timestamp.endTime, const Duration(seconds: 10));
        expect(timestamp.label, 'Pirouette');
      });

      test('converts seconds to Duration', () {
        final json = {
          'id': 'test-id',
          'start_time_seconds': 150,
          'end_time_seconds': 195,
          'label': 'Test',
        };

        final timestamp = VideoTimestamp.fromJson(json);

        expect(timestamp.startTime, const Duration(minutes: 2, seconds: 30));
        expect(timestamp.endTime, const Duration(minutes: 3, seconds: 15));
      });
    });

    group('JSON roundtrip', () {
      test('maintains data integrity through serialization cycle', () {
        const original = VideoTimestamp(
          id: 'round-trip-test',
          startTime: Duration(minutes: 1, seconds: 23),
          endTime: Duration(minutes: 2, seconds: 45),
          label: 'Grand Jeté',
        );

        final json = original.toJson();
        final restored = VideoTimestamp.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.label, original.label);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        const timestamp1 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );
        const timestamp2 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        expect(timestamp1, equals(timestamp2));
        expect(timestamp1.hashCode, equals(timestamp2.hashCode));
      });

      test('different ids are not equal', () {
        const timestamp1 = VideoTimestamp(
          id: 'id-1',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );
        const timestamp2 = VideoTimestamp(
          id: 'id-2',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        expect(timestamp1, isNot(equals(timestamp2)));
      });

      test('different times are not equal', () {
        const timestamp1 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );
        const timestamp2 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 6),
          endTime: Duration(seconds: 10),
          label: 'Test',
        );

        expect(timestamp1, isNot(equals(timestamp2)));
      });

      test('different labels are not equal', () {
        const timestamp1 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test1',
        );
        const timestamp2 = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Test2',
        );

        expect(timestamp1, isNot(equals(timestamp2)));
      });
    });

    group('toString', () {
      test('includes id, range, and label', () {
        const timestamp = VideoTimestamp(
          id: 'test-id',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          label: 'Pirouette',
        );

        final string = timestamp.toString();

        expect(string, contains('test-id'));
        expect(string, contains('0:05 - 0:10'));
        expect(string, contains('Pirouette'));
      });
    });
  });
}
