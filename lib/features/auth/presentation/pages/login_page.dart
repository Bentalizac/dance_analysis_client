import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
import '../../../../shared/services/auth_service.dart';

/// Email + password authentication page using backend AuthService.
///
/// Supports:
/// - Login mode
/// - Registration mode (with username)
/// - Optional redirect back to a protected route after successful auth
class LoginPage extends StatefulWidget {
  final String? initialRedirectPath;

  const LoginPage({super.key, this.initialRedirectPath});

  static const routePath = '/login';
  static const routeName = 'login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorText;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isSubmitting) return;

    setState(() {
      _errorText = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final auth = context.read<AuthService>();

      if (_isRegisterMode) {
        await auth.register(
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) return;

      final redirectPath = widget.initialRedirectPath;
      if (redirectPath != null && redirectPath.isNotEmpty) {
        context.go(redirectPath);
      } else {
        context.pop(true);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorText = e.message;
      });
    } catch (_) {
      setState(() {
        _errorText = _isRegisterMode
            ? 'Registration failed. Please try again.'
            : 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _onCancel() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context),
        const SizedBox(height: AppDesignSystem.spacingXl),
        _buildFormCard(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Icon(Icons.lock_outline, size: 64, color: colorScheme.primary),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text(
          _isRegisterMode ? 'Create your account' : 'Welcome back',
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          _isRegisterMode
              ? 'Sign up to upload videos and manage your routines.'
              : 'Sign in to upload videos and manage your routines.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEmailField(context),
            const SizedBox(height: AppDesignSystem.spacingMd),
            if (_isRegisterMode) ...[
              _buildUsernameField(context),
              const SizedBox(height: AppDesignSystem.spacingMd),
            ],
            _buildPasswordField(context),
            if (_errorText != null) ...[
              const SizedBox(height: AppDesignSystem.spacingSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorText!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDesignSystem.spacingLg),
            _buildButtons(context),
            const SizedBox(height: AppDesignSystem.spacingSm),
            _buildToggleAuthMode(context),
            const SizedBox(height: AppDesignSystem.spacingMd),
            _buildFutureOauthHint(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _emailController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email';
        }
        final email = value.trim();
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
        if (!emailRegex.hasMatch(email)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _passwordController,
      enabled: !_isSubmitting,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildUsernameField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _usernameController,
      enabled: !_isSubmitting,
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'your_name',
        prefixIcon: Icon(
          Icons.person_outline,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      validator: (value) {
        if (!_isRegisterMode) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a username';
        }
        if (value.trim().length < 3) {
          return 'Username must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              side: BorderSide(color: colorScheme.outline),
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingSm,
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacingMd),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingSm,
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isRegisterMode ? 'Create account' : 'Sign in'),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleAuthMode(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final primaryText = _isRegisterMode
        ? 'Already have an account?'
        : 'New here?';
    final actionText = _isRegisterMode
        ? 'Sign in instead'
        : 'Create an account';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          primaryText,
          style: textTheme.bodySmall,
        ),
        const SizedBox(width: AppDesignSystem.spacingXs),
        GestureDetector(
          onTap: _isSubmitting
              ? null
              : () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                    _errorText = null;
                  });
                },
          child: Text(
            actionText,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFutureOauthHint(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          "In future versions you'll be able to sign in or register with\n"
          'Apple or Google for a faster experience.',
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
