import '../models/app_user.dart';

/// Everything the app needs from "who is signed in" lives behind this
/// interface — same reasoning as [MarketRepository]: screens don't talk
/// to `firebase_auth` directly, so swapping/mocking auth later doesn't
/// mean rewriting every screen that cares whether someone's logged in.
abstract class AuthRepository {
  /// Emits the current user (or null when signed out) immediately on
  /// listen, then again every time auth state changes.
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> signInWithEmail({required String email, required String password});

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signInWithGoogle();

  /// Starts phone verification. [onCodeSent] fires once Firebase has sent
  /// the SMS, with the `verificationId` you must pass back into
  /// [confirmPhoneCode]. [onVerificationFailed] fires for bad numbers,
  /// quota issues, etc. — always show that message to the user rather
  /// than swallowing it.
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onVerificationFailed,
  });

  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<void> signOut();
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
