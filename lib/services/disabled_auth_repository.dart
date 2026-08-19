import '../models/app_user.dart';
import 'auth_repository.dart';

/// Used instead of [FirebaseAuthRepository] when Firebase couldn't be
/// initialized (see main.dart). Unlike [SampleMarketRepository], there's
/// no meaningful "fake sign-in" to offer — auth needs a real backend to
/// mean anything — so every action just explains why it can't work yet
/// instead of the app crashing when someone taps "تسجيل الدخول".
class DisabledAuthRepository implements AuthRepository {
  static const _message =
      'تسجيل الدخول غير متاح حاليًا — لم يتم ربط Firebase بعد. راجع خطوات الإعداد في README.md.';

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(null);

  @override
  AppUser? get currentUser => null;

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    throw const AuthException(_message);
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    throw const AuthException(_message);
  }

  @override
  Future<void> signInWithGoogle() async {
    throw const AuthException(_message);
  }

  @override
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onVerificationFailed,
  }) async {
    onVerificationFailed(_message);
  }

  @override
  Future<void> confirmPhoneCode({required String verificationId, required String smsCode}) async {
    throw const AuthException(_message);
  }

  @override
  Future<void> signOut() async {}
}
