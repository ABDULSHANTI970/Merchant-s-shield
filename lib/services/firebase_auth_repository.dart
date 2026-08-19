import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(
          (user) => user == null ? null : AppUser.fromFirebase(user),
        );
  }

  @override
  AppUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : AppUser.fromFirebase(user);
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // NOTE: google_sign_in's classic signIn() button-flow API (v6.x) is
      // used here. This package went through a significant API rework in
      // its v7 line (GoogleSignIn.instance.authenticate(), no more plain
      // signIn()). pubspec.yaml pins `^6.2.1` specifically so `flutter pub
      // get` won't silently jump to that newer API and break this file —
      // but since versions couldn't be checked live in this sandbox,
      // double check what actually resolved if you see errors here.
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User closed the picker — not an error, just no-op.
        return;
      }
      final authTokens = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: authTokens.accessToken,
        idToken: authTokens.idToken,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android can auto-verify without the user typing the code at all.
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onVerificationFailed(_mapError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op: if the user's still on the OTP screen they can just
        // retype/resend; nothing to clean up here.
      },
    );
  }

  @override
  Future<void> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'user-disabled':
        return 'هذا الحساب موقوف. تواصل مع الدعم.';
      case 'user-not-found':
        return 'ما في حساب مسجّل بهذا البريد.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور غير صحيحة.';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بحساب موجود مسبقًا.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة — استخدم 6 أحرف على الأقل.';
      case 'invalid-phone-number':
        return 'رقم الجوال غير صحيح. اكتبه مع رمز الدولة، مثال: ‎+970599000000';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح.';
      case 'session-expired':
        return 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.';
      case 'too-many-requests':
        return 'محاولات كثيرة متتالية. حاول بعد شوي.';
      case 'network-request-failed':
        return 'تأكد من الاتصال بالإنترنت وحاول مرة ثانية.';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مسجّل مسبقًا بطريقة دخول مختلفة (جوجل مثلًا).';
      default:
        return 'صار خطأ غير متوقع (${e.code}). حاول مرة ثانية.';
    }
  }
}
