import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
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
  bool _accepted = false;

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
      await ds.acceptInvite(widget.token);
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _accepted = true;
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
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
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
              : _accepted
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 64, color: Colors.green),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        Text('Invite accepted!',
                            style: TextStyle(
                                color: AppDesignSystem.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppDesignSystem.spacingLg),
                        ElevatedButton(
                          onPressed: () => context.go('/groups'),
                          child: const Text('Go to Groups'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: AppDesignSystem.errorRed),
                        const SizedBox(height: AppDesignSystem.spacingMd),
                        Text(
                            _error ??
                                'Invite is invalid or expired.',
                            style: AppDesignSystem.feedbackStyle.copyWith(
                                color: AppDesignSystem.textSecondary),
                            textAlign: TextAlign.center),
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
