import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_service.dart';
import 'verify_email_screen.dart' show VerifyEmailScreen;
import 'register.dart' show RegisterScreen;
import '../home/HomeScreen.dart' show HomeScreen;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _authErrorText;
  bool _showEmailValidation = false;
  bool _showPasswordValidation = false;

  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bgTop = Color(0xFFEDE8F5);
  static const Color _darkBtn = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus && mounted) {
        setState(() => _showEmailValidation = true);
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && mounted) {
        setState(() => _showPasswordValidation = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _showEmailValidation = true;
      _showPasswordValidation = true;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authErrorText = null;
    });

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      setState(() => _authErrorText = result.errorMessage);
      return;
    }

    if (result.isEmailVerified) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        (route) => false,
      );
    }
  }

  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isFacebookLoading) return;
    setState(() {
      _isGoogleLoading = true;
      _authErrorText = null;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success) {
      _goToHome();
    } else if (result.errorMessage != null &&
        !result.errorMessage!.contains('cancelled')) {
      _showSnack(result.errorMessage!);
    }
  }

  Future<void> _signInWithFacebook() async {
    if (_isGoogleLoading || _isFacebookLoading) return;
    setState(() {
      _isFacebookLoading = true;
      _authErrorText = null;
    });

    final result = await AuthService.signInWithFacebook();

    if (!mounted) return;
    setState(() => _isFacebookLoading = false);

    if (result.success) {
      _goToHome();
    } else if (result.errorMessage != null &&
        !result.errorMessage!.contains('cancelled')) {
      _showSnack(result.errorMessage!);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    String resetEmail = _emailController.text.trim();
    final resetFormKey = GlobalKey<FormState>();
    bool isSending = false;
    bool emailSent = false;
    String? dialogError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // ── Success state ──
          if (emailSent) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.green.shade50,
                    child: Icon(
                      Icons.mark_email_read_outlined,
                      color: Colors.green.shade600,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email Sent!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A password reset link was sent to:\n$resetEmail\n\nCheck your inbox (and spam folder).',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF555555),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _darkBtn,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Form state ──
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            content: Form(
              key: resetFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your email and we\'ll send you a reset link.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: resetEmail,
                    decoration: InputDecoration(
                      hintText: 'example@gmail.com',
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF9AA4B2),
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF2F4F9),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFDDDDDD),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF2B3E5C),
                          width: 1.4,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      resetEmail = value;
                      if (dialogError != null) {
                        setDialogState(() => dialogError = null);
                      }
                    },
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Enter your email';
                      if (!RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      ).hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),

                  // Firebase error
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    isSending ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        if (resetFormKey.currentState?.validate() != true) {
                          return;
                        }

                        final email = resetEmail.trim();
                        setDialogState(() {
                          isSending = true;
                          dialogError = null;
                        });

                        try {
                          debugPrint(
                            '[ResetPassword] Sending reset email to: $email',
                          );
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );
                          debugPrint(
                            '[ResetPassword] ✅ Email sent successfully to: $email',
                          );
                          setDialogState(() {
                            isSending = false;
                            emailSent = true;
                          });
                        } on FirebaseAuthException catch (e) {
                          debugPrint(
                            '[ResetPassword] ❌ FirebaseAuthException: code=${e.code}, message=${e.message}',
                          );
                          String msg;
                          if (e.code == 'user-not-found') {
                            msg = 'No account found with this email address.';
                          } else if (e.code == 'invalid-email') {
                            msg = 'Invalid email address.';
                          } else if (e.code == 'network-request-failed') {
                            msg = 'No internet connection. Try again.';
                          } else if (e.code == 'too-many-requests') {
                            msg = 'Too many attempts. Try again later.';
                          } else if (e.code == 'operation-not-allowed') {
                            msg =
                                'Email/Password is disabled in Firebase Console.';
                          } else {
                            msg =
                                'Error (${e.code}): ${e.message ?? 'Failed to send reset email.'}';
                          }
                          setDialogState(() {
                            isSending = false;
                            dialogError = msg;
                          });
                        } catch (e) {
                          debugPrint('[ResetPassword] ❌ Unexpected error: $e');
                          setDialogState(() {
                            isSending = false;
                            dialogError =
                                'Something went wrong. Please try again.';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkBtn,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF12131C) : const Color(0xFFF2F4F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF1A1C27) : _bgTop,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/icon/image 1.png',
                        height: 230,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          height: 230,
                          child: Icon(
                            Icons.lock_person_outlined,
                            size: 120,
                            color: Color(0xFFB7BED1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Welcome ',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFF1EEF8)
                                    : const Color(0xFF10131A),
                              ),
                            ),
                            const TextSpan(
                              text: 'Back!',
                              style: TextStyle(color: _pink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Continue your calmness journey',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFA8A6B5)
                              : const Color(0xFF53637B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        hint: 'example@gmail.com',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: _showEmailValidation
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        onChanged: (_) {
                          if (_authErrorText != null) {
                            setState(() => _authErrorText = null);
                          }
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hint: 'Password',
                        icon: Icons.key_outlined,
                        obscure: _obscurePassword,
                        autovalidateMode: _showPasswordValidation
                            ? AutovalidateMode.always
                            : AutovalidateMode.disabled,
                        onChanged: (_) {
                          if (_authErrorText != null) {
                            setState(() => _authErrorText = null);
                          }
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: isDark
                                ? const Color(0xFFC6C3D3)
                                : const Color(0xFF9AA4B2),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _showResetPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFD1CEDF)
                                : const Color(0xFF3E4C65),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkBtn,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      if (_authErrorText != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _authErrorText!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? const Color(0xFF3A3B4D)
                                  : const Color(0xFFDDDDDD),
                              thickness: 1,
                              endIndent: 12,
                            ),
                          ),
                          Text(
                            'Or sign in with',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFFC6C3D3)
                                  : const Color(0xFF888888),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDark
                                  ? const Color(0xFF3A3B4D)
                                  : const Color(0xFFDDDDDD),
                              thickness: 1,
                              indent: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              onTap: (_isGoogleLoading || _isFacebookLoading)
                                  ? null
                                  : _signInWithGoogle,
                              label: 'Google',
                              faIcon: FontAwesomeIcons.google,
                              iconColor: const Color(0xFFDB4437),
                              isLoading: _isGoogleLoading,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SocialButton(
                              onTap: (_isGoogleLoading || _isFacebookLoading)
                                  ? null
                                  : _signInWithFacebook,
                              label: 'Facebook',
                              faIcon: FontAwesomeIcons.facebook,
                              iconColor: const Color(0xFF1877F2),
                              isLoading: _isFacebookLoading,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFFC6C3D3)
                                    : const Color(0xFF3E4C65),
                              ),
                              children: [
                                const TextSpan(
                                    text: 'Doesn\'t have an account? '),
                                TextSpan(
                                  text: 'Signup',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    color: isDark
                                        ? const Color(0xFFF1EEF8)
                                        : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    void Function(String)? onChanged,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    String? Function(String?)? validator,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? const Color(0xFFF1EEF8) : const Color(0xFF333333),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFFA09DB0) : const Color(0xFF8E97A6),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? const Color(0xFFAAA7B7) : const Color(0xFF9AA4B2),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2B38) : const Color(0xFFF2F4F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF45465A) : const Color(0xFF2B3E5C),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF8C88A2) : const Color(0xFF2B3E5C),
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable social login button widget for LoginScreen
// ─────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final IconData faIcon;
  final Color iconColor;
  final bool isLoading;

  const _SocialButton({
    required this.onTap,
    required this.label,
    required this.faIcon,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1A1C27) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: isDark ? const Color(0xFF2B2D3D) : const Color(0xFFEDE8F5),
        highlightColor:
            (isDark ? const Color(0xFF2B2D3D) : const Color(0xFFEDE8F5))
                .withOpacity(0.5),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: onTap == null
                  ? (isDark ? const Color(0xFF3F4153) : const Color(0xFFEEEEEE))
                  : (isDark
                      ? const Color(0xFF585A70)
                      : const Color(0xFFDDDDDD)),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              else
                FaIcon(faIcon, size: 22, color: iconColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onTap == null
                      ? const Color(0xFFAAAAAA)
                      : (isDark
                          ? const Color(0xFFF1EEF8)
                          : const Color(0xFF1A1A2E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
