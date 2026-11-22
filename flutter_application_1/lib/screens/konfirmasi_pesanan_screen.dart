import 'package:flutter/material.dart';

import '../services/format_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';
import 'segera_hadir_screen.dart';

/// Kode pesanan tampilan, mis. MKR-000123.
String kodePesanan(Map<String, dynamic> p) {
  final kode = p['kode_booking'];
  if (kode is String && kode.isNotEmpty) return kode;
  return 'MKR-${(p['id'] ?? '').toString().padLeft(6, '0')}';
}

String _labelStatus(String? s) {
  switch (s) {
    case 'menunggu_bayar':
      return 'Menunggu bayar';
    case 'dibayar':
      return 'Dibayar';
    case 'check_in':
      return 'Check-in';
    case 'selesai':
      return 'Selesai';
    case 'dibatalkan':
      return 'Dibatalkan';
    default:
      return s ?? '-';
  }
}

class KonfirmasiPesananScreen extends StatefulWidget {
  const KonfirmasiPesananScreen({super.key, required this.pemesanan});

  /// Hasil PemesananService.pesan() atau pesananAktif().
  final Map<String, dynamic> pemesanan;

  @override
  State<KonfirmasiPesananScreen> createState() =>
      _KonfirmasiPesananScreenState();
}

class _KonfirmasiPesananScreenState extends State<KonfirmasiPesananScreen> {
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    final p = widget.pemesanan;
    // Hasil RPC mungkin belum berisi join lokasi & slot.
    _data = p['slot'] is Map
        ? Future.value(p)
        : PemesananService().detail((p['id'] as num).toInt());
  }

  void _kembaliKeBeranda([int tab = 0]) {
    tabAktif.value = tab;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= batasDesktop;
    return Scaffold(
      body: Column(
        children: [
          const NavbarAtas(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _data,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BannerPesan(PemesananService.pesanError(
                              snap.error!)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => setState(_muat),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _isi(snap.data!);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : NavBawah(index: 0, onTap: _kembaliKeBeranda),
    );
  }

  Widget _isi(Map<String, dynamic> p) {
    final slot = (p['slot'] as Map?) ?? const {};
    final lokasi = (slot['lokasi'] as Map?) ?? const {};
    final tarif = lokasi['tarif_per_jam'] as num?;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.emerald100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 32, color: AppColors.emerald600),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan berhasil',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  const TextSpan(
                    text: 'Kode pesanan ',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                  TextSpan(
                    text: kodePesanan(p),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ]),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.permukaan,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.garis),
                  boxShadow: bayanganKartu,
                ),
                child: Column(
                  children: [
                    _baris('Lokasi', Text('${lokasi['nama'] ?? '-'}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    _baris('Alamat', Text('${lokasi['alamat'] ?? '-'}',
                        textAlign: TextAlign.right)),
                    _baris('Tipe slot', const Text('Normal')),
                    _baris('Slot', Text('${slot['kode_slot'] ?? '-'}',
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                    _baris(
                      'Tarif parkir',
                      Text(tarif == null ? '-' : '${formatRupiah(tarif)}/jam'),
                    ),
                    _baris(
                      'Status',
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelStatus(p['status'] as String?),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.emerald700,
                          ),
                        ),
                      ),
                      terakhir: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TombolUtama(
                label: 'Lanjut ke pembayaran',
                // TODO(pembayaran): ganti dengan layar pembayaran (tahap berikutnya).
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SegeraHadirScreen(judul: 'Pembayaran'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _kembaliKeBeranda,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.garis),
                ),
                child: const Text('Kembali ke beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(String label, Widget nilai, {bool terakhir = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: terakhir
            ? null
            : const Border(bottom: BorderSide(color: AppColors.garis)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 14),
                child: nilai,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
