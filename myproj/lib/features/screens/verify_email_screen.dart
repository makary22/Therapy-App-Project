import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/auth_service.dart';
import '../home/HomeScreen.dart' show HomeScreen;
import 'register.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isCheckingVerification = false;
  bool _isResending = false;
  String? _message;
  bool _messageIsError = false;

  // Cooldown to prevent spamming "Resend"
  bool _resendCooldown = false;

  static const Color _purple = Color(0xFF7B5EA7);
  static const Color _pink = Color(0xFFD45DA1);
  static const Color _darkBtn = Color(0xFF1A1A2E);
  static const Color _bgTop = Color(0xFFEDE8F5);

  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? 'your email';

  // ─────────────────────────────────────────────────────────────
  // CHECK VERIFICATION
  // ─────────────────────────────────────────────────────────────
  Future<void> _checkVerification() async {
    setState(() {
      _isCheckingVerification = true;
      _message = null;
    });

    final verified = await AuthService.checkEmailVerified();

    if (!mounted) return;

    if (verified) {
      // Navigate to Home and clear the stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _isCheckingVerification = false;
        _message =
            'Your email is not verified yet.\nPlease check your inbox and click the verification link.';
        _messageIsError = true;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESEND VERIFICATION EMAIL
  // ─────────────────────────────────────────────────────────────
  Future<void> _resendEmail() async {
    if (_resendCooldown) return;

    setState(() {
      _isResending = true;
      _message = null;
    });

    final result = await AuthService.resendVerificationEmail();

    if (!mounted) return;

    setState(() {
      _isResending = false;
      _message = result.success
          ? 'Verification email sent! Check your inbox.'
          : result.errorMessage;
      _messageIsError = !result.success;
    });

    if (result.success) {
      // Apply a 30-second cooldown after a successful resend
      setState(() => _resendCooldown = true);
      await Future.delayed(const Duration(seconds: 30));
      if (mounted) setState(() => _resendCooldown = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top illustration band ──
              Container(
                color: _bgTop,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: _purple.withOpacity(0.12),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 60,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Decorative dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(_pink),
                        const SizedBox(width: 6),
                        _dot(_purple),
                        const SizedBox(width: 6),
                        _dot(_pink.withOpacity(0.4)),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Verify your ',
                              style: TextStyle(color: Color(0xFF1A1A2E)),
                            ),
                            TextSpan(
                              text: 'Email',
                              style: TextStyle(color: _pink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Instruction text
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.6,
                          ),
                          children: [
                            const TextSpan(
                              text: 'We sent a verification link to:\n',
                            ),
                            TextSpan(
                              text: _userEmail,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _purple,
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '\n\nOpen your email and click the link to activate your account. '
                                  "If you can't find it, check your spam folder.",
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ── "I Verified My Email" button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isCheckingVerification
                              ? null
                              : _checkVerification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _darkBtn,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingVerification
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'I Verified My Email',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── "Resend Verification Email" button ──
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: (_isResending || _resendCooldown)
                              ? null
                              : _resendEmail,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _purple,
                            side: BorderSide(color: _purple, width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isResending
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: _purple,
                                  ),
                                )
                              : Text(
                                  _resendCooldown
                                      ? 'Email sent — wait 30 s to resend'
                                      : 'Resend Verification Email',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      // ── Feedback message ──
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: _messageIsError
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _messageIsError
                                  ? Colors.redAccent.withOpacity(0.4)
                                  : Colors.green.shade300,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _messageIsError
                                    ? Icons.error_outline
                                    : Icons.check_circle_outline,
                                size: 18,
                                color: _messageIsError
                                    ? Colors.redAccent
                                    : Colors.green.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _message!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _messageIsError
                                        ? Colors.redAccent
                                        : Colors.green.shade800,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
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

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
