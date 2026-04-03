import 'package:flutter/material.dart';
import '../../../../shared/design_system/theme.dart';

/// Reusable navigation card widget for home page features
class NavigationCard extends StatelessWidget {
  const NavigationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: colorScheme.outline, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 32),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
