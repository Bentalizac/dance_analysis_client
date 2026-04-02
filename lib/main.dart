import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'config/routes.dart';
import 'features/dancer_slots/data/dancer_slots_data_source.dart';
import 'features/dancer_slots/presentation/controllers/dancer_slots_controller.dart';
import 'features/dances/data/dances_data_source.dart';
import 'features/dances/presentation/controllers/dances_controller.dart';
import 'features/group_invites/data/group_invites_data_source.dart';
import 'features/groups/data/groups_data_source.dart';
import 'features/groups/presentation/controllers/groups_controller.dart';
import 'features/routine_notes/data/notes_data_source.dart';
import 'features/routine_instances/data/routine_instances_data_source.dart';
import 'features/routine_instances/presentation/controllers/routine_instances_controller.dart';
import 'features/routine_videos/data/videos_data_source.dart';
import 'features/routines/data/routines_data_source.dart';
import 'features/routines/presentation/controllers/routines_controller.dart';
import 'features/slot_assignments/data/slot_assignments_data_source.dart';
import 'features/slot_assignments/presentation/controllers/slot_assignments_controller.dart';
import 'features/upload/data/video_repository.dart';
import 'shared/design_system/theme.dart';
import 'shared/services/api_service.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/video_service.dart';

void main() {
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError('Flutter Error', details.exception, details.stack);
      };

      runApp(const MyApp());
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              'Something went wrong',
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'The app encountered an error. Please restart the app.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: AppDesignSystem.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                ),
                child: Text(
                  details.exception.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
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
  const MyApp({super.key});

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

        // Data sources (global — stateless, safe to share)
        Provider<DancesDataSource>(
          create: (context) =>
              DancesDataSource(context.read<ApiService>().client),
        ),
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
        Provider<RoutineInstancesDataSource>(
          create: (context) =>
              RoutineInstancesDataSource(context.read<ApiService>().client),
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
        ChangeNotifierProvider<DancesController>(
          create: (context) =>
              DancesController(dataSource: context.read<DancesDataSource>()),
        ),
        ChangeNotifierProvider<GroupsController>(
          create: (context) =>
              GroupsController(dataSource: context.read<GroupsDataSource>()),
        ),
        ChangeNotifierProvider<RoutinesController>(
          create: (context) => RoutinesController(
            dataSource: context.read<RoutinesDataSource>(),
            dancerSlotsDataSource: context.read<DancerSlotsDataSource>(),
          ),
        ),
        ChangeNotifierProvider<RoutineInstancesController>(
          create: (context) => RoutineInstancesController(
            dataSource: context.read<RoutineInstancesDataSource>(),
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
        title: 'DanceNote',
        debugShowCheckedModeBanner: false,
        theme: AppDesignSystem.theme,
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
