import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../auth/auth_service.dart';
import 'login.dart' show LoginScreen;
import 'verify_email_screen.dart' show VerifyEmailScreen;
import '../home/HomeScreen.dart' show HomeScreen;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _showValidationErrors = false;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _termsErrorText;
  String? _formErrorText;

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _bgTop = Color(0xFFEDE8F5);
  static const Color _darkBtn = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // ── Navigate to Home and clear the stack ──
  void _goToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  // ── Show a bottom snackbar for social errors ──
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EMAIL / PASSWORD REGISTER
  // ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _showValidationErrors = true;
      _emailErrorText = null;
      _passwordErrorText = null;
      _termsErrorText = null;
      _formErrorText = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      setState(() => _termsErrorText = 'Please agree to terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        (route) => false,
      );
    } else {
      final msg = result.errorMessage ?? 'Something went wrong.';
      if (msg.toLowerCase().contains('email')) {
        setState(() => _emailErrorText = msg);
        _formKey.currentState?.validate();
      } else if (msg.toLowerCase().contains('password')) {
        setState(() => _passwordErrorText = msg);
        _formKey.currentState?.validate();
      } else {
        setState(() => _formErrorText = msg);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ─────────────────────────────────────────────────────────────
  Future<void> _signUpWithGoogle() async {
    if (_isGoogleLoading || _isFacebookLoading) return;
    setState(() => _isGoogleLoading = true);

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success) {
      _goToHome();
    } else if (result.errorMessage != null &&
        !result.errorMessage!.contains('cancelled')) {
      _showError(result.errorMessage!);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FACEBOOK SIGN-IN
  // ─────────────────────────────────────────────────────────────
  Future<void> _signUpWithFacebook() async {
    if (_isGoogleLoading || _isFacebookLoading) return;
    setState(() => _isFacebookLoading = true);

    final result = await AuthService.signInWithFacebook();

    if (!mounted) return;
    setState(() => _isFacebookLoading = false);

    if (result.success) {
      _goToHome();
    } else if (result.errorMessage != null &&
        !result.errorMessage!.contains('cancelled')) {
      _showError(result.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 780;
            final topImageHeight = isCompact
                ? (constraints.maxHeight * 0.24).clamp(145.0, 190.0)
                : 235.0;
            final sectionSpacing = isCompact ? 18.0 : 24.0;
            final formHorizontalPadding = isCompact ? 18.0 : 24.0;
            final formVerticalPadding = isCompact ? 14.0 : 20.0;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top section with illustration ──
                  Container(
                    width: double.infinity,
                    color: _bgTop,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.asset(
                            'assets/icon/erasebg-transformed 1.png',
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => SizedBox(
                              height: 200,
                              child: Icon(
                                Icons.people_alt_outlined,
                                size: 120,
                                color: _purple.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 16),
                      ],
                    ),
                  ),

                  // ── Form section ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: formHorizontalPadding,
                      vertical: formVerticalPadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: isCompact ? 30 : 34,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Sign ',
                                  style: TextStyle(color: Color(0xFF1A1A2E)),
                                ),
                                TextSpan(
                                  text: 'Up',
                                  style: TextStyle(color: _pink),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create a new account',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                          SizedBox(height: sectionSpacing),

                          // Full Name field
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline,
                            onChanged: (_) {
                              if (_formErrorText != null) {
                                setState(() => _formErrorText = null);
                              }
                            },
                            autovalidateMode: _showValidationErrors
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter your full name';
                              }
                              final trimmed = v.trim();
                              if (trimmed.length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                                return 'Name can only contain letters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email field
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            hint: 'Email',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) {
                              if (_emailErrorText != null ||
                                  _formErrorText != null) {
                                setState(() {
                                  _emailErrorText = null;
                                  _formErrorText = null;
                                });
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            validator: (v) {
                              if (_emailFocusNode.hasFocus) return null;
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (_emailErrorText != null)
                                return _emailErrorText;
                              final input = v.trim();
                              final containsLetter = RegExp(
                                r'[a-zA-Z]',
                              ).hasMatch(input);
                              if (containsLetter || input.contains('@')) {
                                if (!RegExp(
                                  r'^[A-Za-z0-9._%+-]+@',
                                ).hasMatch(input)) {
                                  return 'Invalid email format (must start with username@)';
                                }
                                if (!RegExp(
                                  r'@(gmail\.com|hotmail\.com|outlook\.com|icloud\.com|yahoo\.com|(?:[A-Za-z0-9-]+\.)*edu\.eg)$',
                                  caseSensitive: false,
                                ).hasMatch(input)) {
                                  return 'Email domain not allowed\nAllowed: gmail.com, hotmail.com, outlook.com, icloud.com, yahoo.com, *.edu.eg';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.key_outlined,
                            obscure: _obscurePassword,
                            onChanged: (_) {
                              if (_passwordErrorText != null ||
                                  _formErrorText != null) {
                                setState(() {
                                  _passwordErrorText = null;
                                  _formErrorText = null;
                                });
                              }
                            },
                            autovalidateMode: _showValidationErrors
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
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
                              return _passwordErrorText;
                            },
                          ),
                          SizedBox(height: isCompact ? 14 : 18),

                          // Terms checkbox
                          Row(
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  activeColor: _purple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (v) => setState(() {
                                    _agreeToTerms = v ?? false;
                                    if (_agreeToTerms) _termsErrorText = null;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'I agree to terms and conditions',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF444444),
                                ),
                              ),
                            ],
                          ),
                          if (_termsErrorText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _termsErrorText!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          SizedBox(height: sectionSpacing),

                          // Create Account button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  (_isLoading ||
                                      _isGoogleLoading ||
                                      _isFacebookLoading)
                                  ? null
                                  : _submit,
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
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          if (_formErrorText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _formErrorText!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],

                          // ── "Or sign up with" divider ──
                          SizedBox(height: sectionSpacing),
                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFDDDDDD),
                                  thickness: 1,
                                  endIndent: 12,
                                ),
                              ),
                              Text(
                                'Or sign up with',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Color(0xFFDDDDDD),
                                  thickness: 1,
                                  indent: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 14 : 20),

                          // ── Social login buttons ──
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  onTap:
                                      (_isGoogleLoading || _isFacebookLoading)
                                      ? null
                                      : _signUpWithGoogle,
                                  label: 'Google',
                                  faIcon: FontAwesomeIcons.google,
                                  iconColor: const Color(0xFFDB4437),
                                  isLoading: _isGoogleLoading,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _SocialButton(
                                  onTap:
                                      (_isGoogleLoading || _isFacebookLoading)
                                      ? null
                                      : _signUpWithFacebook,
                                  label: 'Facebook',
                                  faIcon: FontAwesomeIcons.facebook,
                                  iconColor: const Color(0xFF1877F2),
                                  isLoading: _isFacebookLoading,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 14 : 20),

                          // Login link
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888),
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Already have an account? ',
                                    ),
                                    TextSpan(
                                      text: 'Login',
                                      style: TextStyle(
                                        color: _darkBtn,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFAAAAAA)),
        prefixIcon: Icon(icon, color: const Color(0xFFAAAAAA), size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B5EA7), width: 1.5),
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
// Reusable social login button widget
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFFEDE8F5),
        highlightColor: const Color(0xFFEDE8F5).withOpacity(0.5),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: onTap == null
                  ? const Color(0xFFEEEEEE)
                  : const Color(0xFFDDDDDD),
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
                      : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
