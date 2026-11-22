import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_out_berhasil_screen.dart' show ringkasDurasi;
import 'riwayat_screen.dart' show BadgeStatusRiwayat;

/// Detail satu riwayat booking.
/// Selesai: struk parkir lengkap. Dibatalkan: rincian pesanan + hapus.
class RiwayatDetailScreen extends StatelessWidget {
  const RiwayatDetailScreen({super.key, required this.pemesanan});

  /// Pemesanan dari daftar riwayat (sudah berisi join slot/lokasi/pembayaran).
  final Map<String, dynamic> pemesanan;

  @override
  Widget build(BuildContext context) {
    return KerangkaLayarBooking(
      child: MuatPemesanan(
        id: (pemesanan['id'] as num).toInt(),
        awal: pemesanan,
        builder: (context, data) => _Isi(data: data),
      ),
    );
  }
}

class _Isi extends StatefulWidget {
  const _Isi({required this.data});

  final Map<String, dynamic> data;

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  bool _menghapus = false;

  Map<String, dynamic> get _p => widget.data;
  bool get _selesai => _p['status'] == 'selesai';

  Future<void> _hapus() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dari riwayat?'),
        content: Text(
          'Booking ${kodePesanan(_p)} akan dihapus permanen dari riwayatmu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.merah),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !mounted) return;

    setState(() => _menghapus = true);
    try {
      await PemesananService().hapus((_p['id'] as num).toInt());
      segarkanData();
      if (!mounted) return;
      pesanSnack(context, 'Riwayat ${kodePesanan(_p)} dihapus.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) pesanSnack(context, PemesananService.pesanError(e));
    } finally {
      if (mounted) setState(() => _menghapus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TombolKembali('Kembali ke riwayat'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _selesai ? 'Struk Parkir' : 'Booking Dibatalkan',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            BadgeStatusRiwayat(_p['status'] as String?),
          ],
        ),
        const SizedBox(height: 16),
        if (_selesai) ..._struk() else ..._dibatalkan(),
        const SizedBox(height: 24),
        if (!_selesai) ...[
          OutlinedButton.icon(
            onPressed: _menghapus ? null : _hapus,
            icon: _menghapus
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus dari riwayat'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.merah,
              side: const BorderSide(color: AppColors.merah200, width: 2),
            ),
          ),
          const SizedBox(height: 12),
        ],
        TombolUtama(
          label: 'Kembali ke daftar',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  /// Booking selesai: sama dengan struk check-out versi lengkap di PPPL.
  List<Widget> _struk() {
    final d = ringkasDurasi(_p);
    final dibayar = jumlahDibayar(_p);
    final total = totalBiaya(_p);
    final metode = metodePembayaran(_p);
    final idBayar = idPembayaran(_p);

    return [
      KartuBaris([
        BarisInfo.teks('Kode booking', kodePesanan(_p), tebal: true),
        BarisInfo.teks('Lokasi', namaLokasiDari(_p)),
        BarisInfo.teks('Alamat', alamatLokasiDari(_p)),
        BarisInfo.teks('Slot', kodeSlotDari(_p), tebal: true),
        BarisInfo.teks('Tipe parkir', tipeSlotDari(_p)),
        BarisInfo.teks('Waktu masuk', tampilWib(waktuCheckIn(_p))),
        BarisInfo.teks('Waktu keluar', tampilWib(waktuCheckOut(_p))),
        BarisInfo.teks('Durasi parkir', teksJam(d.aktual)),
        BarisInfo.teks('Durasi dibayar', teksJam(durasiDibayar(_p))),
        if (metode != null) BarisInfo.teks('Metode pembayaran', metode),
        if (idBayar != null)
          BarisInfo.teks('No. transaksi', nomorTransaksi(idBayar)),
        BarisInfo.teks(
            'Sudah dibayar', dibayar == null ? '-' : formatRupiah(dibayar)),
        BarisInfo.teks(
          'Total biaya parkir',
          total == null ? '-' : formatRupiah(total),
          tebal: true,
        ),
      ]),
      if (d.lebih > 0) ...[
        const SizedBox(height: 12),
        BannerPesan(
          'Melebihi durasi yang dibayar ${d.lebih} jam',
          error: false,
        ),
      ],
      const SizedBox(height: 12),
      const Text(
        'Biaya parkir dibayar sebelum check in.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.slate500),
      ),
    ];
  }

  /// Booking dibatalkan sebelum dibayar: tanpa biaya.
  List<Widget> _dibatalkan() {
    return [
      KartuBaris([
        BarisInfo.teks('Kode booking', kodePesanan(_p), tebal: true),
        BarisInfo.teks('Lokasi', namaLokasiDari(_p)),
        BarisInfo.teks('Alamat', alamatLokasiDari(_p)),
        BarisInfo.teks('Slot', kodeSlotDari(_p), tebal: true),
        BarisInfo.teks('Tipe parkir', tipeSlotDari(_p)),
        BarisInfo.teks('Waktu dipesan', tampilWib(waktuDipesan(_p))),
        BarisInfo('Status', BadgeStatusRiwayat(_p['status'] as String?)),
      ]),
      const SizedBox(height: 12),
      const Text(
        'Pesanan ini dibatalkan sebelum dibayar, jadi tidak ada biaya.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.slate500),
      ),
    ];
  }
}