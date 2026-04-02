import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/group_invites/presentation/pages/accept_invite_page.dart';
import '../features/groups/presentation/pages/group_detail_page.dart';
import '../features/groups/presentation/pages/groups_list_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/routine_instances/presentation/pages/instance_detail_page.dart';
import '../features/routine_instances/presentation/pages/instance_upload_page.dart';
import '../features/routine_videos/presentation/pages/video_detail_page.dart';
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
        goingTo.startsWith('/instances') ||
        goingTo.startsWith('/groups') ||
        goingTo.startsWith('/accept-invite');

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

    // Instance routes (full-screen, outside shell)
    GoRoute(
      path: '/instances/:instanceId',
      name: 'instanceDetail',
      builder: (context, state) =>
          InstanceDetailPage(instanceId: state.pathParameters['instanceId']!),
      routes: [
        GoRoute(
          path: 'upload',
          name: 'instanceUpload',
          builder: (context, state) =>
              InstanceUploadPage(instanceId: state.pathParameters['instanceId']!),
        ),
        GoRoute(
          path: 'videos/:videoId',
          name: 'videoDetail',
          builder: (context, state) => VideoDetailPage(
            instanceId: state.pathParameters['instanceId']!,
            videoId: state.pathParameters['videoId']!,
          ),
        ),
      ],
    ),
  ],
);

/// Main scaffold with platform-appropriate navigation.
///
/// On web a top [AppBar] is used; on native the standard bottom nav bar.
class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: _buildWebTopNav(context),
        body: child,
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildWebTopNav(BuildContext context) {
    final currentIndex = _getIndexFromPath(GoRouterState.of(context).uri.path);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        'DanceNote',
        style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
      ),
      actions: [
        for (int i = 0; i < _kNavItems.length; i++)
          _WebNavButton(
            item: _kNavItems[i],
            isActive: currentIndex == i,
            onTap: () => _onTabTapped(context, i),
          ),
        const SizedBox(width: AppDesignSystem.spacingMd),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: colorScheme.outline),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndexFromPath(currentLocation);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onTabTapped(context, index),
          type: BottomNavigationBarType.fixed,
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
    if (currentLocation.startsWith('/instances') &&
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

// ---------------------------------------------------------------------------
// Shared nav item data
// ---------------------------------------------------------------------------

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _kNavItems = [
  _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
  _NavItem(
    label: 'Routines',
    icon: Icons.library_music_outlined,
    activeIcon: Icons.library_music,
  ),
  _NavItem(
    label: 'Groups',
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  ),
];

// ---------------------------------------------------------------------------
// Web-only nav button
// ---------------------------------------------------------------------------

class _WebNavButton extends StatelessWidget {
  const _WebNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        isActive ? item.activeIcon : item.icon,
        size: 18,
        color: color,
      ),
      label: Text(
        item.label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: -0.08,
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacingMd,
          vertical: AppDesignSystem.spacingSm,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Temporary stub page for features not yet implemented.
class _StubPage extends StatelessWidget {
  const _StubPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(AppDesignSystem.spacingXl),
          padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
            border: Border.all(color: colorScheme.outline, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
              Text('$title Page', style: textTheme.headlineSmall),
              const SizedBox(height: AppDesignSystem.spacingSm),
              Text(
                'Coming soon',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
