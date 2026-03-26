import 'package:flutter/material.dart';

import '../../../../generated/api/models/routine_session_response.dart';
import '../../../../shared/design_system/theme.dart';

/// Card displaying a session's label and date.
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session, this.onTap});

  final RoutineSessionResponse session;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = session.label ?? 'Session ${session.id.substring(0, 8)}';
    final date = session.createdAt;
    final dateStr = '${date.month}/${date.day}/${date.year}';

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
              padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                Icons.video_library,
                color: AppDesignSystem.mainAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppDesignSystem.feedbackStyle.copyWith(
                      color: AppDesignSystem.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: AppDesignSystem.smallTextStyle.copyWith(
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
