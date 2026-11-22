import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../services/lokasi_service.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';
import 'check_in_screen.dart';
import 'konfirmasi_pesanan_screen.dart';
import 'pilih_slot_screen.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({
    super.key,
    required this.profil,
    required this.kataKunci,
    required this.onHapusPencarian,
  });

  final Future<Map<String, dynamic>> profil;
  final String kataKunci;
  final VoidCallback onHapusPencarian;

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _lokasi = LokasiService();
  final _pemesanan = PemesananService();

  late Future<List<Map<String, dynamic>>> _daftarLokasi;
  late Future<Map<String, dynamic>?> _aktif;

  @override
  void initState() {
    super.initState();
    _muat();
    versiData.addListener(_muatAktif);
    tabAktif.addListener(_saatTabBerubah);
  }

  @override
  void dispose() {
    versiData.removeListener(_muatAktif);
    tabAktif.removeListener(_saatTabBerubah);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BerandaScreen old) {
    super.didUpdateWidget(old);
    if (old.kataKunci != widget.kataKunci) _muatLokasi();
  }

  void _muatLokasi() {
    setState(() {
      _daftarLokasi = _lokasi.cariLokasi(kataKunci: widget.kataKunci);
    });
  }

  void _muat() {
    _daftarLokasi = _lokasi.cariLokasi(kataKunci: widget.kataKunci);
    // Pesanan aktif hanya pelengkap: kalau gagal, banner tidak ditampilkan.
    _aktif = _pemesanan.pesananAktif().catchError((_) => null);
  }

  void _muatAktif() {
    if (!mounted) return;
    setState(() {
      _aktif = _pemesanan.pesananAktif().catchError((_) => null);
    });
  }

  void _saatTabBerubah() {
    if (tabAktif.value == 0) _muatAktif();
  }

  /// Banner pesanan aktif menuju layar yang sesuai status.
  void _bukaAktif(Map<String, dynamic> p) {
    switch (aksiBooking(p['status'] as String?)) {
      case AksiBooking.lanjutBayar:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KonfirmasiPesananScreen(pemesanan: p),
          ),
        );
      case AksiBooking.checkIn:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CheckInScreen(pemesanan: p)),
        );
      case AksiBooking.parkirBerlangsung:
        tabAktif.value = 1;
      case AksiBooking.tidakAda:
        break;
    }
  }

  Future<void> _bukaSlot(Map<String, dynamic> lokasi) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PilihSlotScreen(lokasi: lokasi)),
    );
    if (mounted) setState(_muat);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1152),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: widget.profil,
              builder: (context, snap) {
                final nama = (snap.data?['nama'] as String?)?.trim() ?? '';
                final depan = nama.isEmpty ? '' : nama.split(RegExp(r'\s+')).first;
                return Text(
                  depan.isEmpty
                      ? 'Halo! Mau parkir di mana?'
                      : 'Halo, $depan! Mau parkir di mana?',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.slate500),
                );
              },
            ),
            const SizedBox(height: 12),
            _bannerAktif(),
            _judul(),
            const SizedBox(height: 12),
            _chipFilter(),
            const SizedBox(height: 16),
            _daftar(),
          ],
        ),
      ),
    );
  }

  Widget _bannerAktif() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _aktif,
      builder: (context, snap) {
        final p = snap.data;
        if (p == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: AppColors.permukaanAlt,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _bukaAktif(p),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Kamu punya pesanan aktif '),
                          TextSpan(
                            text: kodePesanan(p),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ]),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _judul() {
    final cari = widget.kataKunci;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _daftarLokasi,
      builder: (context, snap) {
        final n = snap.data?.length;
        final info = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            if (cari.isNotEmpty)
              Text('Hasil untuk “$cari” ·',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.slate500)),
            if (cari.isNotEmpty)
              InkWell(
                onTap: widget.onHapusPencarian,
                child: const Text(
                  'Hapus pencarian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            else if (n != null)
              Text('$n lokasi',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.slate500)),
          ],
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Mal',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: info,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _chipFilter() {
    return Wrap(
      spacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Semua',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onPrimer,
            ),
          ),
        ),
        // TODO(geolokasi): aktifkan setelah posisi pengguna tersedia
        // (LokasiService.cariLokasi sudah mendukung latUser/lngUser).
        Tooltip(
          message: 'Izinkan akses lokasi untuk memakai filter ini',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate200.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Terdekat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _daftar() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _daftarLokasi,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data ?? [];
        if (snap.hasError) {
          return _kosong(
            'Data lahan parkir belum tersedia',
            'Silakan coba lagi nanti.',
          );
        }
        if (data.isEmpty) {
          if (widget.kataKunci.isNotEmpty) {
            return _kosong(
              'Tidak ada mal yang cocok',
              'Coba kata kunci lain.',
              tombol: 'Tampilkan semua mal',
            );
          }
          return _kosong(
            'Data lahan parkir belum tersedia',
            'Silakan coba lagi nanti.',
          );
        }
        return LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= batasDesktop) {
              final kolom = c.maxWidth >= 1100 ? 4 : 3;
              const jarak = 16.0;
              final lebar = (c.maxWidth - jarak * (kolom - 1)) / kolom;
              return Wrap(
                spacing: jarak,
                runSpacing: jarak,
                children: [
                  for (final l in data)
                    SizedBox(
                      width: lebar,
                      child: _KartuMal(data: l, onTap: () => _bukaSlot(l)),
                    ),
                ],
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final l in data)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: 264,
                          child: _KartuMal(data: l, onTap: () => _bukaSlot(l)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _kosong(String judul, String sub, {String? tombol}) {
    return CustomPaint(
      painter: DashedBorderPainter(warna: AppColors.garis),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(judul,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.slate500)),
            if (tombol != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: TombolUtama(
                  label: tombol,
                  onPressed: widget.onHapusPencarian,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatJarak(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Kartu satu mal (tanpa foto; bagian atas = blok ikon).
class _KartuMal extends StatefulWidget {
  const _KartuMal({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  State<_KartuMal> createState() => _KartuMalState();
}

class _KartuMalState extends State<_KartuMal> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final nama = (d['nama'] as String?) ?? '-';
    final alamat = (d['alamat'] as String?) ?? '';
    final tarif = d['tarif_per_jam'] as num?;
    final slot = (d['slot_tersedia'] as int?) ?? 0;
    final jarak = d['jarak_km'] as double?;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.permukaan,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.garis),
          boxShadow: bayanganKartu,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 96,
                  width: double.infinity,
                  color: AppColors.permukaanAlt,
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.local_parking_rounded,
                            size: 44, color: AppColors.primer),
                      ),
                      if (jarak != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.navigation_rounded, size: 12),
                                const SizedBox(width: 4),
                                Text(_formatJarak(jarak),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alamat,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (slot > 0)
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                  text: '$slot',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const TextSpan(
                                  text: ' slot kosong',
                                  style: TextStyle(color: AppColors.slate500),
                                ),
                              ]),
                              style: const TextStyle(fontSize: 13),
                            )
                          else
                            const Text('Slot penuh',
                                style: TextStyle(
                                    fontSize: 13, color: AppColors.slate500)),
                          const SizedBox(width: 8),
                          if (slot > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primerSoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text('Normal',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      if (tarif != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${formatRupiah(tarif)}/jam',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
