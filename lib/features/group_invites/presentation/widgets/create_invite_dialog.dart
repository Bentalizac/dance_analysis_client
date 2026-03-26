import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../shared/design_system/theme.dart';
import '../../data/group_invites_data_source.dart';

/// Dialog for inviting someone by email to a group.
///
/// Since there's no email service yet, the invite token is shown
/// in the UI so the creator can share it manually.
class CreateInviteDialog extends StatefulWidget {
  const CreateInviteDialog({super.key, required this.groupId});

  final String groupId;

  @override
  State<CreateInviteDialog> createState() => _CreateInviteDialogState();
}

class _CreateInviteDialogState extends State<CreateInviteDialog> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  String? _createdToken;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final ds = context.read<GroupInvitesDataSource>();
      final invite =
          await ds.createInvite(widget.groupId, email: email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _createdToken = invite.token;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // After successful creation, show the token
    if (_createdToken != null) {
      return AlertDialog(
        backgroundColor: AppDesignSystem.backgroundMedium,
        title: Text('Invite Sent',
            style: TextStyle(color: AppDesignSystem.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share this token with the invitee:',
                style: TextStyle(color: AppDesignSystem.textSecondary)),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius:
                    BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(_createdToken!,
                        style: AppDesignSystem.smallTextStyle
                            .copyWith(color: AppDesignSystem.textPrimary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _createdToken!));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Token copied')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done')),
        ],
      );
    }

    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      title: Text('Invite Member',
          style: TextStyle(color: AppDesignSystem.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'partner@example.com',
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(_error!,
                style: AppDesignSystem.smallTextStyle
                    .copyWith(color: AppDesignSystem.errorRed)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: TextStyle(color: AppDesignSystem.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send Invite'),
        ),
      ],
    );
  }
}
