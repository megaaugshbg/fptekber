import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

export 'logo_markir.dart';

/// Lebar layar mulai dianggap "desktop" (navbar penuh, login 2 kolom).
const double batasDesktop = 900;

/// Kartu putih: border garis 1px + bayangan lembut.
class KartuPutih extends StatelessWidget {
  const KartuPutih({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.garis),
        boxShadow: bayanganKartu,
      ),
      child: child,
    );
  }
}

/// Tombol utama penuh lebar. Menampilkan spinner kecil saat [loading].
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
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primer,
              ),
            )
          : Text(label),
    );
  }
}

/// Tombol outline (border 2px primer).
class TombolOutline extends StatelessWidget {
  const TombolOutline({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      OutlinedButton(onPressed: onPressed, child: Text(label));
}

/// Label 14px medium di atas input.
class LabelField extends StatelessWidget {
  const LabelField(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Banner pesan (error merah atau info primer-soft).
class BannerPesan extends StatelessWidget {
  const BannerPesan(this.pesan, {super.key, this.error = true});

  final String pesan;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: error ? AppColors.merah50 : AppColors.primerSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error ? AppColors.merah200 : AppColors.garis,
        ),
      ),
      child: Text(
        pesan,
        style: TextStyle(
          fontSize: 14,
          color: error ? AppColors.merah : AppColors.primer,
        ),
      ),
    );
  }
}

/// Border putus-putus (dipakai keadaan kosong & lorong denah).
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.warna,
    this.lebar = 2,
    this.radius = 24,
    this.dash = 8,
    this.celah = 6,
  });

  final Color warna;
  final double lebar;
  final double radius;
  final double dash;
  final double celah;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = warna
      ..style = PaintingStyle.stroke
      ..strokeWidth = lebar;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(lebar / 2),
        Radius.circular(radius),
      ));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + dash), paint);
        d += dash + celah;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) =>
      old.warna != warna || old.lebar != lebar || old.radius != radius;
}

/// Garis vertikal putus-putus (lorong denah).
class GarisVertikalPutus extends StatelessWidget {
  const GarisVertikalPutus({super.key});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _GarisVertikalPainter(), size: const Size(2, 0));
}

class _GarisVertikalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.garis
      ..strokeWidth = 2;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, (y + 8).clamp(0, size.height)), paint);
      y += 14;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
