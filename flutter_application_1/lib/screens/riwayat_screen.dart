import 'package:flutter/material.dart';

import '../services/data_pemesanan.dart';
import '../services/format_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'booking_screen.dart';
import 'riwayat_detail_screen.dart';

/// Riwayat Booking: pesanan milik pengguna yang sudah selesai atau dibatalkan.
/// Sama dengan halaman riwayat PPPL: filter status, 10 per halaman,
/// tap item untuk melihat detail.
class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  static const _perHalaman = 10;

  /// null = semua, 'selesai', atau 'dibatalkan'.
  String? _filter;
  final List<Map<String, dynamic>> _data = [];
  int _halaman = 0;
  bool _habis = false;
  bool _memuat = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _muatUlang();
    versiData.addListener(_muatUlang);
    subTabBooking.addListener(_saatSubTabBerubah);
  }

  @override
  void dispose() {
    versiData.removeListener(_muatUlang);
    subTabBooking.removeListener(_saatSubTabBerubah);
    super.dispose();
  }

  void _saatSubTabBerubah() {
    if (subTabBooking.value == 1) _muatUlang();
  }

  /// Naik setiap kali daftar dimuat ulang, supaya hasil permintaan lama
  /// (mis. filter sebelumnya) diabaikan.
  int _token = 0;

  Future<void> _muatUlang() async {
    if (!mounted) return;
    _token++;
    setState(() {
      _data.clear();
      _halaman = 0;
      _habis = false;
      _error = null;
      _memuat = false;
    });
    await _muatHalaman();
  }

  Future<void> _muatHalaman() async {
    if (_memuat || _habis) return;
    final token = _token;
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final hasil = await PemesananService().daftarRiwayat(
        status: _filter,
        halaman: _halaman,
        perHalaman: _perHalaman,
      );
      if (!mounted || token != _token) return;
      setState(() {
        _data.addAll(hasil);
        _halaman++;
        _habis = hasil.length < _perHalaman;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = e;
        _memuat = false;
      });
    }
  }

  void _gantiFilter(String? status) {
    if (status == _filter) return;
    _filter = status;
    _muatUlang();
  }

  void _bukaDetail(Map<String, dynamic> p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RiwayatDetailScreen(pemesanan: p)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: RefreshIndicator(
          onRefresh: _muatUlang,
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const JudulLayar(
                'Riwayat Booking',
                'Booking yang sudah selesai atau dibatalkan.',
              ),
              _chipFilter(),
              const SizedBox(height: 16),
              ..._isi(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipFilter() {
    const pilihan = <String?, String>{
      null: 'Semua',
      'selesai': 'Selesai',
      'dibatalkan': 'Dibatalkan',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in pilihan.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: e.value,
                aktif: _filter == e.key,
                onTap: () => _gantiFilter(e.key),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _isi() {
    if (_data.isEmpty && _memuat) {
      return const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_data.isEmpty && _error != null) {
      return [
        BannerPesan(PemesananService.pesanError(_error!)),
        const SizedBox(height: 12),
        TextButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
      ];
    }
    if (_data.isEmpty) return [_kosong()];

    return [
      for (final p in _data)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ItemRiwayat(data: p, onTap: () => _bukaDetail(p)),
        ),
      if (_error != null) ...[
        BannerPesan(PemesananService.pesanError(_error!)),
        const SizedBox(height: 12),
      ],
      if (!_habis)
        _memuat
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            : TombolOutline(
                label: 'Muat lebih banyak',
                onPressed: _muatHalaman,
              ),
    ];
  }

  Widget _kosong() {
    final judul = switch (_filter) {
      'selesai' => 'Belum ada booking yang selesai',
      'dibatalkan' => 'Belum ada booking yang dibatalkan',
      _ => 'Belum ada riwayat booking',
    };
    return KartuKosongPutus(
      judul: judul,
      sub: 'Booking yang sudah check-out atau dibatalkan akan muncul di sini.',
      aksi: [
        if (_filter != null) ...[
          TombolOutline(
            label: 'Lihat semua riwayat',
            onPressed: () => _gantiFilter(null),
          ),
          const SizedBox(height: 10),
        ],
        TombolUtama(
          label: 'Cari parkir',
          onPressed: () => tabAktif.value = 0,
        ),
      ],
    );
  }
}

/// Chip filter status (Semua / Selesai / Dibatalkan).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.aktif, required this.onTap});

  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: aktif ? AppColors.primer : AppColors.permukaan,
      shape: StadiumBorder(
        side: BorderSide(color: aktif ? AppColors.primer : AppColors.garis),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: aktif ? AppColors.onPrimer : AppColors.primer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu kartu di daftar riwayat.
class _ItemRiwayat extends StatelessWidget {
  const _ItemRiwayat({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String?;
    final selesai = status == 'selesai';
    final total = totalBiaya(data);

    return Material(
      color: AppColors.permukaan,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.garis),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            namaLokasiDari(data),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BadgeStatusRiwayat(status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tipeSlotDari(data)} · Slot ${kodeSlotDari(data)} · '
                      '${kodePesanan(data)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            tampilWib(waktuRiwayat(data)),
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.slate500),
                          ),
                        ),
                        if (selesai)
                          Text(
                            total == null ? '-' : formatRupiah(total),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          )
                        else
                          const Text(
                            'Dibatalkan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.slate500),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge status riwayat: selalu teks + ikon (tidak hanya warna).
class BadgeStatusRiwayat extends StatelessWidget {
  const BadgeStatusRiwayat(this.status, {super.key});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final selesai = status == 'selesai';
    final batal = status == 'dibatalkan';
    final latar = selesai
        ? AppColors.emerald50
        : batal
            ? AppColors.permukaanAlt
            : AppColors.primerSoft;
    final warna = selesai
        ? AppColors.emerald700
        : batal
            ? AppColors.slate500
            : AppColors.primer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selesai || batal) ...[
            Icon(selesai ? Icons.check_rounded : Icons.close_rounded,
                size: 14, color: warna),
            const SizedBox(width: 4),
          ],
          Text(
            labelStatus(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}