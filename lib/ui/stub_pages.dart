import 'package:flutter/material.dart';

import 'design_system.dart';

/// Reusable stub page for features not yet implemented.
///
/// Used as placeholder for History and Profile pages during MVP development.
/// Shows a friendly "Coming soon" message with appropriate icon.
class StubPage extends StatelessWidget {
  const StubPage({
    super.key,
    required this.title,
    this.icon = Icons.construction,
  });

  /// Page title (e.g., "History", "Profile")
  final String title;

  /// Icon to display in the placeholder
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: SafeArea(
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
                  icon,
                  size: 64,
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  '$title Page',
                  style: const TextStyle(
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
      ),
    );
  }
}
