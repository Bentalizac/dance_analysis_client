import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../shared/design_system/theme.dart';
import '../../data/group_invites_data_source.dart';

/// Dialog for inviting someone by email to a group.
///
/// On success, the backend sends an email via SES with an accept link.
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
  bool _sent = false;

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
      await ds.createInvite(widget.groupId, email: email);
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _sent = true;
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_sent) {
      return AlertDialog(
        constraints: kIsWeb ? const BoxConstraints(maxWidth: 480) : null,
        title: const Text('Invite Sent'),
        content: Text(
          'An invitation email has been sent to ${_emailController.text.trim()}.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      );
    }

    return AlertDialog(
      constraints: kIsWeb ? const BoxConstraints(maxWidth: 480) : null,
      title: const Text('Invite Member'),
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
            Text(
              _error!,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Invite'),
        ),
      ],
    );
  }
}
