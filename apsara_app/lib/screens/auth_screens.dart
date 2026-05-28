import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';

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
  bool _acceptedTerms = false;
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
  // Keeps the form in a single screen by switching between register, login, and reset modes.
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
      backgroundColor: AppColors.surface,
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
                    style: TextStyle(
                        color: AppColors.textLight, fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 22),
                  if (_isRegisterMode && !_isResetMode) ...[
                    _AuthTextField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _AuthTextField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: _isResetMode
                        ? TextInputAction.done
                        : TextInputAction.next,
                  ),
                  if (!_isResetMode) ...[
                    const SizedBox(height: 10),
                    _AuthTextField(
                      label: 'Password',
                      controller: _passwordController,
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                    if (_isRegisterMode) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isSubmitting
                            ? null
                            : () => setState(
                                  () => _acceptedTerms = !_acceptedTerms,
                                ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: Checkbox(
                                value: _acceptedTerms,
                                onChanged: _isSubmitting
                                    ? null
                                    : (value) => setState(
                                          () => _acceptedTerms = value ?? false,
                                        ),
                                activeColor: AppColors.primary,
                                checkColor: Colors.white,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: AppColors.textLight,
                                  width: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                  children: [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'terms',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'privacy policy',
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      style: TextStyle(
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
                      style: TextStyle(
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
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  if (!_isResetMode) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      button: true,
                      label: 'Continue with Google',
                      child: Opacity(
                        opacity: _isSubmitting ? 0.55 : 1,
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _signInWithGoogle,
                            borderRadius: BorderRadius.circular(28),
                            child: SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google_g_mark.png',
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!_isResetMode)
                          Text(
                            _isRegisterMode
                                ? 'Already have an account? '
                                : 'Need an account? ',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isSubmitting ? null : _switchAuthMode,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              _isResetMode
                                  ? 'Back to log in'
                                  : _isRegisterMode
                                      ? 'Log in'
                                      : 'Create one',
                              style: TextStyle(
                                color: _isSubmitting
                                    ? AppColors.textLight
                                    : AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _switchAuthMode() {
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
  }

  // Validates form input, then delegates either registration or login to AuthService.
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_isRegisterMode && name.isEmpty) {
      setState(() => _errorText = 'Enter your name.');
      return;
    }
    if (_isRegisterMode && !_acceptedTerms) {
      setState(() => _errorText = 'Agree to the terms to create an account.');
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
      AppLogger.warn('Auth failed', error);
      if (mounted) {
        setState(() => _errorText = _firebaseErrorMessage(error));
      }
    } catch (error, stackTrace) {
      AppLogger.error('Auth failed', error, stackTrace);
      if (mounted) {
        setState(() => _errorText = 'Authentication failed. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Starts the native Google account picker, then signs into Firebase with the returned Google token.
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _successText = null;
    });

    try {
      await AuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      AppLogger.warn('Google auth failed', error);
      if (!mounted) {
        return;
      }
      if (error.code == 'sign_in_canceled') {
        setState(() => _errorText = null);
      } else {
        setState(() => _errorText = _firebaseErrorMessage(error));
      }
    } catch (error, stackTrace) {
      AppLogger.error('Google auth failed', error, stackTrace);
      if (mounted) {
        setState(() => _errorText = 'Google sign-in failed. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Sends a password-reset email and updates the inline success/error message.
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
      AppLogger.warn('Password reset failed', error);
      if (mounted) {
        setState(() => _errorText = _firebaseErrorMessage(error));
      }
    } catch (error, stackTrace) {
      AppLogger.error('Password reset failed', error, stackTrace);
      if (mounted) {
        setState(() => _errorText = 'Unable to send reset email.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Converts FirebaseAuth error codes into short UI-friendly messages.
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
      case 'sign_in_canceled':
        return 'Google sign-in was canceled.';
      case 'google_sign_in_not_configured':
        return 'Google sign-in is not fully configured.';
      case 'google_sign_in_failed':
        return 'Google sign-in failed. Try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  final _focusNode = FocusNode();

  bool get _isActive => _focusNode.hasFocus;

  bool get _hasText => widget.controller.text.isNotEmpty;

  bool get _showIcon => !_focusNode.hasFocus && widget.controller.text.isEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFieldChanged);
    widget.controller.addListener(_handleFieldChanged);
  }

  @override
  void didUpdateWidget(covariant _AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleFieldChanged);
      widget.controller.addListener(_handleFieldChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFieldChanged);
    widget.controller.removeListener(_handleFieldChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final floatingLabel = widget.label.toLowerCase();
    const activeLabelStyle = TextStyle(
      color: AppColors.textLight,
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      height: 1,
    );
    final labelPainter = TextPainter(
      text: TextSpan(text: floatingLabel, style: activeLabelStyle),
      textDirection: Directionality.of(context),
    )..layout();

    return SizedBox(
      height: 66,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _isActive ? 1 : 0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        builder: (context, progress, child) {
          const activeLabelLeft = 26.0;
          final labelLeft =
              _lerpDouble(_showIcon ? 50 : 18, activeLabelLeft, progress);
          final labelTop = _lerpDouble(25, 15, progress);
          final labelSize = _lerpDouble(14, 10.5, progress);
          final labelOpacity = _isActive || !_hasText ? 1.0 : progress;
          final labelColor = Color.lerp(
            AppColors.textSecondary,
            AppColors.textLight,
            progress,
          )!;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                top: 8,
                child: CustomPaint(
                  painter: _AuthFieldBorderPainter(
                    progress: progress,
                    labelLeft: activeLabelLeft,
                    labelWidth: labelPainter.width,
                  ),
                ),
              ),
              Positioned.fill(
                top: 8,
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  cursorColor: AppColors.primary,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: _showIcon
                        ? Icon(
                            widget.icon,
                            color: AppColors.textSecondary,
                            size: 22,
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(
                      _showIcon ? 0 : 18,
                      _isActive ? 20 : 18,
                      18,
                      _isActive ? 11 : 13,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: labelLeft,
                top: _showIcon ? 29 : labelTop,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: labelOpacity,
                    child: Text(
                      progress > 0.08 ? floatingLabel : widget.label,
                      style: TextStyle(
                        color: labelColor,
                        fontSize: labelSize,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
  }
}

class _AuthFieldBorderPainter extends CustomPainter {
  const _AuthFieldBorderPainter({
    required this.progress,
    required this.labelLeft,
    required this.labelWidth,
  });

  final double progress;
  final double labelLeft;
  final double labelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.lerp(AppColors.text, AppColors.primary, progress)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = _lerpDouble(1.25, 1.8, progress)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (progress <= 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(6),
        ),
        paint,
      );
      return;
    }

    final tabPadding = _lerpDouble(12, 7, progress);
    final labelRight = labelLeft + labelWidth + tabPadding * 2;
    final topY = _lerpDouble(0, 13, progress);
    final bumpTop = _lerpDouble(0, 3, progress);
    final sideXOffset = 5.0;
    final path = Path()
      ..moveTo(6, topY)
      ..lineTo(labelLeft - tabPadding - 3, topY)
      ..cubicTo(
        labelLeft - tabPadding,
        topY,
        labelLeft - tabPadding,
        bumpTop,
        labelLeft - tabPadding + sideXOffset,
        bumpTop,
      )
      ..lineTo(labelRight - sideXOffset, bumpTop)
      ..cubicTo(
        labelRight + sideXOffset,
        bumpTop,
        labelRight + sideXOffset,
        topY,
        labelRight + 8,
        topY,
      )
      ..lineTo(size.width - 6, topY)
      ..quadraticBezierTo(size.width, topY, size.width, topY + 6)
      ..lineTo(size.width, size.height - 6)
      ..quadraticBezierTo(size.width, size.height, size.width - 6, size.height)
      ..lineTo(6, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - 6)
      ..lineTo(0, topY + 6)
      ..quadraticBezierTo(0, topY, 6, topY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AuthFieldBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.labelLeft != labelLeft ||
        oldDelegate.labelWidth != labelWidth;
  }

  double _lerpDouble(double start, double end, double t) {
    return start + (end - start) * t;
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
  // Lets the user confirm verification progress without leaving the app.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
                    style: TextStyle(
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
                      side: BorderSide(color: AppColors.border),
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
                      style: TextStyle(
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

  // Reloads the current Firebase user so emailVerified reflects the latest backend state.
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

  // Requests another verification email for users who missed the first one.
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
