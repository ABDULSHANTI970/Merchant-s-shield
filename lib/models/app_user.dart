import 'package:firebase_auth/firebase_auth.dart';

/// A signed-in trader. Deliberately thin for Phase 2 — company name,
/// commercial register number, and rating (feature #32, "الملف الشخصي
/// للتاجر") get their own `traders/{uid}` Firestore document in a later
/// phase. This is just "who is signed in right now".
class AppUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  /// Best-effort human label when displayName isn't set (e.g. phone-only
  /// sign-in), so the UI never shows a blank name.
  String get label {
    if (displayName != null && displayName!.trim().isNotEmpty) return displayName!;
    if (email != null && email!.isNotEmpty) return email!;
    if (phoneNumber != null && phoneNumber!.isNotEmpty) return phoneNumber!;
    return 'تاجر';
  }
}
