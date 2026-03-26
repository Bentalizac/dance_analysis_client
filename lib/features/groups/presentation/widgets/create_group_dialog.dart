import 'package:flutter/material.dart';

import '../../../../shared/design_system/theme.dart';

/// Dialog for creating a new group.
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key, required this.onSubmit});

  /// Called with (name, description). Returns true on success.
  final Future<bool> Function(String name, String? description) onSubmit;

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Group name is required.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final desc = _descController.text.trim();
    final success =
        await widget.onSubmit(name, desc.isEmpty ? null : desc);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to create group. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      title: Text('Create Group',
          style: TextStyle(color: AppDesignSystem.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'e.g. Waltz Practice Partners',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What is this group for?',
            ),
            maxLines: 2,
            textInputAction: TextInputAction.done,
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
              : const Text('Create'),
        ),
      ],
    );
  }
}
