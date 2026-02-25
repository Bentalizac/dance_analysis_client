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
        // Router-level guard flow: send user back to originally requested route.
        context.go(redirectPath);
      } else {
        // Local flow (e.g. upload picker gating): pop with success flag.
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
    context.pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
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
        _buildHeader(),
        const SizedBox(height: AppDesignSystem.spacingXl),
        _buildFormCard(context),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.lock_outline, size: 64, color: AppDesignSystem.accentBlue),
        const SizedBox(height: AppDesignSystem.spacingMd),
        Text(
          _isRegisterMode ? 'Create your account' : 'Welcome back',
          style: TextStyle(
            color: AppDesignSystem.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          _isRegisterMode
              ? 'Sign up to upload videos, view your history,\n'
                    'and manage your profile.'
              : 'Sign in to upload videos, view your history,\n'
                    'and manage your profile.',
          style: AppDesignSystem.feedbackStyle.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingLg),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: AppDesignSystem.dividerLight),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEmailField(),
            const SizedBox(height: AppDesignSystem.spacingMd),
            if (_isRegisterMode) ...[
              _buildUsernameField(),
              const SizedBox(height: AppDesignSystem.spacingMd),
            ],
            _buildPasswordField(),
            if (_errorText != null) ...[
              const SizedBox(height: AppDesignSystem.spacingSm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _errorText!,
                  style: AppDesignSystem.feedbackStyle.copyWith(
                    color: AppDesignSystem.errorRed,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppDesignSystem.spacingLg),
            _buildButtons(context),
            const SizedBox(height: AppDesignSystem.spacingSm),
            _buildToggleAuthMode(),
            const SizedBox(height: AppDesignSystem.spacingMd),
            _buildFutureOauthHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: AppDesignSystem.textPrimary),
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'you@example.com',
        labelStyle: TextStyle(color: AppDesignSystem.textSecondary),
        hintStyle: TextStyle(
          color: AppDesignSystem.textSecondary.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: AppDesignSystem.textSecondary,
        ),
        filled: true,
        fillColor: AppDesignSystem.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.accentBlue),
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

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: !_isSubmitting,
      obscureText: _obscurePassword,
      style: TextStyle(color: AppDesignSystem.textPrimary),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: AppDesignSystem.textSecondary),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppDesignSystem.textSecondary,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppDesignSystem.textSecondary,
          ),
        ),
        filled: true,
        fillColor: AppDesignSystem.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.accentBlue),
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

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppDesignSystem.textSecondary,
              side: BorderSide(color: AppDesignSystem.dividerLight),
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
              backgroundColor: AppDesignSystem.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingSm,
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppDesignSystem.textPrimary,
                      ),
                    ),
                  )
                : Text(_isRegisterMode ? 'Create account' : 'Sign in'),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      enabled: !_isSubmitting,
      style: TextStyle(color: AppDesignSystem.textPrimary),
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'your_name',
        labelStyle: TextStyle(color: AppDesignSystem.textSecondary),
        hintStyle: TextStyle(
          color: AppDesignSystem.textSecondary.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(
          Icons.person_outline,
          color: AppDesignSystem.textSecondary,
        ),
        filled: true,
        fillColor: AppDesignSystem.backgroundDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.dividerLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          borderSide: BorderSide(color: AppDesignSystem.accentBlue),
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

  Widget _buildToggleAuthMode() {
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
          style: AppDesignSystem.smallTextStyle.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
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
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: AppDesignSystem.accentBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFutureOauthHint() {
    return Column(
      children: [
        Divider(color: AppDesignSystem.dividerLight),
        const SizedBox(height: AppDesignSystem.spacingSm),
        Text(
          'In future versions you’ll be able to sign in or register with\n'
          'Apple or Google for a faster experience.',
          style: AppDesignSystem.smallTextStyle.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
