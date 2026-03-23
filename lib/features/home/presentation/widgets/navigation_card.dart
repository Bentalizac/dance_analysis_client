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
              child: Icon(icon, color: AppDesignSystem.accentPurple, size: 32),
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
}
