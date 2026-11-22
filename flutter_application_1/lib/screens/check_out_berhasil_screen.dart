import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'struk_screen.dart';

/// Durasi aktual dan kelebihan jam untuk pemesanan yang sudah check-out.
({int? aktual, int lebih}) ringkasDurasi(Map<String, dynamic> p) {
  final masuk = waktuCheckIn(p);
  final keluar = waktuCheckOut(p);
  if (masuk == null || keluar == null) return (aktual: null, lebih: 0);
  final aktual = hitungDurasiAktual(masuk, keluar);
  final dibayar = durasiDibayar(p);
  return (
    aktual: aktual,
    lebih: dibayar == null ? 0 : melebihiJam(aktual, dibayar),
  );
}

class CheckOutBerhasilScreen extends StatelessWidget {
  const CheckOutBerhasilScreen({super.key, required this.data});

  /// Pemesanan lengkap setelah check-out.
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final d = ringkasDurasi(data);
    final total = jumlahDibayar(data);
    return KerangkaLayarBooking(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const IkonCentang(),
          const SizedBox(height: 16),
          const Text('Check-out berhasil',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Terima kasih, booking ${kodePesanan(data)} sudah selesai.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(height: 24),
          KartuBaris([
            BarisInfo.teks('Waktu keluar', tampilWib(waktuCheckOut(data))),
            BarisInfo.teks('Durasi parkir', teksJam(d.aktual)),
            BarisInfo.teks(
                'Total biaya', total == null ? '-' : formatRupiah(total),
                tebal: true),
          ]),
          const SizedBox(height: 12),
          const Text(
            'Biaya parkir sudah dibayar sebelum check in, jadi tidak ada '
            'pembayaran tambahan saat check-out.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          if (d.lebih > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Durasi aktual melebihi jam yang dibayar (${d.lebih} jam). '
              'Informasi saja, tanpa tagihan tambahan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
            ),
          ],
          const SizedBox(height: 24),
          TombolOutline(
            label: 'Lihat Struk',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => StrukScreen(data: data)),
            ),
          ),
          const SizedBox(height: 12),
          TombolUtama(
            label: 'Selesai',
            onPressed: () => kembaliKeKerangka(context, 0),
          ),
        ],
      ),
    );
  }
}
