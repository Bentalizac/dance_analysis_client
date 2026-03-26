import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/routine_videos/data/videos_data_source.dart';
import '../../../../features/upload/domain/repositories/video_repository.dart';
import '../../../../features/upload/presentation/controllers/upload_controller.dart';
import '../../../../features/upload/presentation/controllers/video_player_manager.dart';
import '../../../../features/upload/presentation/widgets/upload_page_content.dart';
import '../../../../shared/design_system/theme.dart';

/// Session-scoped video upload page.
///
/// Provides a fresh [UploadController] scoped to [sessionId].
class SessionUploadPage extends StatelessWidget {
  const SessionUploadPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VideoPlayerManager()),
          ChangeNotifierProvider(
            create: (context) => UploadController(
              sessionId: sessionId,
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
