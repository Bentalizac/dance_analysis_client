import 'package:flutter/material.dart';

import 'design_system.dart';
import 'home_page.dart';
import 'stub_pages.dart';
import 'upload_page.dart';

/// Main scaffold wrapper with bottom navigation bar.
///
/// Uses IndexedStack to maintain page state when switching between tabs.
/// This ensures:
/// - Each page gets proper lifecycle events (initState/dispose)
/// - State is preserved when switching tabs (e.g., video player position)
/// - PopScope works correctly for navigation guards
/// - Memory management is handled by Flutter's widget lifecycle
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.initialIndex = 0});

  /// Initial page index to display
  final int initialIndex;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  // Pages are instantiated once and reused to preserve state
  late final List<Widget> _pages;
  
  // GlobalKeys to access page state for navigation guards
  final _uploadPageKey = GlobalKey<_UploadPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const HomePage(),
      UploadPage(key: _uploadPageKey),
      const StubPage(title: 'History', icon: Icons.history),
      const StubPage(title: 'Profile', icon: Icons.person),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      // IndexedStack shows only the selected page but keeps all pages in the widget tree
      // This preserves state when switching tabs (e.g., video player state, scroll position)
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        border: Border(
          top: BorderSide(color: AppDesignSystem.dividerLight, width: 1),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
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

  /// Handle bottom navigation bar taps with navigation guards.
  ///
  /// Checks if the current page allows navigation (e.g., UploadPage may show
  /// a confirmation dialog if there are unsaved timestamps).
  Future<void> _onTabTapped(int index) async {
    if (index == _currentIndex) {
      // Tapping the same tab - could scroll to top or refresh
      return;
    }

    // Check if current page wants to block navigation
    // Currently only UploadPage (index 1) has navigation guards
    if (_currentIndex == 1) {
      final uploadState = _uploadPageKey.currentState;
      if (uploadState != null) {
        final canNavigate = await uploadState.canNavigateAway();
        if (!canNavigate) {
          return; // User cancelled navigation
        }
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }
}
