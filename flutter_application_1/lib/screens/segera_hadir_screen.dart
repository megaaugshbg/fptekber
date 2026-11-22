import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';

/// Isi placeholder "Segera hadir" (dipakai di tab dan layar penuh).
class SegeraHadirView extends StatelessWidget {
  const SegeraHadirView({super.key, this.judul});

  final String? judul;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: KartuPutih(
          padding: const EdgeInsets.all(32),
          radius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primerSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_empty_rounded,
                    color: AppColors.primer),
              ),
              const SizedBox(height: 16),
              if (judul != null) ...[
                Text(judul!,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
              ],
              const Text('Segera hadir',
                  style: TextStyle(fontSize: 14, color: AppColors.slate500)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Layar penuh placeholder (mis. pembayaran, TODO tahap berikutnya).
class SegeraHadirScreen extends StatelessWidget {
  const SegeraHadirScreen({super.key, this.judul});

  final String? judul;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const NavbarAtas(),
          Expanded(child: SegeraHadirView(judul: judul)),
        ],
      ),
    );
  }
}
