import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/auth_repository.dart';
import 'phone_otp_screen.dart';
import 'widgets/google_sign_in_button.dart';

/// Feature #31 — "تسجيل دخول: ايميل + رقم جوال + جوجل".
///
/// Shown whenever a screen needs a signed-in trader and there isn't one
/// (see MarketScreen's "إضافة منتج" button). On success, pops back to
/// whatever pushed it — the caller decides what happens next.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'البريد الإلكتروني'),
            Tab(text: 'رقم الجوال'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _EmailTab(authRepository: widget.authRepository),
                _PhoneTab(authRepository: widget.authRepository),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('أو', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
                _GoogleSection(authRepository: widget.authRepository),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmailTab extends StatefulWidget {
  const _EmailTab({required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends State<_EmailTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (_isRegisterMode) {
        await widget.authRepository.registerWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await widget.authRepository.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isRegisterMode) ...[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الشركة أو الاسم الكامل',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                if (!v.contains('@') || !v.contains('.')) return 'بريد إلكتروني غير صحيح';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (v.length < 6) return '6 أحرف على الأقل';
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _submitting ? null : _submit,
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
                  : Text(_isRegisterMode ? 'إنشاء حساب' : 'تسجيل الدخول'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                        _isRegisterMode = !_isRegisterMode;
                        _error = null;
                      }),
              child: Text(
                _isRegisterMode ? 'لديك حساب؟ سجّل الدخول' : 'ليس لديك حساب؟ أنشئ واحدًا',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneTab extends StatefulWidget {
  const _PhoneTab({required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<_PhoneTab> createState() => _PhoneTabState();
}

class _PhoneTabState extends State<_PhoneTab> {
  final _phoneController = TextEditingController(text: '+970');
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'اكتب رقم الجوال كامل مع رمز الدولة.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authRepository.sendPhoneCode(
        phoneNumber: phone,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _submitting = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhoneOtpScreen(
                authRepository: widget.authRepository,
                phoneNumber: phone,
                verificationId: verificationId,
              ),
            ),
          );
        },
        onVerificationFailed: (message) {
          if (!mounted) return;
          setState(() {
            _error = message;
            _submitting = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'صار خطأ غير متوقع. حاول مرة ثانية.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رقم الجوال',
              hintText: '+970599000000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'رح نرسلّك رمز تحقق برسالة SMS.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting ? null : _sendCode,
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
                : const Text('إرسال رمز التحقق'),
          ),
        ],
      ),
    );
  }
}

class _GoogleSection extends StatefulWidget {
  const _GoogleSection({required this.authRepository});
  final AuthRepository authRepository;

  @override
  State<_GoogleSection> createState() => _GoogleSectionState();
}

class _GoogleSectionState extends State<_GoogleSection> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      await widget.authRepository.signInWithGoogle();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذّر الدخول عبر جوجل. حاول مرة ثانية.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleSignInButton(onPressed: _signIn, loading: _loading);
  }
}
