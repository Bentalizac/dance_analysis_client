import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/home/presentation/pages/home_page.dart';
import '../features/upload/presentation/controllers/upload_controller.dart';
import '../features/upload/presentation/pages/upload_page.dart';
import '../shared/design_system/theme.dart';
import '../shared/widgets/discard_confirmation_dialog.dart';
import '../ui/demo_results_page.dart';

/// App routing configuration using go_router.
///
/// This provides:
/// - Declarative routing
/// - Type-safe navigation
/// - Deep linking support
/// - Navigation guards
/// - Route-level state management
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return _MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/upload',
          name: 'upload',
          pageBuilder: (context, state) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const UploadPage(),
            );
          },
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: _StubPage(title: 'History', icon: Icons.history),
          ),
        ),
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
    // Routes outside the main scaffold (full screen)
    GoRoute(
      path: '/demo',
      name: 'demo',
      builder: (context, state) => const DemoResultsPage(),
    ),
  ],
);

/// Main scaffold with bottom navigation bar using ShellRoute.
///
/// ShellRoute keeps the scaffold persistent across navigation, maintaining
/// the bottom nav state. The child widget changes based on the current route.
class _MainScaffold extends StatelessWidget {
  const _MainScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
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
          selectedItemColor: AppDesignSystem.accentBlue,
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
              icon: Icon(Icons.upload_file_outlined),
              activeIcon: Icon(Icons.upload_file),
              label: 'Upload',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
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
    if (path.startsWith('/upload')) return 1;
    if (path.startsWith('/history')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0; // home
  }

  Future<void> _onTabTapped(BuildContext context, int index) async {
    final currentLocation = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndexFromPath(currentLocation);

    // Same tab tapped - no action
    if (index == currentIndex) return;

    // Check if leaving upload page with unsaved work
    if (currentLocation.startsWith('/upload')) {
      try {
        final controller = context.read<UploadController?>();
        if (controller != null && controller.hasUnsavedWork) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => DiscardConfirmationDialog(
              timestampCount: controller.state.timestamps.length,
            ),
          );

          if (confirmed != true) return; // User cancelled
        }
      } catch (e) {
        // Controller not available, allow navigation
      }
    }

    // Navigate to selected tab
    if (!context.mounted) return;
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/upload');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

/// Temporary stub page for features not yet implemented
class _StubPage extends StatelessWidget {
  const _StubPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
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
