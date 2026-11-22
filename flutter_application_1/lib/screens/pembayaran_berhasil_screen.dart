import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_in_screen.dart';

class PembayaranBerhasilScreen extends StatelessWidget {
  const PembayaranBerhasilScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return KerangkaLayarBooking(
      child: MuatPemesanan(
        id: id,
        paksa: true, // butuh baris pembayaran terbaru
        builder: (context, p) {
          final status = p['status'] as String?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const IkonCentang(),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'No. transaksi ${nomorTransaksi(idPembayaran(p))}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.slate500),
              ),
              const SizedBox(height: 24),
              KartuBaris([
                BarisInfo.teks('Kode pesanan', kodePesanan(p), tebal: true),
                BarisInfo.teks('Lokasi', namaLokasiDari(p)),
                BarisInfo.teks('Slot (Normal)', kodeSlotDari(p), tebal: true),
                BarisInfo.teks('Lama parkir', teksJam(durasiDibayar(p))),
                BarisInfo.teks('Metode', metodePembayaran(p) ?? 'QRIS'),
                BarisInfo.teks('Waktu bayar', tampilWib(waktuBayar(p))),
                BarisInfo.teks('Total dibayar', _rupiah(jumlahDibayar(p)),
                    tebal: true),
                BarisInfo(
                  'Status',
                  PilStatus(status == 'dibayar'
                      ? 'Sudah dibayar'
                      : labelStatus(status)),
                ),
              ]),
              const SizedBox(height: 24),
              TombolUtama(
                label: 'Lanjut ke check in',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckInScreen(pemesanan: p),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TombolOutline(
                label: 'Kembali ke beranda',
                onPressed: () => kembaliKeKerangka(context, 0),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _rupiah(num? n) => n == null ? '-' : formatRupiah(n);
