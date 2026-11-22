import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';

class CheckInBerhasilScreen extends StatelessWidget {
  const CheckInBerhasilScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return KerangkaLayarBooking(
      child: MuatPemesanan(
        id: id,
        paksa: true, // butuh waktu masuk terbaru
        builder: (context, p) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const IkonCentang(),
            const SizedBox(height: 16),
            const Text('Check in berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Silakan parkir di slot ${kodeSlotDari(p)}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.slate500)),
            const SizedBox(height: 24),
            KartuBaris([
              BarisInfo.teks('Kode pesanan', kodePesanan(p), tebal: true),
              BarisInfo.teks('Lokasi', namaLokasiDari(p)),
              BarisInfo.teks('Slot (Normal)', kodeSlotDari(p), tebal: true),
              BarisInfo.teks('Waktu masuk', tampilWib(waktuCheckIn(p))),
              BarisInfo('Status slot', const PilStatus('Terisi')),
              BarisInfo('Status booking',
                  PilStatus(labelStatus(p['status'] as String?))),
            ]),
            const SizedBox(height: 12),
            const Text(
              'Saat keluar, lakukan check-out dengan scan barcode booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
            const SizedBox(height: 24),
            TombolUtama(
              label: 'Ke halaman check-out',
              onPressed: () => kembaliKeKerangka(context, 1),
            ),
            const SizedBox(height: 12),
            TombolOutline(
              label: 'Kembali ke beranda',
              onPressed: () => kembaliKeKerangka(context, 0),
            ),
          ],
        ),
      ),
    );
  }
}
