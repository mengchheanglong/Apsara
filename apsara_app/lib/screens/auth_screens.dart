import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/form_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegisterMode = true;
  bool _isResetMode = false;
  bool _isSubmitting = false;
  String? _errorText;
  String? _successText;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _isResetMode
        ? 'Enter your email to receive a password reset link'
        : 'Appreciate, Buy & Sell Authentic Khmer Crafts';
    final primaryActionText = _isSubmitting
        ? 'Please wait...'
        : _isResetMode
            ? 'Send reset link'
            : _isRegisterMode
                ? 'Create account'
                : 'Log in';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 336),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/apsara_logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apsara',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textLight, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 22),
                  if (_isRegisterMode && !_isResetMode) ...[
                    LabeledField(
                        label: 'Your name', controller: _nameController),
                    const SizedBox(height: 10),
                  ],
                  LabeledField(label: 'Email', controller: _emailController),
                  if (!_isResetMode) ...[
                    const SizedBox(height: 10),
                    LabeledField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: true,
                    ),
                  ],
                  if (!_isRegisterMode && !_isResetMode)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  _isResetMode = true;
                                  _errorText = null;
                                  _successText = null;
                                });
                              },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(top: 4, bottom: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (_successText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _successText!,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _isSubmitting
                        ? null
                        : _isResetMode
                            ? _sendPasswordReset
                            : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text(primaryActionText,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              if (_isResetMode) {
                                _isResetMode = false;
                                _isRegisterMode = false;
                              } else {
                                _isRegisterMode = !_isRegisterMode;
                              }
                              _errorText = null;
                              _successText = null;
                            });
                          },
                    child: Text.rich(
                      TextSpan(
                        text: _isResetMode
                            ? ''
                            : _isRegisterMode
                                ? 'Already have an account? '
                                : 'Need an account? ',
                        children: [
                          TextSpan(
                            text: _isResetMode
                                ? 'Back to log in'
                                : _isRegisterMode
                                    ? 'Log in'
                                    : 'Create one',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_isRegisterMode && name.isEmpty) {
      setState(() => _errorText = 'Enter your name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'Enter your email and password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _successText = null;
    });

    try {
      if (_isRegisterMode) {
        await AuthService.instance.signUp(
          name: name,
          email: email,
          password: password,
        );
      } else {
        await AuthService.instance.signIn(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _errorText = _firebaseErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Authentication failed. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'Enter your email address.';
        _successText = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _successText = null;
    });

    try {
      await AuthService.instance.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        _successText = 'Password reset email sent to $email.';
      });
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _errorText = _firebaseErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Unable to send reset email.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email is already in use.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isRefreshing = false;
  bool _isSending = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 336),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/apsara_logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to ${widget.user.email ?? 'your email address'}. Confirm it before entering the app.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed:
                        _isRefreshing ? null : _refreshVerificationStatus,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text(
                        _isRefreshing ? 'Checking...' : 'I verified my email'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isSending ? null : _resendVerificationEmail,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(_isSending
                        ? 'Sending...'
                        : 'Resend verification email'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async => AuthService.instance.signOut(),
                    child: const Text(
                      'Use another account',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshVerificationStatus() async {
    setState(() {
      _isRefreshing = true;
      _message = null;
    });

    try {
      final user = await AuthService.instance.reloadCurrentUser();
      if (!mounted) {
        return;
      }
      if (user != null &&
          AuthService.instance.requiresEmailVerification(user)) {
        setState(() {
          _message = 'Email not verified yet. Check your inbox or spam folder.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Verification email sent again.';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = error.message ?? 'Unable to resend verification email.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
}
