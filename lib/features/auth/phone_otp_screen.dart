import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_repository.dart';

/// Step 2 of phone sign-in: the user types the 6-digit SMS code Firebase
/// just sent. Reached from [LoginScreen] after [AuthRepository.sendPhoneCode]
/// calls back with a verificationId.
class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({
    super.key,
    required this.authRepository,
    required this.phoneNumber,
    required this.verificationId,
  });

  final AuthRepository authRepository;
  final String phoneNumber;
  final String verificationId;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _codeController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'أدخل الرمز المكوّن من 6 أرقام كامل.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.confirmPhoneCode(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      if (mounted) {
        // Pop all the way back past the login screen to whatever screen
        // triggered sign-in (e.g. "إضافة منتج").
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'صار خطأ غير متوقع. حاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تأكيد رقم الجوال')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أرسلنا رمز تحقق مكوّن من 6 أرقام إلى',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.phoneNumber,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submitting ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }
}
