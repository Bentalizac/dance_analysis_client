import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../widgets/navigation_card.dart';

const title = "DanceNote";

/// Home page - main landing page with navigation to all features
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // On web the global nav already shows the app name; suppress the redundant AppBar.
      appBar: kIsWeb ? null : AppBar(title: const Text(title), centerTitle: true),
      body: SafeArea(
        child: WebConstrainedBody(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusSm),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.school,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppDesignSystem.spacingMd),
                      Text(
                        'Welcome to $title',
                        style: textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppDesignSystem.spacingSm),
                      Text(
                        'AI-powered dance analysis and coaching',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingLg),

                // Navigation cards — row on wide screens, column on narrow
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (kIsWeb && constraints.maxWidth >= 600) {
                      return Row(
                        children: [
                          Expanded(
                            child: NavigationCard(
                              icon: Icons.library_music,
                              title: 'Routines',
                              subtitle: 'Create and manage your routines',
                              onTap: () => context.go('/routines'),
                            ),
                          ),
                          const SizedBox(width: AppDesignSystem.spacingMd),
                          Expanded(
                            child: NavigationCard(
                              icon: Icons.group,
                              title: 'Groups',
                              subtitle: 'Collaborate with your dance partners',
                              onTap: () => context.go('/groups'),
                            ),
                          ),
                          const SizedBox(width: AppDesignSystem.spacingMd),
                          Expanded(
                            child: NavigationCard(
                              icon: Icons.person,
                              title: 'Profile',
                              subtitle: 'Manage your account settings',
                              onTap: () => context.go('/profile'),
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NavigationCard(
                          icon: Icons.library_music,
                          title: 'Routines',
                          subtitle: 'Create and manage your routines',
                          onTap: () => context.go('/routines'),
                        ),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        NavigationCard(
                          icon: Icons.group,
                          title: 'Groups',
                          subtitle: 'Collaborate with your dance partners',
                          onTap: () => context.go('/groups'),
                        ),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        NavigationCard(
                          icon: Icons.person,
                          title: 'Profile',
                          subtitle: 'Manage your account settings',
                          onTap: () => context.go('/profile'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
