import 'package:dance_analysis_client/features/upload/domain/models/video_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoMetadata', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/path/to/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.id, 'test-id');
        expect(metadata.originalPath, '/path/to/video.mp4');
        expect(metadata.totalDuration, const Duration(seconds: 60));
      });

      test('has correct default values', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/path/to/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.startTime, Duration.zero);
        expect(metadata.endTime, isNull);
        expect(metadata.trimmedPath, isNull);
        expect(metadata.uploadedAt, isNull);
        expect(metadata.backendReference, isNull);
      });

      test('accepts all optional fields', () {
        final uploadTime = DateTime(2024, 1, 15);
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/original.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 55),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
          backendReference: 'backend-ref-123',
        );

        expect(metadata.trimmedPath, '/trimmed.mp4');
        expect(metadata.startTime, const Duration(seconds: 5));
        expect(metadata.endTime, const Duration(seconds: 55));
        expect(metadata.uploadedAt, uploadTime);
        expect(metadata.backendReference, 'backend-ref-123');
      });
    });

    group('effectivePath', () {
      test('returns trimmedPath when available', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/original.mp4',
          trimmedPath: '/trimmed.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.effectivePath, '/trimmed.mp4');
      });

      test('returns originalPath when trimmedPath is null', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/original.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.effectivePath, '/original.mp4');
      });
    });

    group('effectiveEndTime', () {
      test('returns endTime when set', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          endTime: const Duration(seconds: 45),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.effectiveEndTime, const Duration(seconds: 45));
      });

      test('returns totalDuration when endTime is null', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.effectiveEndTime, const Duration(seconds: 60));
      });
    });

    group('trimmedDuration', () {
      test('calculates duration from start to end', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.trimmedDuration, const Duration(seconds: 40));
      });

      test('uses totalDuration when endTime is null', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 10),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.trimmedDuration, const Duration(seconds: 50));
      });

      test('equals totalDuration when no trimming', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.trimmedDuration, const Duration(seconds: 60));
      });

      test('handles zero duration', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 30),
          endTime: const Duration(seconds: 30),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.trimmedDuration, Duration.zero);
      });
    });

    group('isTrimmed', () {
      test('returns true when startTime > 0', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 5),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isTrimmed, isTrue);
      });

      test('returns true when endTime < totalDuration', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isTrimmed, isTrue);
      });

      test('returns true when both start and end trimmed', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isTrimmed, isTrue);
      });

      test('returns false when no trimming', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isTrimmed, isFalse);
      });

      test('returns false when endTime equals totalDuration', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          endTime: const Duration(seconds: 60),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isTrimmed, isFalse);
      });
    });

    group('isUploaded', () {
      test('returns true when backendReference is set', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
          backendReference: 'backend-123',
        );

        expect(metadata.isUploaded, isTrue);
      });

      test('returns false when backendReference is null', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.isUploaded, isFalse);
      });
    });

    group('copyWith', () {
      late VideoMetadata original;

      setUp(() {
        original = VideoMetadata(
          id: 'original-id',
          originalPath: '/original.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 55),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: DateTime(2024, 1, 15),
          backendReference: 'ref-123',
        );
      });

      test('updates id', () {
        final updated = original.copyWith(id: 'new-id');

        expect(updated.id, 'new-id');
        expect(updated.originalPath, original.originalPath);
      });

      test('updates originalPath', () {
        final updated = original.copyWith(originalPath: '/new-original.mp4');

        expect(updated.originalPath, '/new-original.mp4');
        expect(updated.id, original.id);
      });

      test('updates trimmedPath', () {
        final updated = original.copyWith(trimmedPath: '/new-trimmed.mp4');

        expect(updated.trimmedPath, '/new-trimmed.mp4');
      });

      test('clears trimmedPath with clearTrimmedPath flag', () {
        final updated = original.copyWith(clearTrimmedPath: true);

        expect(updated.trimmedPath, isNull);
      });

      test('updates startTime', () {
        final updated = original.copyWith(
          startTime: const Duration(seconds: 10),
        );

        expect(updated.startTime, const Duration(seconds: 10));
      });

      test('updates endTime', () {
        final updated = original.copyWith(endTime: const Duration(seconds: 50));

        expect(updated.endTime, const Duration(seconds: 50));
      });

      test('clears endTime with clearEndTime flag', () {
        final updated = original.copyWith(clearEndTime: true);

        expect(updated.endTime, isNull);
      });

      test('updates totalDuration', () {
        final updated = original.copyWith(
          totalDuration: const Duration(seconds: 120),
        );

        expect(updated.totalDuration, const Duration(seconds: 120));
      });

      test('updates uploadedAt', () {
        final newDate = DateTime(2024, 2, 20);
        final updated = original.copyWith(uploadedAt: newDate);

        expect(updated.uploadedAt, newDate);
      });

      test('clears uploadedAt with clearUploadedAt flag', () {
        final updated = original.copyWith(clearUploadedAt: true);

        expect(updated.uploadedAt, isNull);
      });

      test('updates backendReference', () {
        final updated = original.copyWith(backendReference: 'new-ref-456');

        expect(updated.backendReference, 'new-ref-456');
      });

      test('clears backendReference with clearBackendReference flag', () {
        final updated = original.copyWith(clearBackendReference: true);

        expect(updated.backendReference, isNull);
      });

      test('updates multiple fields simultaneously', () {
        final newDate = DateTime(2024, 3, 1);
        final updated = original.copyWith(
          id: 'multi-id',
          startTime: const Duration(seconds: 15),
          endTime: const Duration(seconds: 45),
          uploadedAt: newDate,
          backendReference: 'multi-ref',
        );

        expect(updated.id, 'multi-id');
        expect(updated.startTime, const Duration(seconds: 15));
        expect(updated.endTime, const Duration(seconds: 45));
        expect(updated.uploadedAt, newDate);
        expect(updated.backendReference, 'multi-ref');
      });

      test('returns equivalent instance when no parameters provided', () {
        final updated = original.copyWith();

        expect(updated.id, original.id);
        expect(updated.originalPath, original.originalPath);
        expect(updated.trimmedPath, original.trimmedPath);
        expect(updated.startTime, original.startTime);
        expect(updated.endTime, original.endTime);
        expect(updated.totalDuration, original.totalDuration);
        expect(updated.uploadedAt, original.uploadedAt);
        expect(updated.backendReference, original.backendReference);
      });

      test('clear flags take precedence over provided values', () {
        final updated = original.copyWith(
          trimmedPath: '/should-be-ignored.mp4',
          clearTrimmedPath: true,
        );

        expect(updated.trimmedPath, isNull);
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final uploadTime = DateTime(2024, 1, 15, 10, 30);
        final metadata = VideoMetadata(
          id: 'json-test',
          originalPath: '/original.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
          backendReference: 'ref-abc',
        );

        final json = metadata.toJson();

        expect(json['id'], 'json-test');
        expect(json['originalPath'], '/original.mp4');
        expect(json['trimmedPath'], '/trimmed.mp4');
        expect(json['startTime_seconds'], 10);
        expect(json['endTime_seconds'], 50);
        expect(json['totalDuration_seconds'], 60);
        expect(json['uploadedAt'], uploadTime.toIso8601String());
        expect(json['backendReference'], 'ref-abc');
      });

      test('handles null optional fields', () {
        final metadata = VideoMetadata(
          id: 'json-test',
          originalPath: '/original.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        final json = metadata.toJson();

        expect(json['trimmedPath'], isNull);
        expect(json['endTime_seconds'], isNull);
        expect(json['uploadedAt'], isNull);
        expect(json['backendReference'], isNull);
      });

      test('converts Duration to seconds', () {
        final metadata = VideoMetadata(
          id: 'test',
          originalPath: '/video.mp4',
          startTime: const Duration(minutes: 2, seconds: 30),
          endTime: const Duration(minutes: 5, seconds: 15),
          totalDuration: const Duration(minutes: 10),
        );

        final json = metadata.toJson();

        expect(json['startTime_seconds'], 150); // 2:30
        expect(json['endTime_seconds'], 315); // 5:15
        expect(json['totalDuration_seconds'], 600); // 10:00
      });

      test('converts DateTime to ISO 8601 string', () {
        final uploadTime = DateTime(2024, 1, 15, 14, 30, 45);
        final metadata = VideoMetadata(
          id: 'test',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
        );

        final json = metadata.toJson();

        expect(json['uploadedAt'], uploadTime.toIso8601String());
      });
    });

    group('fromJson', () {
      test('deserializes all fields correctly', () {
        final uploadTimeStr = DateTime(2024, 1, 15, 10, 30).toIso8601String();
        final json = {
          'id': 'from-json-test',
          'originalPath': '/original.mp4',
          'trimmedPath': '/trimmed.mp4',
          'startTime_seconds': 10,
          'endTime_seconds': 50,
          'totalDuration_seconds': 60,
          'uploadedAt': uploadTimeStr,
          'backendReference': 'ref-xyz',
        };

        final metadata = VideoMetadata.fromJson(json);

        expect(metadata.id, 'from-json-test');
        expect(metadata.originalPath, '/original.mp4');
        expect(metadata.trimmedPath, '/trimmed.mp4');
        expect(metadata.startTime, const Duration(seconds: 10));
        expect(metadata.endTime, const Duration(seconds: 50));
        expect(metadata.totalDuration, const Duration(seconds: 60));
        expect(metadata.uploadedAt, DateTime.parse(uploadTimeStr));
        expect(metadata.backendReference, 'ref-xyz');
      });

      test('handles null optional fields', () {
        final json = {
          'id': 'minimal-test',
          'originalPath': '/video.mp4',
          'trimmedPath': null,
          'startTime_seconds': 0,
          'endTime_seconds': null,
          'totalDuration_seconds': 60,
          'uploadedAt': null,
          'backendReference': null,
        };

        final metadata = VideoMetadata.fromJson(json);

        expect(metadata.trimmedPath, isNull);
        expect(metadata.endTime, isNull);
        expect(metadata.uploadedAt, isNull);
        expect(metadata.backendReference, isNull);
      });

      test('converts seconds to Duration', () {
        final json = {
          'id': 'test',
          'originalPath': '/video.mp4',
          'startTime_seconds': 150,
          'endTime_seconds': 315,
          'totalDuration_seconds': 600,
        };

        final metadata = VideoMetadata.fromJson(json);

        expect(metadata.startTime, const Duration(minutes: 2, seconds: 30));
        expect(metadata.endTime, const Duration(minutes: 5, seconds: 15));
        expect(metadata.totalDuration, const Duration(minutes: 10));
      });

      test('parses ISO 8601 DateTime string', () {
        final uploadTime = DateTime(2024, 1, 15, 14, 30, 45);
        final json = {
          'id': 'test',
          'originalPath': '/video.mp4',
          'startTime_seconds': 0,
          'totalDuration_seconds': 60,
          'uploadedAt': uploadTime.toIso8601String(),
        };

        final metadata = VideoMetadata.fromJson(json);

        expect(metadata.uploadedAt, uploadTime);
      });
    });

    group('JSON roundtrip', () {
      test('maintains data integrity through serialization cycle', () {
        final uploadTime = DateTime(2024, 1, 15, 10, 30);
        final original = VideoMetadata(
          id: 'roundtrip-test',
          originalPath: '/original.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
          backendReference: 'ref-roundtrip',
        );

        final json = original.toJson();
        final restored = VideoMetadata.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.originalPath, original.originalPath);
        expect(restored.trimmedPath, original.trimmedPath);
        expect(restored.startTime, original.startTime);
        expect(restored.endTime, original.endTime);
        expect(restored.totalDuration, original.totalDuration);
        expect(restored.uploadedAt, original.uploadedAt);
        expect(restored.backendReference, original.backendReference);
      });

      test('maintains data with null optional fields', () {
        final original = VideoMetadata(
          id: 'minimal-roundtrip',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        final json = original.toJson();
        final restored = VideoMetadata.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.originalPath, original.originalPath);
        expect(restored.trimmedPath, isNull);
        expect(restored.startTime, Duration.zero);
        expect(restored.endTime, isNull);
        expect(restored.totalDuration, original.totalDuration);
        expect(restored.uploadedAt, isNull);
        expect(restored.backendReference, isNull);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        final uploadTime = DateTime(2024, 1, 15);
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
          backendReference: 'ref-123',
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
          backendReference: 'ref-123',
        );

        expect(metadata1, equals(metadata2));
        expect(metadata1.hashCode, equals(metadata2.hashCode));
      });

      test('different IDs are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'id-1',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'id-2',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('different originalPaths are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video1.mp4',
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video2.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('different trimmedPaths are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed1.mp4',
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed2.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('different startTimes are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 5),
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 10),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('different endTimes are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          endTime: const Duration(seconds: 50),
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          endTime: const Duration(seconds: 55),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('different totalDurations are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 120),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });

      test('null and non-null trimmedPath are not equal', () {
        final metadata1 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed.mp4',
          totalDuration: const Duration(seconds: 60),
        );
        final metadata2 = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata1, isNot(equals(metadata2)));
      });
    });

    group('edge cases', () {
      test('handles very large duration values', () {
        final metadata = VideoMetadata(
          id: 'large-duration',
          originalPath: '/long-video.mp4',
          totalDuration: const Duration(hours: 24),
        );

        expect(metadata.totalDuration.inHours, 24);
        expect(metadata.trimmedDuration.inHours, 24);

        final json = metadata.toJson();
        expect(json['totalDuration_seconds'], 86400);

        final restored = VideoMetadata.fromJson(json);
        expect(restored.totalDuration, const Duration(hours: 24));
      });

      test('handles zero duration', () {
        final metadata = VideoMetadata(
          id: 'zero-duration',
          originalPath: '/empty.mp4',
          totalDuration: Duration.zero,
        );

        expect(metadata.totalDuration, Duration.zero);
        expect(metadata.trimmedDuration, Duration.zero);
        expect(metadata.isTrimmed, isFalse);
      });

      test('handles startTime equals endTime', () {
        final metadata = VideoMetadata(
          id: 'equal-times',
          originalPath: '/video.mp4',
          startTime: const Duration(seconds: 30),
          endTime: const Duration(seconds: 30),
          totalDuration: const Duration(seconds: 60),
        );

        expect(metadata.trimmedDuration, Duration.zero);
        expect(metadata.isTrimmed, isTrue);
      });

      test('toString includes meaningful information', () {
        final metadata = VideoMetadata(
          id: 'test-id',
          originalPath: '/video.mp4',
          trimmedPath: '/trimmed.mp4',
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 55),
          totalDuration: const Duration(seconds: 60),
          backendReference: 'ref-123',
        );

        final string = metadata.toString();

        expect(string, contains('test-id'));
        expect(string, contains('/video.mp4'));
        expect(string, contains('trimmed'));
        expect(string, contains('uploaded'));
      });

      test('handles DateTime with microseconds precision', () {
        final uploadTime = DateTime(2024, 1, 15, 10, 30, 45, 123, 456);
        final metadata = VideoMetadata(
          id: 'precise-time',
          originalPath: '/video.mp4',
          totalDuration: const Duration(seconds: 60),
          uploadedAt: uploadTime,
        );

        final json = metadata.toJson();
        final restored = VideoMetadata.fromJson(json);

        // ISO 8601 string preserves microseconds
        expect(restored.uploadedAt, uploadTime);
      });
    });
  });
}
