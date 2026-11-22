import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_out_berhasil_screen.dart' show ringkasDurasi;
import '../theme/app_theme.dart';

class StrukScreen extends StatelessWidget {
  const StrukScreen({super.key, required this.data});

  /// Pemesanan lengkap yang sudah check-out.
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final d = ringkasDurasi(data);
    final tarif = tarifPerJamDari(data);
    final total = jumlahDibayar(data);
    return KerangkaLayarBooking(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TombolKembali('Kembali'),
          const SizedBox(height: 4),
          Row(
            children: [
              const Expanded(
                child: Text('Struk Parkir',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              PilStatus(labelStatus(data['status'] as String?)),
            ],
          ),
          const SizedBox(height: 16),
          KartuBaris([
            BarisInfo.teks('Kode', kodePesanan(data), tebal: true),
            BarisInfo.teks('Lokasi', namaLokasiDari(data)),
            BarisInfo.teks('Alamat', alamatLokasiDari(data)),
            BarisInfo.teks('Slot', kodeSlotDari(data), tebal: true),
            BarisInfo.teks('Waktu masuk', tampilWib(waktuCheckIn(data))),
            BarisInfo.teks('Waktu keluar', tampilWib(waktuCheckOut(data))),
            BarisInfo.teks('Durasi', teksJam(d.aktual)),
            BarisInfo.teks(
                'Tarif/jam', tarif == null ? '-' : formatRupiah(tarif)),
            BarisInfo.teks(
                'Total dibayar', total == null ? '-' : formatRupiah(total),
                tebal: true),
          ]),
          const SizedBox(height: 12),
          const Text(
            'Biaya parkir dibayar sebelum check in. Terima kasih telah memakai Markir.In.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          // TODO(cetak): tombol "Cetak" (window.print di web) ditunda; butuh
          // conditional import dart:html/package:web.
          const SizedBox(height: 24),
          TombolUtama(
            label: 'Selesai',
            onPressed: () => kembaliKeKerangka(context, 0),
          ),
        ],
      ),
    );
  }
}
