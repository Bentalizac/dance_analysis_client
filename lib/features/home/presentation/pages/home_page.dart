import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme.dart';
import '../widgets/navigation_card.dart';

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
              NavigationCard(
                icon: Icons.upload_file,
                title: 'Upload',
                subtitle: 'Upload a practice video for analysis',
                onTap: () => context.go('/upload'),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              NavigationCard(
                icon: Icons.rate_review,
                title: 'Review',
                subtitle: 'Review your analysis results',
                onTap: () {
                  // TODO: Implement review page
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Coming soon')));
                },
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              NavigationCard(
                icon: Icons.history,
                title: 'History',
                subtitle: 'View past uploads and progress',
                onTap: () => context.go('/history'),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),

              NavigationCard(
                icon: Icons.person,
                title: 'Profile',
                subtitle: 'Manage your account settings',
                onTap: () => context.go('/profile'),
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

              NavigationCard(
                icon: Icons.science,
                title: 'Demo Results',
                subtitle: 'View sample analysis results',
                onTap: () => context.push('/demo'),
                color: AppDesignSystem.accentBlue.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
