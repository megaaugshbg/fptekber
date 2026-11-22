import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_in_screen.dart';
import 'check_out_screen.dart';
import 'pembayaran_screen.dart';
import 'struk_screen.dart';

/// Isi tab Booking: pesanan aktif milik pengguna.
class BookingAktifScreen extends StatefulWidget {
  const BookingAktifScreen({super.key});

  @override
  State<BookingAktifScreen> createState() => _BookingAktifScreenState();
}

class _BookingAktifScreenState extends State<BookingAktifScreen> {
  late Future<Map<String, dynamic>?> _aktif;

  @override
  void initState() {
    super.initState();
    _aktif = PemesananService().pesananAktif();
    versiData.addListener(_muatUlang);
    tabAktif.addListener(_saatTabBerubah);
  }

  @override
  void dispose() {
    versiData.removeListener(_muatUlang);
    tabAktif.removeListener(_saatTabBerubah);
    super.dispose();
  }

  void _saatTabBerubah() {
    if (tabAktif.value == 1) _muatUlang();
  }

  void _muatUlang() {
    if (!mounted) return;
    setState(() => _aktif = PemesananService().pesananAktif());
  }

  void _buka(Widget layar) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => layar));

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const JudulLayar('Booking Aktif', 'Booking yang sedang berjalan.'),
              FutureBuilder<Map<String, dynamic>?>(
                future: _aktif,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Column(
                      children: [
                        BannerPesan(PemesananService.pesanError(snap.error!)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _muatUlang,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    );
                  }
                  final p = snap.data;
                  return p == null ? _kosong() : _aktifKartu(p);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kosong() {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: strukTerakhir,
      builder: (context, struk, _) => KartuKosongPutus(
        judul: 'Tidak ada booking aktif',
        sub: 'Pesan slot parkir dari beranda untuk memulai.',
        aksi: [
          TombolUtama(
            label: 'Cari parkir',
            onPressed: () => tabAktif.value = 0,
          ),
          if (struk != null) ...[
            const SizedBox(height: 10),
            TombolOutline(
              label: 'Lihat struk terakhir (${kodePesanan(struk)})',
              onPressed: () => _buka(StrukScreen(data: struk)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aktifKartu(Map<String, dynamic> p) {
    final aksi = aksiBooking(p['status'] as String?);
    switch (aksi) {
      case AksiBooking.lanjutBayar:
        return _kartuSederhana(
          p,
          label: 'Lanjut ke pembayaran',
          onPressed: () => _buka(PembayaranScreen(pemesanan: p)),
        );
      case AksiBooking.checkIn:
        return _kartuSederhana(
          p,
          label: 'Check In',
          onPressed: () => _buka(CheckInScreen(pemesanan: p)),
        );
      case AksiBooking.parkirBerlangsung:
        return _kartuParkir(p);
      case AksiBooking.tidakAda:
        return _kosong();
    }
  }

  Widget _kartuSederhana(Map<String, dynamic> p,
      {required String label, required VoidCallback onPressed}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KartuBaris([
          BarisInfo.teks('Kode pesanan', kodePesanan(p), tebal: true),
          BarisInfo.teks('Lokasi', namaLokasiDari(p)),
          BarisInfo.teks('Slot (Normal)', kodeSlotDari(p), tebal: true),
          BarisInfo(
            'Status',
            PilStatus(labelStatus(p['status'] as String?),
                latar: AppColors.primerSoft, warna: AppColors.primer),
          ),
        ]),
        const SizedBox(height: 20),
        TombolUtama(label: label, onPressed: onPressed),
      ],
    );
  }

  Widget _kartuParkir(Map<String, dynamic> p) {
    final jam = durasiDibayar(p);
    final dibayar = jumlahDibayar(p);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KartuPutih(
          radius: 24,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const SizedBox(height: 24),
              Text(kodeSlotDari(p),
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.w800, height: 1.1)),
              const SizedBox(height: 4),
              Text(kodePesanan(p),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(namaLokasiDari(p),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('Normal · masuk ${tampilWib(waktuCheckIn(p))}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.slate500)),
              const SizedBox(height: 10),
              const PilStatus('Sedang parkir'),
              const SizedBox(height: 16),
              const Divider(),
              BarisInfo.teks('Waktu masuk', tampilWib(waktuCheckIn(p))),
              BarisInfo.teks(
                'Dibayar',
                dibayar == null
                    ? '-'
                    : '${formatRupiah(dibayar)} (${teksJam(jam)})',
                terakhir: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TombolUtama(
          label: 'Parkir Berlangsung',
          onPressed: () => _buka(CheckOutScreen(pemesanan: p)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pilih saat kamu akan keluar dari lokasi parkir untuk melakukan check-out.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.slate500),
        ),
      ],
    );
  }
}
