import 'package:flutter/material.dart';
import 'design_system.dart';
import 'demo_results_page.dart';

/// Main scaffold wrapper with bottom navigation bar
/// Provides consistent navigation across all main pages
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.initialIndex = 0});

  /// Initial page index to display
  final int initialIndex;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      body: _getPage(_currentIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const _HomePageContent();
      case 1:
        return const _StubPageContent(title: 'Upload');
      case 2:
        return const _StubPageContent(title: 'History');
      case 3:
        return const _StubPageContent(title: 'Profile');
      default:
        return const _HomePageContent();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        border: Border(
          top: BorderSide(color: AppDesignSystem.dividerLight, width: 1),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
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
}

/// Home page content without its own Scaffold
class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App title
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingMd,
              ),
              child: Text(
                'Dance Coach',
                style: TextStyle(
                  color: AppDesignSystem.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Welcome section
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: AppDesignSystem.accentBlue,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  Text(
                    'Welcome to Dance Coach',
                    style: TextStyle(
                      color: AppDesignSystem.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDesignSystem.spacingSm),
                  Text(
                    'AI-powered dance analysis and coaching',
                    style: AppDesignSystem.feedbackStyle.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),

            // Quick actions
            Text(
              'Quick Actions',
              style: AppDesignSystem.timestampStyle.copyWith(
                color: AppDesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),

            _buildActionCard(
              context: context,
              icon: Icons.science,
              title: 'View Demo',
              subtitle: 'See sample analysis results',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DemoResultsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),

            _buildActionCard(
              context: context,
              icon: Icons.video_library,
              title: 'Recent Videos',
              subtitle: 'Coming soon',
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: AppDesignSystem.backgroundMedium,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: AppDesignSystem.dividerLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundDark,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                icon,
                color: onTap != null
                    ? AppDesignSystem.accentBlue
                    : AppDesignSystem.textDisabled,
                size: 32,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppDesignSystem.timestampStyle.copyWith(
                      color: AppDesignSystem.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Text(
                    subtitle,
                    style: AppDesignSystem.feedbackStyle.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                color: AppDesignSystem.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// Stub page content for features not yet implemented
class _StubPageContent extends StatelessWidget {
  const _StubPageContent({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
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
                color: AppDesignSystem.textSecondary.withOpacity(0.5),
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
