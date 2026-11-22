import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/format_pemesanan.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_layout.dart';
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
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Sapaan berdasarkan jam WIB.
  String _sapaan() {
    final jam = keWib(DateTime.now()).hour;
    final waktu = jam < 11
        ? 'pagi'
        : jam < 15
            ? 'siang'
            : jam < 19
                ? 'sore'
                : 'malam';
    return 'Halo! Selamat $waktu!';
  }

  Future<void> _masuk() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.masuk(email: _email.text.trim(), password: _password.text);
      // AuthGate di main.dart otomatis menampilkan Beranda saat sesi berubah.
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _sapaan(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masuk untuk mulai cari parkir.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.slate500),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              BannerPesan(_error!),
              const SizedBox(height: 16),
            ],
            LabelField(
              'Alamat email',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'nama@email.com'),
                validator: validasiEmail,
              ),
            ),
            const SizedBox(height: 16),
            LabelField(
              'Password',
              child: TextFormField(
                controller: _password,
                obscureText: _sembunyi,
                onFieldSubmitted: (_) => _masuk(),
                decoration: InputDecoration(
                  hintText: 'Masukkan password',
                  suffixIcon: IconButton(
                    icon: Icon(_sembunyi
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _sembunyi = !_sembunyi),
                  ),
                ),
                validator: validasiPassword,
              ),
            ),
            const SizedBox(height: 24),
            TombolUtama(label: 'Masuk', loading: _loading, onPressed: _masuk),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(fontSize: 14, color: AppColors.slate500),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegistrasiScreen()),
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
