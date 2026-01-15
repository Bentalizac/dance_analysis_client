import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/video_service.dart';
import '../state/upload_controller.dart';
import '../state/upload_state.dart';

/// Single-screen MVP UI for selecting/recording a video, entering an email,
/// and uploading to the backend.
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final UploadController _controller;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _controller = UploadController(
      videoService: VideoService(),
      apiClient: ApiClient(),
    );
    _emailController = TextEditingController();
    _emailController.addListener(() {
      _controller.updateEmail(_emailController.text);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload practice video'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    errorText:
                        state.email.isEmpty || state.isEmailValid ? null : 'Enter a valid email',
                  ),
                ),
                const SizedBox(height: 16),
                // On web, only show file picker since camera recording is not well supported
                if (kIsWeb)
                  ElevatedButton.icon(
                    onPressed: _isBusy(state)
                        ? null
                        : () => _controller.pickVideo(ImageSource.gallery),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Choose video file'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isBusy(state)
                              ? null
                              : () => _controller.pickVideo(ImageSource.camera),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Record video'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isBusy(state)
                              ? null
                              : () => _controller.pickVideo(ImageSource.gallery),
                          icon: const Icon(Icons.video_library),
                          label: const Text('Choose existing'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                _VideoSummary(state: state),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.canUpload && !_isBusy(state)
                      ? () async {
                          await _controller.upload();
                        }
                      : null,
                  child: const Text('Upload'),
                ),
                const SizedBox(height: 16),
                _StatusText(state: state),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const Spacer(),
                const Text(
                  // TODO: Replace with a more polished explanation/help section.
                  'This is a minimal MVP. After upload, a coach will analyze your video server-side.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isBusy(UploadState state) {
    return switch (state.status) {
      UploadStatus.uploading || UploadStatus.processing => true,
      _ => false,
    };
  }
}

class _VideoSummary extends StatelessWidget {
  const _VideoSummary({required this.state});

  final UploadState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasVideo) {
      return const Text('No video selected yet.');
    }

    final video = state.video!;
    final durationSeconds = video.duration.inSeconds;
    final sizeMb = (video.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected video',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text('Duration: ~${durationSeconds}s'),
        Text('Size: ${sizeMb}MB'),
      ],
    );
  }
}

class _StatusText extends StatelessWidget {
  const _StatusText({required this.state});

  final UploadState state;

  @override
  Widget build(BuildContext context) {
    Widget content = Text('Status: ${state.statusLabel}');
    if (state.status == UploadStatus.uploading ||
        state.status == UploadStatus.processing) {
      content = Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(state.statusLabel),
        ],
      );
    }
    return content;
  }
}
