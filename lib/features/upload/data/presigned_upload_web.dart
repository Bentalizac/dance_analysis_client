import 'package:dio/dio.dart';

import '../presentation/controllers/upload_state.dart';

/// Web implementation of the presigned-URL PUT.
///
/// Reads the file into memory via XFile.readAsBytes() — dart:io is not
/// available on web so file streaming is not possible. The 100 MB / 20 s
/// caps enforced by VideoService keep this from becoming a problem in practice.
Future<void> putVideoToPresignedUrl(
  String uploadUrl,
  SelectedVideo video, {
  void Function(int sent, int total)? onSendProgress,
}) async {
  final bytes = await video.xFile.readAsBytes();

  final s3Dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(minutes: 15),
    receiveTimeout: const Duration(minutes: 5),
  ));

  try {
    await s3Dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': 'video/mp4',
          'Content-Length': bytes.length,
        },
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
