import 'package:dance_analysis_client/models/feedback_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedbackItem', () {
    group('constructor', () {
      test('creates instance with required fields', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
        );

        expect(item.timestamp, '0:15');
        expect(item.type, FeedbackType.positive);
        expect(item.feedback, isNull);
      });

      test('creates instance with optional feedback', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.negative,
          feedback: 'Keep your back straight',
        );

        expect(item.feedback, 'Keep your back straight');
      });
    });

    group('hasFeedback', () {
      test('returns false when feedback is null', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
        );

        expect(item.hasFeedback, isFalse);
      });

      test('returns false when feedback is empty string', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
          feedback: '',
        );

        expect(item.hasFeedback, isFalse);
      });

      test('returns true when feedback has content', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
          feedback: 'Great form!',
        );

        expect(item.hasFeedback, isTrue);
      });
    });

    group('icon', () {
      test('returns ▲ for positive feedback', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
        );

        expect(item.icon, '▲');
      });

      test('returns ▼ for negative feedback', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.negative,
        );

        expect(item.icon, '▼');
      });
    });

    group('duration', () {
      test('parses simple seconds correctly', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
        );

        expect(item.duration, const Duration(seconds: 15));
      });

      test('parses minutes and seconds correctly', () {
        const item = FeedbackItem(
          timestamp: '2:30',
          type: FeedbackType.positive,
        );

        expect(item.duration, const Duration(minutes: 2, seconds: 30));
      });

      test('handles single digit seconds', () {
        const item = FeedbackItem(
          timestamp: '0:08',
          type: FeedbackType.positive,
        );

        expect(item.duration, const Duration(seconds: 8));
      });

      test('returns Duration.zero for malformed timestamp', () {
        const item = FeedbackItem(
          timestamp: 'invalid',
          type: FeedbackType.positive,
        );

        expect(item.duration, Duration.zero);
      });

      test('returns Duration.zero for timestamp without colon', () {
        const item = FeedbackItem(
          timestamp: '15',
          type: FeedbackType.positive,
        );

        expect(item.duration, Duration.zero);
      });

      test('handles non-numeric values gracefully', () {
        const item = FeedbackItem(
          timestamp: 'a:b',
          type: FeedbackType.positive,
        );

        expect(item.duration, Duration.zero);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.positive,
          feedback: 'Excellent posture',
        );

        final json = item.toJson();

        expect(json['timestamp'], '0:15');
        expect(json['type'], 'positive');
        expect(json['feedback'], 'Excellent posture');
      });

      test('serializes null feedback', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.negative,
        );

        final json = item.toJson();

        expect(json['feedback'], isNull);
      });

      test('uses enum name for type', () {
        const item = FeedbackItem(
          timestamp: '0:15',
          type: FeedbackType.negative,
        );

        final json = item.toJson();

        expect(json['type'], 'negative');
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final json = {
          'timestamp': '0:15',
          'type': 'positive',
          'feedback': 'Great work!',
        };

        final item = FeedbackItem.fromJson(json);

        expect(item.timestamp, '0:15');
        expect(item.type, FeedbackType.positive);
        expect(item.feedback, 'Great work!');
      });

      test('deserializes null feedback', () {
        final json = {
          'timestamp': '0:15',
          'type': 'positive',
          'feedback': null,
        };

        final item = FeedbackItem.fromJson(json);

        expect(item.feedback, isNull);
      });

      test('handles negative type', () {
        final json = {
          'timestamp': '0:15',
          'type': 'negative',
        };

        final item = FeedbackItem.fromJson(json);

        expect(item.type, FeedbackType.negative);
      });

      test('defaults to negative for unknown type', () {
        final json = {
          'timestamp': '0:15',
          'type': 'unknown_type',
        };

        final item = FeedbackItem.fromJson(json);

        expect(item.type, FeedbackType.negative);
      });
    });

    group('JSON roundtrip', () {
      test('maintains data integrity through serialization cycle', () {
        const original = FeedbackItem(
          timestamp: '1:23',
          type: FeedbackType.positive,
          feedback: 'Perfect timing',
        );

        final json = original.toJson();
        final restored = FeedbackItem.fromJson(json);

        expect(restored.timestamp, original.timestamp);
        expect(restored.type, original.type);
        expect(restored.feedback, original.feedback);
      });
    });
  });

  group('FeedbackType', () {
    group('values', () {
      test('has exactly two values', () {
        expect(FeedbackType.values.length, 2);
      });

      test('contains positive and negative', () {
        expect(FeedbackType.values, contains(FeedbackType.positive));
        expect(FeedbackType.values, contains(FeedbackType.negative));
      });
    });
  });

  group('FeedbackTypeExtension', () {
    test('isPositive returns true for positive type', () {
      expect(FeedbackType.positive.isPositive, isTrue);
      expect(FeedbackType.negative.isPositive, isFalse);
    });

    test('isNegative returns true for negative type', () {
      expect(FeedbackType.negative.isNegative, isTrue);
      expect(FeedbackType.positive.isNegative, isFalse);
    });
  });
}
