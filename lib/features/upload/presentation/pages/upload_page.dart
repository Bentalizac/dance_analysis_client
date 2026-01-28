import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/services/api_client.dart';
import '../../domain/repositories/video_repository.dart';
import '../controllers/upload_controller.dart';
import '../controllers/video_player_manager.dart';
import '../widgets/upload_page_content.dart';

/// Upload page - refactored to use provider pattern for state management.
///
/// This page:
/// - Provides UploadController and VideoPlayerManager via providers
/// - Delegates all UI rendering to UploadPageContent
/// - Handles controller initialization with proper dependency injection
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Video player manager for playback controls
        ChangeNotifierProvider(
          create: (_) => VideoPlayerManager(),
        ),
        // Upload controller for business logic
        ChangeNotifierProvider(
          create: (context) => UploadController(
            videoRepository: context.read<VideoRepository>(),
            apiClient: context.read<ApiClient>(),
          ),
        ),
      ],
      child: const UploadPageContent(),
    );
  }
}
