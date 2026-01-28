import 'package:dance_analysis_client/shared/services/video_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VideoConfig', () {
    test('has correct max duration', () {
      expect(VideoConfig.maxDuration, const Duration(seconds: 20));
    });

    test('has correct max size in bytes', () {
      expect(VideoConfig.maxSizeBytes, 100 * 1024 * 1024); // 100 MB
    });

    test('max size MB matches max size bytes', () {
      const expectedMB = 100.0;
      expect(VideoConfig.maxSizeMB, expectedMB);
      expect(VideoConfig.maxSizeBytes, (expectedMB * 1024 * 1024).toInt());
    });

    test('has correct recommended step duration', () {
      expect(VideoConfig.recommendedStepDuration, const Duration(seconds: 15));
    });

    test('recommended duration is less than max duration', () {
      expect(
        VideoConfig.recommendedStepDuration < VideoConfig.maxDuration,
        isTrue,
      );
    });
  });
}
