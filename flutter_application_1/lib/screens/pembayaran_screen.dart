import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'pembayaran_berhasil_screen.dart';

class PembayaranScreen extends StatelessWidget {
  const PembayaranScreen({super.key, required this.pemesanan});

  /// Hasil pesan() atau pesananAktif().
  final Map<String, dynamic> pemesanan;

  @override
  Widget build(BuildContext context) {
    final id = (pemesanan['id'] as num).toInt();
    return KerangkaLayarBooking(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TombolKembali('Kembali ke pesanan'),
          const SizedBox(height: 4),
          const JudulLayar(
              'Pembayaran', 'Cek rincian tagihan, lalu bayar sebelum check in.'),
          MuatPemesanan(
            id: id,
            awal: pemesanan,
            builder: (_, data) => _FormBayar(pemesanan: data),
          ),
        ],
      ),
    );
  }
}

class _FormBayar extends StatefulWidget {
  const _FormBayar({required this.pemesanan});

  final Map<String, dynamic> pemesanan;

  @override
  State<_FormBayar> createState() => _FormBayarState();
}

class _FormBayarState extends State<_FormBayar> {
  int _durasi = 2;
  bool _loading = false;
  String? _error;

  int get _id => (widget.pemesanan['id'] as num).toInt();

  Future<void> _bayar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PemesananService().bayar(_id, _durasi, metode: 'QRIS');
      segarkanData();
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PembayaranBerhasilScreen(id: _id)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PemesananService.pesanError(e);
        _loading = false;
      });
    }
  }

  Future<void> _batalkan() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan pembayaran?'),
        content: const Text('Pesanan ini akan dibatalkan dan slot dilepas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ya != true || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await PemesananService().batalkan(_id);
      segarkanData();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      kembaliKeKerangka(context, 0);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Pesanan dibatalkan.'),
          behavior: SnackBarBehavior.floating,
        ));
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
    final p = widget.pemesanan;
    final tarif = tarifPerJamDari(p);
    final total = tarif == null ? null : tarif * _durasi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          BannerPesan(_error!),
          const SizedBox(height: 12),
        ],
        KartuPutih(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Rincian tagihan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _ringkas('Lokasi', namaLokasiDari(p)),
              _ringkas('Slot', kodeSlotDari(p)),
              _ringkas('Tarif / jam', tarif == null ? '-' : formatRupiah(tarif)),
              const SizedBox(height: 16),
              const Text('Lama parkir',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var j = 1; j <= 6; j++) _pilJam(j),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Metode pembayaran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primer, width: 1.5),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('QRIS',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text(
                            'Scan pakai e-wallet atau m-banking yang mendukung QRIS.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.slate500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Total biaya ($_durasi jam)',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.slate500)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                total == null ? '-' : formatRupiah(total),
                style:
                    const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TombolUtama(
          label: 'Konfirmasi Pembayaran',
          loading: _loading,
          onPressed: _bayar,
        ),
        const SizedBox(height: 10),
        TombolOutline(
          label: 'Batalkan Pembayaran',
          onPressed: _loading ? null : _batalkan,
        ),
      ],
    );
  }

  Widget _ringkas(String label, String nilai) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.slate500)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(nilai,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _pilJam(int jam) {
    final aktif = _durasi == jam;
    return Material(
      color: aktif ? AppColors.primerSoft : AppColors.permukaan,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: _loading ? null : () => setState(() => _durasi = jam),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: aktif ? AppColors.primer : AppColors.garis,
              width: aktif ? 1.5 : 1,
            ),
          ),
          child: Text('$jam jam',
              style: TextStyle(
                fontSize: 14,
                fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
              )),
        ),
      ),
    );
  }
}
