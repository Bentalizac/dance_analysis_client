import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/session_access_response.dart';
import '../../../../generated/api/models/session_invite_lookup_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/services/auth_service.dart';
import '../../data/session_invites_data_source.dart';

enum _Phase { loadingPreview, preview, accepting, accepted, error }

/// Standalone page for accepting a session invite via token.
///
/// Public route — no auth required to land here. The page calls the
/// unauthenticated [SessionInvitesDataSource.lookupInvite] endpoint first to
/// show invite details, then:
///
/// - **Unauthenticated**: shows "Log In" / "Create Account" buttons that
///   redirect to `/login?from=<this path>`. On return the page reloads and
///   the accept button is shown.
/// - **Authenticated**: shows an explicit "Accept Invitation" button.
///
/// Accessed via `/accept-session-invite/:token`.
class AcceptSessionInvitePage extends StatefulWidget {
  const AcceptSessionInvitePage({super.key, required this.token});

  final String token;

  @override
  State<AcceptSessionInvitePage> createState() =>
      _AcceptSessionInvitePageState();
}

class _AcceptSessionInvitePageState extends State<AcceptSessionInvitePage> {
  _Phase _phase = _Phase.loadingPreview;
  SessionInviteLookupResponse? _preview;
  SessionAccessResponse? _access;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() async {
    setState(() {
      _phase = _Phase.loadingPreview;
      _errorMessage = null;
    });

    try {
      final ds = context.read<SessionInvitesDataSource>();
      final preview = await ds.lookupInvite(widget.token);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _phase = _Phase.preview;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _accept() async {
    setState(() {
      _phase = _Phase.accepting;
      _errorMessage = null;
    });

    try {
      final ds = context.read<SessionInvitesDataSource>();
      final access = await ds.acceptInvite(widget.token);
      if (!mounted) return;
      setState(() {
        _access = access;
        _phase = _Phase.accepted;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.message;
      });
    }
  }

  void _goToLogin() {
    final from = Uri.encodeComponent('/accept-session-invite/${widget.token}');
    context.go('/login?from=$from');
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthService>().isAuthenticated;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invitation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
          child: switch (_phase) {
            _Phase.loadingPreview => _buildLoading('Loading invitation...'),
            _Phase.accepting => _buildLoading('Accepting invitation...'),
            _Phase.preview => _buildPreview(
              colorScheme,
              textTheme,
              isAuthenticated,
            ),
            _Phase.accepted => _buildAccepted(colorScheme, textTheme),
            _Phase.error => _buildError(colorScheme, textTheme),
          },
        ),
      ),
    );
  }

  Widget _buildLoading(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text(message),
      ],
    );
  }

  Widget _buildPreview(
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isAuthenticated,
  ) {
    final preview = _preview!;
    final roleLabel =
        preview.role[0].toUpperCase() + preview.role.substring(1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mail_outline, size: 64, color: colorScheme.primary),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text("You've been invited", style: textTheme.headlineSmall),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          "You've been invited to join ${preview.routineName} as $roleLabel.",
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesignSystem.spacingLg),
        if (isAuthenticated) ...[
          ElevatedButton(
            onPressed: _accept,
            child: const Text('Accept Invitation'),
          ),
        ] else ...[
          ElevatedButton(
            onPressed: _goToLogin,
            child: const Text('Log In to Accept'),
          ),
          const SizedBox(height: AppDesignSystem.spacingSm),
          OutlinedButton(
            onPressed: _goToLogin,
            child: const Text('Create Account'),
          ),
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(
            'New to DanceNote? Select "Create Account" and use the sign-up toggle.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildAccepted(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 64, color: AppDesignSystem.success),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text('Invite accepted!', style: textTheme.titleLarge),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          'You now have access to the routine.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesignSystem.spacingLg),
        ElevatedButton(
          onPressed: () => context.go('/routines'),
          child: const Text('Go to Routines'),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text(
          _errorMessage ?? 'Invite is invalid or expired.',
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
    );
  }
}
