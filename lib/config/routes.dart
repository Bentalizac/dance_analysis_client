import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/group_invites/presentation/pages/accept_invite_page.dart';
import '../features/groups/presentation/pages/group_detail_page.dart';
import '../features/groups/presentation/pages/groups_list_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/results/presentation/pages/demo_results_page.dart';
import '../features/routine_sessions/presentation/pages/session_detail_page.dart';
import '../features/routine_sessions/presentation/pages/session_upload_page.dart';
import '../features/routines/presentation/pages/routine_detail_page.dart';
import '../features/routines/presentation/pages/routines_list_page.dart';
import '../shared/design_system/theme.dart';
import '../shared/services/auth_service.dart';

/// Global key to access navigator state for upload guard.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Callback to check if user can leave the session upload page.
/// Set by SessionUploadPage when mounted.
Future<bool> Function()? _uploadPageCanLeaveCallback;

/// Register callback for upload page navigation guard.
void registerUploadPageGuard(Future<bool> Function()? callback) {
  _uploadPageCanLeaveCallback = callback;
}

/// Simple singleton-like access to AuthService for router-level guards.
///
/// go_router redirects do not receive a BuildContext, so we can't use the
/// usual Provider lookup there.
class AuthServiceRegistry {
  AuthServiceRegistry._();

  static AuthService? instance;
}

/// App routing configuration using go_router.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final auth = AuthServiceRegistry.instance;
    final isLoggedIn = auth?.isAuthenticated ?? false;
    final goingTo = state.uri.path;

    if (goingTo == '/login') return null;

    final isProtected =
        goingTo == '/profile' ||
        goingTo.startsWith('/routines') ||
        goingTo.startsWith('/sessions') ||
        goingTo.startsWith('/groups');

    if (!isLoggedIn && isProtected) {
      final from = Uri.encodeComponent(state.uri.toString());
      return '/login?from=$from';
    }

    return null;
  },
  routes: [
    // Public / standalone routes (outside main scaffold)
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        final from = state.uri.queryParameters['from'];
        return LoginPage(initialRedirectPath: from);
      },
    ),
    GoRoute(
      path: '/accept-invite/:token',
      name: 'acceptInvite',
      builder: (context, state) =>
          AcceptInvitePage(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/demo',
      name: 'demo',
      builder: (context, state) => const DemoResultsPage(),
    ),

    // Main scaffold with persistent bottom navigation
    ShellRoute(
      builder: (context, state, child) => _MainScaffold(child: child),
      routes: [
        // Home
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const HomePage()),
        ),

        // Routines (top-level, user-owned)
        GoRoute(
          path: '/routines',
          name: 'routines',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const RoutinesListPage(),
          ),
          routes: [
            GoRoute(
              path: ':routineId',
              name: 'routineDetail',
              builder: (context, state) => RoutineDetailPage(
                routineId: state.pathParameters['routineId']!,
              ),
            ),
          ],
        ),

        // Groups (session-centric — sessions tab replaces routines tab)
        GoRoute(
          path: '/groups',
          name: 'groups',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const GroupsListPage(),
          ),
          routes: [
            GoRoute(
              path: ':groupId',
              name: 'groupDetail',
              builder: (context, state) =>
                  GroupDetailPage(groupId: state.pathParameters['groupId']!),
            ),
          ],
        ),

        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: _StubPage(title: 'Profile', icon: Icons.person),
          ),
        ),
      ],
    ),

    // Session routes (full-screen, outside shell)
    GoRoute(
      path: '/sessions/:sessionId',
      name: 'sessionDetail',
      builder: (context, state) =>
          SessionDetailPage(sessionId: state.pathParameters['sessionId']!),
      routes: [
        GoRoute(
          path: 'upload',
          name: 'sessionUpload',
          builder: (context, state) =>
              SessionUploadPage(sessionId: state.pathParameters['sessionId']!),
        ),
      ],
    ),
  ],
);

/// Main scaffold with bottom navigation.
class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndexFromPath(currentLocation);

    return Container(
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        border: Border(
          top: BorderSide(color: AppDesignSystem.dividerLight, width: 1),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTabTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppDesignSystem.backgroundMedium,
          selectedItemColor: AppDesignSystem.mainAccent,
          unselectedItemColor: AppDesignSystem.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'Routines',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int _getIndexFromPath(String path) {
    if (path.startsWith('/routines')) return 1;
    if (path.startsWith('/groups')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0; // home
  }

  Future<void> _onTabTapped(BuildContext context, int index) async {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndexFromPath(currentLocation);

    if (index == currentIndex) return;

    // Guard: check if leaving session upload with unsaved work
    if (currentLocation.startsWith('/sessions') &&
        currentLocation.endsWith('/upload') &&
        _uploadPageCanLeaveCallback != null) {
      final canLeave = await _uploadPageCanLeaveCallback!();
      if (!canLeave) return;
    }

    if (!context.mounted) return;

    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/routines');
      case 2:
        context.go('/groups');
      case 3:
        context.go('/profile');
    }
  }
}

/// Temporary stub page for features not yet implemented.
class _StubPage extends StatelessWidget {
  const _StubPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(AppDesignSystem.spacingXl),
          padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
          decoration: BoxDecoration(
            color: AppDesignSystem.backgroundMedium,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
            border: Border.all(color: AppDesignSystem.dividerLight, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
              Text(
                '$title Page',
                style: TextStyle(
                  color: AppDesignSystem.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingSm),
              Text(
                'Coming soon',
                style: AppDesignSystem.feedbackStyle.copyWith(
                  color: AppDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
