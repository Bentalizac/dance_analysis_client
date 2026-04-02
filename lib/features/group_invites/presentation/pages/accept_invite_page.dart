import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/group_membership_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../data/group_invites_data_source.dart';

/// Standalone page for accepting a group invite via token.
///
/// Accessed via `/accept-invite/:token`.
class AcceptInvitePage extends StatefulWidget {
  const AcceptInvitePage({super.key, required this.token});

  final String token;

  @override
  State<AcceptInvitePage> createState() => _AcceptInvitePageState();
}

class _AcceptInvitePageState extends State<AcceptInvitePage> {
  bool _isAccepting = false;
  String? _error;
  GroupMembershipResponse? _membership;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _accept());
  }

  Future<void> _accept() async {
    setState(() {
      _isAccepting = true;
      _error = null;
    });

    try {
      final ds = context.read<GroupInvitesDataSource>();
      final membership = await ds.acceptInvite(widget.token);
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _membership = membership;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invite')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
          child: _isAccepting
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Accepting invite...'),
                  ],
                )
              : _membership != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 64,
                          color: AppDesignSystem.success,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        Text(
                          'Invite accepted!',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingLg),
                        ElevatedButton(
                          onPressed: () =>
                              context.go('/groups/${_membership!.groupId}'),
                          child: const Text('Go to Group'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        Text(
                          _error ?? 'Invite is invalid or expired.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDesignSystem.spacingLg),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
