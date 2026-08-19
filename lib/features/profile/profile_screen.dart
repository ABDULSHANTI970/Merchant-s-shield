import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../services/auth_repository.dart';

/// Bare-bones account screen for Phase 2. The full "الملف الشخصي للتاجر"
/// (feature #32 — company name, commercial register, rating) needs its
/// own `traders/{uid}` Firestore document and edit form, which belongs to
/// a later phase once we know what the ratings/reviews model looks like.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.authRepository, required this.user});

  final AuthRepository authRepository;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surfaceAlt,
              backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? const Icon(Icons.person_outline, size: 34, color: AppColors.navy)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(user.label, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                if (user.email != null)
                  _InfoRow(icon: Icons.mail_outline, label: 'البريد الإلكتروني', value: user.email!),
                if (user.phoneNumber != null)
                  _InfoRow(icon: Icons.phone_outlined, label: 'رقم الجوال', value: user.phoneNumber!),
                _InfoRow(icon: Icons.badge_outlined, label: 'معرّف الحساب', value: user.uid),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await authRepository.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text('تسجيل الخروج', style: TextStyle(color: AppColors.danger)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      ),
    );
  }
}
