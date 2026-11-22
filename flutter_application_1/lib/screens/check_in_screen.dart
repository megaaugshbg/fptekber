import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_in_berhasil_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key, required this.pemesanan});

  /// Pemesanan berstatus dibayar (hasil detail() atau pesananAktif()).
  final Map<String, dynamic> pemesanan;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _loading = false;
  String? _error;

  int get _id => (widget.pemesanan['id'] as num).toInt();

  Future<void> _checkIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PemesananService().checkIn(_id);
      segarkanData();
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CheckInBerhasilScreen(id: _id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PemesananService.pesanError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KerangkaLayarBooking(
      child: MuatPemesanan(
        id: _id,
        awal: widget.pemesanan,
        builder: (context, p) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TombolKembali('Kembali'),
            const SizedBox(height: 4),
            const JudulLayar('Check In',
                'Konfirmasi check in saat kamu sudah sampai di lokasi parkir.'),
            if (_error != null) ...[
              BannerPesan(_error!),
              const SizedBox(height: 12),
            ],
            _kartuSlot(p),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Detail booking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            KartuBaris([
              BarisInfo.teks('Kode booking', kodePesanan(p), tebal: true),
              BarisInfo.teks('Lokasi', namaLokasiDari(p)),
              BarisInfo.teks('Alamat', alamatLokasiDari(p)),
              BarisInfo.teks('Jam bayar', tampilWib(waktuBayar(p))),
            ]),
            const SizedBox(height: 24),
            TombolUtama(
              label: 'Konfirmasi Check In',
              loading: _loading,
              onPressed: _checkIn,
            ),
            const SizedBox(height: 10),
            TombolOutline(
              label: 'Batalkan Check In',
              onPressed: _loading ? null : () => kembaliKeKerangka(context, 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuSlot(Map<String, dynamic> p) {
    return KartuPutih(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          const Text('Slot kamu',
              style: TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(height: 4),
          Text(kodeSlotDari(p),
              style: const TextStyle(
                  fontSize: 72, fontWeight: FontWeight.w800, height: 1.1)),
          const SizedBox(height: 8),
          Text(namaLokasiDari(p),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Normal · dibayar untuk ${durasiDibayar(p) ?? '-'} jam',
              style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
        ],
      ),
    );
  }
}
