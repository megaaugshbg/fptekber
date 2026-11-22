import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/markir_widgets.dart';

class RegistrasiScreen extends StatefulWidget {
  const RegistrasiScreen({super.key});

  @override
  State<RegistrasiScreen> createState() => _RegistrasiScreenState();
}

class _RegistrasiScreenState extends State<RegistrasiScreen> {
  final _auth = AuthService();
  final _formDaftar = GlobalKey<FormState>();
  final _formKode = GlobalKey<FormState>();

  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telp = TextEditingController();
  final _password = TextEditingController();
  final _konfirmasi = TextEditingController();
  final _kode = TextEditingController();

  bool _sembunyi = true;
  bool _loading = false;
  bool _tahapKode = false; // false = isi formulir, true = isi kode verifikasi
  int _hitungMundur = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_nama, _email, _telp, _password, _konfirmasi, _kode]) {
      c.dispose();
    }
    super.dispose();
  }

  void _mulaiHitungMundur() {
    _timer?.cancel();
    setState(() => _hitungMundur = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _hitungMundur <= 1) {
        t.cancel();
        if (mounted) setState(() => _hitungMundur = 0);
        return;
      }
      setState(() => _hitungMundur--);
    });
  }

  Future<void> _daftar() async {
    if (!_formDaftar.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.daftar(
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        noTelp: '+62${_telp.text.trim()}',
        password: _password.text,
      );
      if (!mounted) return;
      setState(() => _tahapKode = true);
      _mulaiHitungMundur();
      pesanSnack(context,
          'Kode verifikasi sudah dikirim ke ${_email.text.trim()}');
    } catch (e) {
      if (mounted) pesanSnack(context, AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifikasi() async {
    if (!_formKode.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.verifikasiKode(
        email: _email.text.trim(),
        kode: _kode.text.trim(),
      );
      if (!mounted) return;
      pesanSnack(context, 'Akun berhasil diverifikasi. Selamat datang!');
      // Sesi sudah aktif, AuthGate menampilkan Beranda di route paling bawah.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) pesanSnack(context, AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _kirimUlang() async {
    if (_hitungMundur > 0) return;
    try {
      await _auth.kirimUlangKode(_email.text.trim());
      if (!mounted) return;
      _mulaiHitungMundur();
      pesanSnack(context, 'Kode baru sudah dikirim');
    } catch (e) {
      if (mounted) pesanSnack(context, AuthService.pesanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.biruMuda,
      appBar: AppBar(
        title: Text(_tahapKode ? 'Verifikasi Email' : 'Daftar Akun'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: KartuPutih(
            child: _tahapKode ? _formKodeWidget() : _formDaftarWidget(),
          ),
        ),
      ),
    );
  }

  Widget _formDaftarWidget() {
    return Form(
      key: _formDaftar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Buat akun baru', style: gayaJudulKartu),
          const SizedBox(height: 4),
          const Text(
            'Lengkapi data berikut untuk mulai memesan parkir.',
            style: TextStyle(color: AppColors.abu),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nama,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              hintText: 'Masukkan nama lengkap',
            ),
            validator: (v) => validasiWajib(v, 'Nama'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'contoh@email.com',
            ),
            validator: validasiEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _telp,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Nomor telepon',
              prefixText: '+62 ',
              hintText: '81234567890',
            ),
            validator: validasiTelp,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            obscureText: _sembunyi,
            decoration: InputDecoration(
              labelText: 'Kata sandi',
              hintText: 'Minimal 6 karakter',
              suffixIcon: IconButton(
                icon: Icon(_sembunyi
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _sembunyi = !_sembunyi),
              ),
            ),
            validator: validasiPassword,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _konfirmasi,
            obscureText: _sembunyi,
            decoration: const InputDecoration(
              labelText: 'Ulangi kata sandi',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ulangi kata sandi';
              if (v != _password.text) return 'Kata sandi tidak sama';
              return null;
            },
          ),
          const SizedBox(height: 24),
          TombolUtama(
            label: 'Daftar',
            loading: _loading,
            onPressed: _daftar,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sudah punya akun?',
                  style: TextStyle(color: AppColors.abu)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Masuk',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formKodeWidget() {
    return Form(
      key: _formKode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              size: 56, color: AppColors.navy),
          const SizedBox(height: 12),
          const Text(
            'Masukkan kode verifikasi',
            textAlign: TextAlign.center,
            style: gayaJudulKartu,
          ),
          const SizedBox(height: 8),
          Text(
            'Kode 6 digit telah dikirim ke\n${_email.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.abu),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _kode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '------',
            ),
            validator: (v) => (v != null && RegExp(r'^\d{6}$').hasMatch(v))
                ? null
                : 'Kode harus 6 digit angka',
          ),
          const SizedBox(height: 20),
          TombolUtama(
            label: 'Verifikasi',
            loading: _loading,
            onPressed: _verifikasi,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _hitungMundur > 0 ? null : _kirimUlang,
            child: Text(
              _hitungMundur > 0
                  ? 'Kirim ulang kode ($_hitungMundur dtk)'
                  : 'Kirim ulang kode',
            ),
          ),
        ],
      ),
    );
  }
}