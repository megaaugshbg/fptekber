import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Registrasi, verifikasi kode, login, logout, dan profil.
class AuthService {
  /// Daftar akun baru. Supabase mengirim kode verifikasi ke email.
  /// nama dan no_telp otomatis masuk ke tabel profiles lewat trigger.
  Future<void> daftar({
    required String nama,
    required String email,
    required String noTelp,
    required String password,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'nama': nama, 'no_telp': noTelp},
    );
  }

  /// Cek kode verifikasi yang dikirim ke email.
  Future<void> verifikasiKode({
    required String email,
    required String kode,
  }) async {
    await supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: kode,
    );
  }

  /// Kirim ulang kode verifikasi (dibatasi 1x per 60 detik oleh Supabase).
  Future<void> kirimUlangKode(String email) async {
    await supabase.auth.resend(type: OtpType.signup, email: email);
  }

  /// Login. Akun yang belum verifikasi akan ditolak oleh Supabase.
  Future<void> masuk({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> keluar() async {
    await supabase.auth.signOut();
  }

  bool get sudahLogin => supabase.auth.currentSession != null;

  String? get userId => supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>> ambilProfil() async {
    return await supabase
        .from('profiles')
        .select()
        .eq('id', userId!)
        .single();
  }

  Future<void> ubahProfil({String? nama, String? noTelp}) async {
    await supabase.from('profiles').update({
      'nama': ?nama,
      'no_telp': ?noTelp,
    }).eq('id', userId!);
  }

  /// Pesan error yang lebih enak dibaca untuk ditampilkan di SnackBar.
  static String pesanError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Email atau kata sandi salah';
      if (m.contains('email not confirmed')) return 'Email belum diverifikasi';
      if (m.contains('already registered')) return 'Email sudah terdaftar';
      if (m.contains('expired') || m.contains('invalid')) {
        return 'Kode salah atau sudah kedaluwarsa';
      }
      return e.message;
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
