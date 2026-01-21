import 'package:flutter/material.dart';
import 'design_system.dart';
import 'demo_results_page.dart';

/// Home page - main landing page with navigation to all features
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(title: const Text('Dance Coach'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Navigation cards
              _buildNavigationCard(
                context: context,
                icon: Icons.upload_file,
                title: 'Upload',
                subtitle: 'Upload a practice video for analysis',
                onTap: () => _navigateToStub(context, 'Upload'),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              _buildNavigationCard(
                context: context,
                icon: Icons.rate_review,
                title: 'Review',
                subtitle: 'Review your analysis results',
                onTap: () => _navigateToStub(context, 'Review'),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              _buildNavigationCard(
                context: context,
                icon: Icons.history,
                title: 'History',
                subtitle: 'View past uploads and progress',
                onTap: () => _navigateToStub(context, 'History'),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              _buildNavigationCard(
                context: context,
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your account settings',
                onTap: () => _navigateToStub(context, 'Profile'),
              ),
              const SizedBox(height: AppDesignSystem.spacingXl),

              // Demo section
              Divider(color: AppDesignSystem.dividerLight),
              const SizedBox(height: AppDesignSystem.spacingMd),
              Text(
                'Development',
                style: AppDesignSystem.feedbackStyle.copyWith(
                  color: AppDesignSystem.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              _buildNavigationCard(
                context: context,
                icon: Icons.science,
                title: 'Demo Results',
                subtitle: 'View sample analysis results',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DemoResultsPage(),
                    ),
                  );
                },
                color: AppDesignSystem.accentBlue.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: color ?? AppDesignSystem.backgroundMedium,
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
              child: Icon(icon, color: AppDesignSystem.accentBlue, size: 32),
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

  void _navigateToStub(BuildContext context, String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _StubPage(pageName: pageName)),
    );
  }
}

/// Simple stub page for features not yet implemented
class _StubPage extends StatelessWidget {
  const _StubPage({required this.pageName});

  final String pageName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(title: Text(pageName)),
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
                '$pageName Page',
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
