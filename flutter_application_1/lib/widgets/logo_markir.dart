import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo Markir.In dari aset (rasio 563:153). Jika aset gagal dimuat,
/// tampil teks "MARKIR.in". [krem] mewarnai logo jadi #FFFBE8.
class LogoMarkir extends StatelessWidget {
  const LogoMarkir({super.key, this.height = 40, this.krem = false});

  final double height;
  final bool krem;

  @override
  Widget build(BuildContext context) {
    final warna = krem ? AppColors.onPrimer : AppColors.primer;
    final gambar = Image.asset(
      'assets/images/logo-trim.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: height * 0.6,
            color: warna,
            fontWeight: FontWeight.w800,
          ),
          children: const [
            TextSpan(text: 'MARKIR'),
            TextSpan(text: '.in', style: TextStyle(fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
    if (!krem) return gambar;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(AppColors.onPrimer, BlendMode.srcIn),
      child: gambar,
    );
  }
}
