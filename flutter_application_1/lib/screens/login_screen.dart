import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/markir_widgets.dart';
import 'registrasi_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _sembunyi = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _sapaan() {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Halo! Selamat pagi!';
    if (jam < 15) return 'Halo! Selamat siang!';
    if (jam < 18) return 'Halo! Selamat sore!';
    return 'Halo! Selamat malam!';
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.masuk(email: _email.text.trim(), password: _password.text);
      // Tidak perlu pindah halaman manual: AuthGate di main.dart
      // otomatis menampilkan Beranda ketika sesi berubah.
    } catch (e) {
      if (mounted) pesanSnack(context, AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(
                _sapaan(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 24),
              const LogoMarkir(),
              const SizedBox(height: 32),
              KartuPutih(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Masuk ke akunmu', style: gayaJudulKartu),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan alamat email',
                        ),
                        validator: validasiEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _sembunyi,
                        decoration: InputDecoration(
                          hintText: 'Masukkan kata sandi',
                          suffixIcon: IconButton(
                            icon: Icon(_sembunyi
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _sembunyi = !_sembunyi),
                          ),
                        ),
                        validator: validasiPassword,
                      ),
                      const SizedBox(height: 24),
                      TombolUtama(
                        label: 'Masuk',
                        loading: _loading,
                        onPressed: _masuk,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun?',
                            style: TextStyle(color: AppColors.abu),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistrasiScreen(),
                              ),
                            ),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
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
}