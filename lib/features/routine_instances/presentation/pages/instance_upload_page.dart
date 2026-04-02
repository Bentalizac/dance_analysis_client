import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/routine_videos/data/videos_data_source.dart';
import '../../../../features/upload/data/video_repository.dart';
import '../../../../features/upload/presentation/controllers/upload_controller.dart';
import '../../../../features/upload/presentation/controllers/video_player_manager.dart';
import '../../../../features/upload/presentation/widgets/upload_page_content.dart';

/// Instance-scoped video upload page.
///
/// Provides a fresh [UploadController] scoped to [instanceId].
class InstanceUploadPage extends StatelessWidget {
  const InstanceUploadPage({super.key, required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VideoPlayerManager()),
          ChangeNotifierProvider(
            create: (context) => UploadController(
              sessionId: instanceId,
              videoRepository: context.read<VideoRepository>(),
              videosDataSource: context.read<VideosDataSource>(),
            ),
          ),
        ],
        child: const UploadPageContent(),
      ),
    );
  }
}
