import 'package:flutter/material.dart';

import '../../../../models/dance_style.dart';
import '../../../../shared/design_system/theme.dart';

/// Dialog for creating a new routine + session within a group context.
///
/// Collects routine title and dance style, then calls [onSubmit] which
/// handles the two-step create: routine → session.
class CreateSessionInGroupDialog extends StatefulWidget {
  const CreateSessionInGroupDialog({super.key, required this.onSubmit});

  /// Called with (title, danceId). Returns true on success.
  final Future<bool> Function(String title, String danceId) onSubmit;

  @override
  State<CreateSessionInGroupDialog> createState() =>
      _CreateSessionInGroupDialogState();
}

class _CreateSessionInGroupDialogState
    extends State<CreateSessionInGroupDialog> {
  final _titleController = TextEditingController();
  DanceStyle? _selectedStyle;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Routine title is required.');
      return;
    }
    if (_selectedStyle == null) {
      setState(() => _error = 'Please select a dance style.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await widget.onSubmit(title, _selectedStyle!.name);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to create session.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      title: Text('New Routine Session',
          style: TextStyle(color: AppDesignSystem.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Routine Title',
              hintText: 'e.g. Waltz Competition Routine',
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          DropdownButtonFormField<DanceStyle>(
            initialValue: _selectedStyle,
            decoration: const InputDecoration(labelText: 'Dance Style'),
            dropdownColor: AppDesignSystem.backgroundMedium,
            items: DanceStyle.values
                .map((s) =>
                    DropdownMenuItem(value: s, child: Text(s.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _selectedStyle = v),
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
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).pop(),
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
