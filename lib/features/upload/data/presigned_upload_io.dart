import 'dart:io';

import 'package:dio/dio.dart';

import '../presentation/controllers/upload_state.dart';

/// Native (iOS / Android / desktop) implementation of the presigned-URL PUT.
///
/// Streams the file directly off disk so the full video never has to sit
/// in memory at once.
Future<void> putVideoToPresignedUrl(
  String uploadUrl,
  SelectedVideo video, {
  void Function(int sent, int total)? onSendProgress,
}) async {
  final file = File(video.xFile.path);
  if (!await file.exists()) {
    throw const PresignedUploadException(
      'Local video file no longer exists. Please re-select the video.',
    );
  }

  final length = await file.length();
  final stream = file.openRead();

  final s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(minutes: 15),
    receiveTimeout: const Duration(minutes: 5),
  ));

  try {
    await s3Dio.put<void>(
      uploadUrl,
      data: stream,
      options: Options(
        headers: {'Content-Type': 'video/mp4', 'Content-Length': length},
        followRedirects: true,
      ),
      onSendProgress: onSendProgress,
    );
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final msg = StringBuffer('Failed to upload video to storage.');
    if (status != null) msg.write(' HTTP $status.');
    if (e.message != null) msg.write(' ${e.message}');
    if (body != null) msg.write(' Response: $body');
    throw PresignedUploadException(msg.toString());
  } catch (e) {
    throw PresignedUploadException(
      'Unexpected error while uploading to storage: $e',
    );
  } finally {
    s3Dio.close();
  }
}

class PresignedUploadException implements Exception {
  const PresignedUploadException(this.message);

  final String message;

  @override
  String toString() => 'PresignedUploadException: $message';
}
