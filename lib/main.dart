import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes.dart';
import 'features/dancer_slots/data/dancer_slots_data_source.dart';
import 'features/dancer_slots/presentation/controllers/dancer_slots_controller.dart';
import 'features/group_invites/data/group_invites_data_source.dart';
import 'features/groups/data/groups_data_source.dart';
import 'features/groups/presentation/controllers/groups_controller.dart';
import 'features/history/data/history_local_data_source.dart';
import 'features/history/data/history_repository.dart';
import 'features/routine_notes/data/notes_data_source.dart';
import 'features/routine_sessions/data/routine_sessions_data_source.dart';
import 'features/routine_sessions/presentation/controllers/routine_sessions_controller.dart';
import 'features/routine_videos/data/videos_data_source.dart';
import 'features/routines/data/routines_data_source.dart';
import 'features/routines/presentation/controllers/routines_controller.dart';
import 'features/slot_assignments/data/slot_assignments_data_source.dart';
import 'features/slot_assignments/presentation/controllers/slot_assignments_controller.dart';
import 'features/upload/domain/repositories/video_repository.dart';
import 'shared/design_system/theme.dart';
import 'shared/services/api_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/video_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError('Flutter Error', details.exception, details.stack);
      };

      runApp(MyApp(prefs: prefs));
    },
    (error, stack) {
      _logError('Async Error', error, stack);
    },
  );
}

void _logError(String context, Object error, StackTrace? stack) {
  debugPrint('[$context] $error');
  if (stack != null) debugPrint('Stack trace:\n$stack');
}

class _CustomErrorWidget extends StatelessWidget {
  const _CustomErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignSystem.backgroundMedium,
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppDesignSystem.errorRed),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppDesignSystem.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'The app encountered an error. Please restart the app.',
              style: AppDesignSystem.feedbackStyle
                  .copyWith(color: AppDesignSystem.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppDesignSystem.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundMedium,
                  borderRadius:
                      BorderRadius.circular(AppDesignSystem.radiusXs),
                ),
                child: Text(
                  details.exception.toString(),
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.errorRed,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core services
        Provider<VideoService>(create: (_) => VideoService()),
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<AuthService>(
          create: (context) {
            final apiService = context.read<ApiService>();
            final auth = AuthService(apiService);
            AuthServiceRegistry.instance = auth;
            return auth;
          },
        ),

        // Repositories
        ProxyProvider<VideoService, VideoRepository>(
          update: (_, videoService, _) => VideoRepository(videoService),
        ),
        Provider<HistoryLocalDataSource>(
          create: (_) => HistoryLocalDataSource(prefs),
        ),
        ProxyProvider2<HistoryLocalDataSource, ApiService, HistoryRepository>(
          update: (_, localDataSource, apiService, _) => HistoryRepository(
            localDataSource: localDataSource,
            apiService: apiService,
          ),
        ),

        // Data sources (global — stateless, safe to share)
        Provider<GroupsDataSource>(
          create: (context) =>
              GroupsDataSource(context.read<ApiService>().client),
        ),
        Provider<GroupInvitesDataSource>(
          create: (context) =>
              GroupInvitesDataSource(context.read<ApiService>().client),
        ),
        Provider<RoutinesDataSource>(
          create: (context) =>
              RoutinesDataSource(context.read<ApiService>().client),
        ),
        Provider<RoutineSessionsDataSource>(
          create: (context) =>
              RoutineSessionsDataSource(context.read<ApiService>().client),
        ),
        Provider<VideosDataSource>(
          create: (context) =>
              VideosDataSource(context.read<ApiService>().client),
        ),
        Provider<NotesDataSource>(
          create: (context) =>
              NotesDataSource(context.read<ApiService>().client),
        ),
        Provider<DancerSlotsDataSource>(
          create: (context) =>
              DancerSlotsDataSource(context.read<ApiService>().client),
        ),
        Provider<SlotAssignmentsDataSource>(
          create: (context) =>
              SlotAssignmentsDataSource(context.read<ApiService>().client),
        ),

        // Global controllers (list-level state only)
        // Note: VideosController and NotesController are scoped to
        // SessionDetailPage, not provided globally.
        ChangeNotifierProvider<GroupsController>(
          create: (context) => GroupsController(
            dataSource: context.read<GroupsDataSource>(),
          ),
        ),
        ChangeNotifierProvider<RoutinesController>(
          create: (context) => RoutinesController(
            dataSource: context.read<RoutinesDataSource>(),
          ),
        ),
        ChangeNotifierProvider<RoutineSessionsController>(
          create: (context) => RoutineSessionsController(
            dataSource: context.read<RoutineSessionsDataSource>(),
          ),
        ),
        ChangeNotifierProvider<DancerSlotsController>(
          create: (context) => DancerSlotsController(
            dataSource: context.read<DancerSlotsDataSource>(),
          ),
        ),
        ChangeNotifierProvider<SlotAssignmentsController>(
          create: (context) => SlotAssignmentsController(
            dataSource: context.read<SlotAssignmentsDataSource>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Dance Coach',
        debugShowCheckedModeBanner: false,
        theme: AppDesignSystem.darkTheme,
        routerConfig: appRouter,
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return _CustomErrorWidget(details: details);
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
