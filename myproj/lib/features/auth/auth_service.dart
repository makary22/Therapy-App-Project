import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Result wrapper so callers get a typed success/error response
/// without needing to catch exceptions themselves.
class AuthResult {
  final bool success;
  final String? errorMessage;

  const AuthResult._({required this.success, this.errorMessage});

  factory AuthResult.success() => const AuthResult._(success: true);
  factory AuthResult.failure(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

class AuthService {
  static final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────────────────────
  static Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (fullName.isNotEmpty) {
        await credential.user?.updateDisplayName(fullName);
        await credential.user?.reload();
      }

      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('[Auth] Verification email sent to: ${user.email}');
      }

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Register error: ${e.code} - ${e.message}');
      return AuthResult.failure(_mapRegisterError(e));
    } catch (e) {
      debugPrint('[Auth] Unexpected register error: $e');
      return AuthResult.failure('Something went wrong. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────
  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;

      debugPrint('[Auth] Login success. emailVerified=$verified');
      return LoginResult.success(isEmailVerified: verified);
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Login error: ${e.code} - ${e.message}');
      return LoginResult.failure(_mapLoginError(e));
    } catch (e) {
      debugPrint('[Auth] Unexpected login error: $e');
      return LoginResult.failure('Something went wrong. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ─────────────────────────────────────────────────────────────
  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return AuthResult.failure('Google sign-in cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _auth.currentUser?.reload();

      debugPrint('[Auth] Google sign-in success: ${_auth.currentUser?.email}');
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Google sign-in error: ${e.code}');
      return AuthResult.failure(_mapSocialError(e));
    } catch (e) {
      debugPrint('[Auth] Google unexpected error: $e');
      return AuthResult.failure('Google sign-in failed. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FACEBOOK SIGN-IN
  // ─────────────────────────────────────────────────────────────
  static Future<AuthResult> signInWithFacebook() async {
    try {
      final loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      debugPrint(
        '[Auth] Facebook login status=${loginResult.status} message=${loginResult.message}',
      );

      if (loginResult.status == LoginStatus.cancelled) {
        return AuthResult.failure('Facebook sign-in cancelled.');
      }

      if (loginResult.status != LoginStatus.success) {
        return AuthResult.failure(
          loginResult.message ??
              'Facebook sign-in failed (status: ${loginResult.status.name}).',
        );
      }

      final token = loginResult.accessToken?.tokenString;
      if (token == null || token.isEmpty) {
        return AuthResult.failure(
          'Facebook sign-in failed: no access token returned.',
        );
      }

      final credential = FacebookAuthProvider.credential(token);

      await _auth.signInWithCredential(credential);
      await _auth.currentUser?.reload();

      debugPrint(
        '[Auth] Facebook sign-in success: ${_auth.currentUser?.email}',
      );
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Facebook sign-in error: ${e.code}');
      return AuthResult.failure(_mapSocialError(e));
    } catch (e) {
      debugPrint('[Auth] Facebook unexpected error: $e');
      return AuthResult.failure('Facebook sign-in failed. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // RESEND VERIFICATION EMAIL
  // ─────────────────────────────────────────────────────────────
  static Future<AuthResult> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No signed-in user found.');
      }
      if (user.emailVerified) {
        return AuthResult.failure('This email is already verified.');
      }
      await user.sendEmailVerification();
      debugPrint('[Auth] Verification email resent to: ${user.email}');
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Resend error: ${e.code} - ${e.message}');
      return AuthResult.failure(_mapResendError(e));
    } catch (e) {
      debugPrint('[Auth] Unexpected resend error: $e');
      return AuthResult.failure('Failed to resend email. Please try again.');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CHECK EMAIL VERIFICATION
  // ─────────────────────────────────────────────────────────────
  static Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    final verified = _auth.currentUser?.emailVerified ?? false;
    debugPrint('[Auth] checkEmailVerified → $verified');
    return verified;
  }

  // ─────────────────────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────────────────
  // ERROR MAPPERS
  // ─────────────────────────────────────────────────────────────
  static String _mapRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        final msg = (e.message ?? '').toLowerCase();
        if (msg.contains('configuration_not_found')) {
          return 'Firebase config is invalid. Re-download google-services.json.';
        }
        return 'Failed to create account (${e.code}).';
    }
  }

  static String _mapLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection. Try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  static String _mapResendError(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Too many requests. Please wait a moment before trying again.';
      case 'network-request-failed':
        return 'No internet connection. Try again.';
      default:
        return 'Failed to send email (${e.code}).';
    }
  }

  static String _mapSocialError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// LOGIN RESULT — extends AuthResult with emailVerified flag
// ─────────────────────────────────────────────────────────────
class LoginResult extends AuthResult {
  final bool isEmailVerified;

  const LoginResult._({
    required super.success,
    super.errorMessage,
    this.isEmailVerified = false,
  }) : super._();

  factory LoginResult.success({required bool isEmailVerified}) =>
      LoginResult._(success: true, isEmailVerified: isEmailVerified);

  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}
