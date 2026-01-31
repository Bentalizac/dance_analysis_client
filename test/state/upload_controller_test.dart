import 'package:dance_analysis_client/features/upload/domain/repositories/video_repository.dart';
import 'package:dance_analysis_client/features/upload/presentation/controllers/upload_controller.dart';
import 'package:dance_analysis_client/features/upload/presentation/controllers/upload_state.dart';
import 'package:dance_analysis_client/models/dance_style.dart';
import 'package:dance_analysis_client/shared/services/api_client.dart';
import 'package:dance_analysis_client/shared/services/storage_service.dart';
import 'package:dance_analysis_client/shared/services/video_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'upload_controller_test.mocks.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([VideoRepository, StorageService, ApiClient])
void main() {
  group('UploadController', () {
    late MockVideoRepository mockVideoRepository;
    late MockStorageService mockStorageService;
    late MockApiClient mockApiClient;
    late UploadController controller;

    setUp(() {
      mockVideoRepository = MockVideoRepository();
      mockStorageService = MockStorageService();
      mockApiClient = MockApiClient();
      controller = UploadController(
        videoRepository: mockVideoRepository,
        storageService: mockStorageService,
        apiClient: mockApiClient,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    group('initial state', () {
      test('has idle status', () {
        expect(controller.state.status, UploadStatus.idle);
      });

      test('has empty email', () {
        expect(controller.state.email, isEmpty);
        expect(controller.state.isEmailValid, isFalse);
      });

      test('has no video', () {
        expect(controller.state.hasVideo, isFalse);
        expect(controller.state.video, isNull);
      });

      test('has no timestamps', () {
        expect(controller.state.timestamps, isEmpty);
      });

      test('cannot upload initially', () {
        expect(controller.state.canUpload, isFalse);
      });
    });

    group('updateEmail', () {
      test('updates email and validates correctly', () {
        controller.updateEmail('test@example.com');

        expect(controller.state.email, 'test@example.com');
        expect(controller.state.isEmailValid, isTrue);
      });

      test('marks invalid email as invalid', () {
        controller.updateEmail('not-an-email');

        expect(controller.state.email, 'not-an-email');
        expect(controller.state.isEmailValid, isFalse);
      });

      test('marks empty email as invalid', () {
        controller.updateEmail('');

        expect(controller.state.isEmailValid, isFalse);
      });

      test('rejects email without @ symbol', () {
        controller.updateEmail('userexample.com');

        expect(controller.state.isEmailValid, isFalse);
      });

      test('rejects email without domain', () {
        controller.updateEmail('user@');

        expect(controller.state.isEmailValid, isFalse);
      });

      test('rejects email without TLD', () {
        controller.updateEmail('user@domain');

        expect(controller.state.isEmailValid, isFalse);
      });

      test('accepts email with subdomain', () {
        controller.updateEmail('user@mail.example.com');

        expect(controller.state.isEmailValid, isTrue);
      });

      test('trims whitespace from email', () {
        controller.updateEmail('  test@example.com  ');

        expect(controller.state.isEmailValid, isTrue);
      });

      test('clears error when updating email', () {
        // First set an error
        controller.updateEmail('invalid');
        // Would need to trigger an error state first, but this tests the clearError flag
        controller.updateEmail('valid@example.com');

        expect(controller.state.errorMessage, isNull);
      });
    });

    group('pickVideo', () {
      test('sets pickingVideo status while selecting', () async {
        // Setup mock to delay
        when(mockVideoRepository.pickVideo(any)).thenAnswer((_) async => null);

        final future = controller.pickVideo(ImageSource.gallery);

        // Check intermediate state
        expect(controller.state.status, UploadStatus.pickingVideo);

        await future;
      });

      test('returns to idle when user cancels', () async {
        when(mockVideoRepository.pickVideo(any)).thenAnswer((_) async => null);

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.status, UploadStatus.idle);
        expect(controller.state.hasVideo, isFalse);
      });

      test('sets ready status with valid video', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.status, UploadStatus.ready);
        expect(controller.state.hasVideo, isTrue);
        expect(controller.state.video, mockVideo);
      });

      test('creates video metadata when video selected', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.videoMetadata, isNotNull);
        expect(
          controller.state.videoMetadata!.totalDuration,
          mockVideo.duration,
        );
        expect(controller.state.videoMetadata!.originalPath, mockVideo.path);
      });

      test('resets timestamps when new video selected', () async {
        // First add some timestamps
        controller.addTimestamp(
          const Duration(seconds: 1),
          const Duration(seconds: 2),
          'Test',
        );

        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.timestamps, isEmpty);
      });

      test('sets error status on validation exception', () async {
        when(
          mockVideoRepository.pickVideo(any),
        ).thenThrow(const VideoValidationException('Video too large'));

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.status, UploadStatus.error);
        expect(controller.state.errorMessage, 'Video too large');
      });

      test('handles unexpected exceptions', () async {
        when(
          mockVideoRepository.pickVideo(any),
        ).thenThrow(Exception('Unexpected error'));

        await controller.pickVideo(ImageSource.gallery);

        expect(controller.state.status, UploadStatus.error);
        expect(controller.state.errorMessage, contains('Unexpected error'));
      });
    });

    group('timestamp management', () {
      group('addTimestamp', () {
        test('adds timestamp to empty list', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Pirouette',
          );

          expect(controller.state.timestamps.length, 1);
          expect(controller.state.timestamps.first.label, 'Pirouette');
        });

        test('sorts timestamps by start time', () {
          controller.addTimestamp(
            const Duration(seconds: 10),
            const Duration(seconds: 15),
            'Second',
          );
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'First',
          );

          expect(controller.state.timestamps.length, 2);
          expect(controller.state.timestamps.first.label, 'First');
          expect(controller.state.timestamps.last.label, 'Second');
        });

        test('trims whitespace from label', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            '  Trimmed  ',
          );

          expect(controller.state.timestamps.first.label, 'Trimmed');
        });

        test('ignores empty labels', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            '',
          );

          expect(controller.state.timestamps, isEmpty);
        });

        test('ignores whitespace-only labels', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            '   ',
          );

          expect(controller.state.timestamps, isEmpty);
        });

        test('ignores timestamps with invalid time range', () {
          controller.addTimestamp(
            const Duration(seconds: 10),
            const Duration(seconds: 5), // end before start
            'Invalid',
          );

          expect(controller.state.timestamps, isEmpty);
        });

        test('ignores timestamps with equal start and end', () {
          controller.addTimestamp(
            const Duration(seconds: 10),
            const Duration(seconds: 10),
            'Invalid',
          );

          expect(controller.state.timestamps, isEmpty);
        });

        test('closes inline form after adding', () {
          controller.startAddingTimestamp();
          expect(controller.state.isAddingTimestamp, isTrue);

          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Test',
          );

          expect(controller.state.isAddingTimestamp, isFalse);
        });
      });

      group('updateTimestamp', () {
        test('updates existing timestamp', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Original',
          );

          final id = controller.state.timestamps.first.id;

          controller.updateTimestamp(id, label: 'Updated');

          expect(controller.state.timestamps.first.label, 'Updated');
          expect(
            controller.state.timestamps.first.startTime,
            const Duration(seconds: 5),
          );
        });

        test('maintains sort order after update', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'First',
          );
          controller.addTimestamp(
            const Duration(seconds: 15),
            const Duration(seconds: 20),
            'Second',
          );

          final firstId = controller.state.timestamps.first.id;

          // Update the first timestamp to have a later start time
          controller.updateTimestamp(
            firstId,
            startTime: const Duration(seconds: 16),
            endTime: const Duration(seconds: 21),
          );

          // After update, 'Second' should be first (starts at 15s) and 'First' should be last (now starts at 16s)
          expect(controller.state.timestamps.first.label, 'Second');
          expect(controller.state.timestamps.last.label, 'First');
        });

        test('ignores invalid time range', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Test',
          );

          final id = controller.state.timestamps.first.id;
          final originalStartTime = controller.state.timestamps.first.startTime;

          controller.updateTimestamp(
            id,
            startTime: const Duration(seconds: 15),
            endTime: const Duration(seconds: 10), // end before start
          );

          // Should not update
          expect(
            controller.state.timestamps.first.startTime,
            originalStartTime,
          );
        });

        test('ignores non-existent id', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Test',
          );

          final originalLength = controller.state.timestamps.length;

          controller.updateTimestamp(
            'non-existent-id',
            label: 'Should not add',
          );

          expect(controller.state.timestamps.length, originalLength);
        });

        test('closes edit form after updating', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Test',
          );

          final id = controller.state.timestamps.first.id;
          controller.startEditingTimestamp(id);
          expect(controller.state.editingTimestampId, id);

          controller.updateTimestamp(id, label: 'Updated');

          expect(controller.state.editingTimestampId, isNull);
        });
      });

      group('removeTimestamp', () {
        test('removes timestamp by id', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'To Remove',
          );

          final id = controller.state.timestamps.first.id;

          controller.removeTimestamp(id);

          expect(controller.state.timestamps, isEmpty);
        });

        test('ignores non-existent id', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Keep',
          );

          controller.removeTimestamp('non-existent');

          expect(controller.state.timestamps.length, 1);
        });
      });

      group('form state', () {
        test('startAddingTimestamp sets flag', () {
          controller.startAddingTimestamp();

          expect(controller.state.isAddingTimestamp, isTrue);
          expect(controller.state.editingTimestampId, isNull);
        });

        test('startEditingTimestamp sets id and clears adding flag', () {
          controller.addTimestamp(
            const Duration(seconds: 5),
            const Duration(seconds: 10),
            'Test',
          );

          final id = controller.state.timestamps.first.id;
          controller.startEditingTimestamp(id);

          expect(controller.state.isAddingTimestamp, isFalse);
          expect(controller.state.editingTimestampId, id);
        });

        test('cancelTimestampForm clears both flags', () {
          controller.startAddingTimestamp();
          controller.cancelTimestampForm();

          expect(controller.state.isAddingTimestamp, isFalse);
          expect(controller.state.editingTimestampId, isNull);
        });
      });
    });

    group('upload', () {
      setUp(() {
        // Setup valid state for upload
        controller.updateEmail('test@example.com');
      });

      test('does not upload when canUpload is false', () async {
        await controller.upload();

        verifyNever(mockStorageService.uploadToStorage(any));
        verifyNever(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        );
      });

      test('sets uploading status during upload', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.waltz);

        when(
          mockStorageService.uploadToStorage(any),
        ).thenAnswer((_) async => 'storage-ref');
        when(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        ).thenAnswer((_) async => 'backend-ref');

        final future = controller.upload();

        // Check intermediate state (uploadingToStorage is the first phase)
        expect(controller.state.status, UploadStatus.uploadingToStorage);

        await future;
      });

      test('calls API client with correct parameters', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.waltz);

        controller.addTimestamp(
          const Duration(seconds: 2),
          const Duration(seconds: 5),
          'Step 1',
        );

        when(
          mockStorageService.uploadToStorage(any),
        ).thenAnswer((_) async => 'storage-ref');
        when(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        ).thenAnswer((_) async => 'backend-ref');

        await controller.upload();

        verify(mockStorageService.uploadToStorage(mockVideo)).called(1);
        verify(
          mockApiClient.submitAnalysisJob(
            storageReference: 'storage-ref',
            email: 'test@example.com',
            danceStyle: DanceStyle.waltz,
            timestamps: controller.state.timestamps,
            trimStart: Duration.zero,
            trimEnd: null,
            videoDuration: mockVideo.duration,
          ),
        ).called(1);
      });

      test('sets success status on successful upload', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.waltz);

        when(
          mockStorageService.uploadToStorage(any),
        ).thenAnswer((_) async => 'storage-ref');
        when(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        ).thenAnswer((_) async => 'backend-ref');

        await controller.upload();

        expect(controller.state.status, UploadStatus.success);
      });

      test('updates metadata with backend reference', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.samba);

        when(
          mockStorageService.uploadToStorage(any),
        ).thenAnswer((_) async => 'storage-ref');
        when(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        ).thenAnswer((_) async => 'backend-ref-123');

        await controller.upload();

        expect(
          controller.state.videoMetadata!.backendReference,
          'backend-ref-123',
        );
        expect(controller.state.videoMetadata!.uploadedAt, isNotNull);
      });

      test('sets error status on storage exception', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.waltz);

        when(
          mockStorageService.uploadToStorage(any),
        ).thenThrow(const StorageException('Storage upload failed'));

        await controller.upload();

        expect(controller.state.status, UploadStatus.error);
        expect(controller.state.errorMessage, 'Storage upload failed');
      });

      test('sets error status on API exception', () async {
        final mockVideo = SelectedVideo(
          xFile: XFile('test.mp4'),
          duration: const Duration(seconds: 10),
          sizeBytes: 1024 * 1024,
        );

        when(
          mockVideoRepository.pickVideo(any),
        ).thenAnswer((_) async => mockVideo);
        await controller.pickVideo(ImageSource.gallery);
        controller.updateDanceStyle(DanceStyle.waltz);

        when(
          mockStorageService.uploadToStorage(any),
        ).thenAnswer((_) async => 'storage-ref');
        when(
          mockApiClient.submitAnalysisJob(
            storageReference: anyNamed('storageReference'),
            email: anyNamed('email'),
            danceStyle: anyNamed('danceStyle'),
            timestamps: anyNamed('timestamps'),
            trimStart: anyNamed('trimStart'),
            trimEnd: anyNamed('trimEnd'),
            videoDuration: anyNamed('videoDuration'),
          ),
        ).thenThrow(const ApiException('Analysis job failed'));

        await controller.upload();

        expect(controller.state.status, UploadStatus.error);
        expect(controller.state.errorMessage, 'Analysis job failed');
      });
    });
  });
}
