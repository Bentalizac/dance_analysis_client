import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme.dart';

/// Placeholder invites tab — will show pending invites for the group
/// once a list-invites endpoint is available.
class InvitesTab extends StatelessWidget {
  const InvitesTab({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline,
                size: 64,
                color: AppDesignSystem.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text('Invite people using the + button.',
                style: AppDesignSystem.feedbackStyle
                    .copyWith(color: AppDesignSystem.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
