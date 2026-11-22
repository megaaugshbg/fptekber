import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const gayaJudulKartu = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w800,
  color: AppColors.navy,
);

/// Logo Markir.in. [besar] = true untuk halaman login/daftar,
/// false untuk AppBar.
class LogoMarkir extends StatelessWidget {
  const LogoMarkir({super.key, this.besar = true});

  final bool besar;

  @override
  Widget build(BuildContext context) {
    final teks = RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: besar ? 30 : 17,
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        children: const [
          TextSpan(text: 'MARKIR'),
          TextSpan(
            text: '.in',
            style: TextStyle(fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );

    if (!besar) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_parking_rounded,
              color: AppColors.navy, size: 22),
          const SizedBox(width: 6),
          teks,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.navy, width: 3),
          ),
          child: const Icon(
            Icons.local_parking_rounded,
            size: 46,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        teks,
      ],
    );
  }
}

/// Kartu putih dengan sudut membulat dan bayangan halus.
class KartuPutih extends StatelessWidget {
  const KartuPutih({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Tombol utama. Menampilkan spinner saat [loading].
class TombolUtama extends StatelessWidget {
  const TombolUtama({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

/// SnackBar singkat untuk pesan sukses atau error.
void pesanSnack(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(pesan),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

// ---------- Validator ----------

String? validasiWajib(String? v, String label) =>
    (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

String? validasiEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
  final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v.trim());
  return ok ? null : 'Format email tidak valid';
}

String? validasiPassword(String? v) {
  if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
  if (v.length < 6) return 'Kata sandi minimal 6 karakter';
  return null;
}

/// Nomor tanpa +62 dan tanpa 0 di depan, contoh 81234567890.
String? validasiTelp(String? v) {
  if (v == null || v.trim().isEmpty) return 'Nomor telepon wajib diisi';
  if (!RegExp(r'^8\d{7,11}$').hasMatch(v.trim())) {
    return 'Tanpa 0 di depan, contoh 81234567890';
  }
  return null;
}