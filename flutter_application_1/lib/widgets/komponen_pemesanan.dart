import 'package:flutter/material.dart';

import '../services/pemesanan_service.dart';
import '../theme/app_theme.dart';
import 'kerangka_markir.dart';
import 'markir_widgets.dart';

/// Kembali ke kerangka utama (Beranda/Booking) dan pilih tab tujuan.
void kembaliKeKerangka(BuildContext context, [int tab = 0]) {
  tabAktif.value = tab;
  Navigator.of(context).popUntil((r) => r.isFirst);
}

/// Kerangka layar alur booking: navbar atas, isi di tengah (maks 448),
/// navigasi bawah di HP.
class KerangkaLayarBooking extends StatelessWidget {
  const KerangkaLayarBooking({super.key, required this.child, this.navIndex = 1});

  final Widget child;
  final int navIndex;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= batasDesktop;
    return Scaffold(
      body: Column(
        children: [
          const NavbarAtas(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(desktop ? 32 : 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : NavBawah(
              index: navIndex,
              onTap: (i) => kembaliKeKerangka(context, i),
            ),
    );
  }
}

/// Tombol "‹ Kembali ..." bergaya Pilih Slot.
class TombolKembali extends StatelessWidget {
  const TombolKembali(this.label, {super.key, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed ?? () => Navigator.pop(context),
        icon: const Icon(Icons.chevron_left_rounded),
        label: Text(label),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }
}

/// Judul layar + sub abu-abu.
class JudulLayar extends StatelessWidget {
  const JudulLayar(this.judul, this.sub, {super.key});

  final String judul;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(judul,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(sub,
            style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Lingkaran emerald + centang.
class IkonCentang extends StatelessWidget {
  const IkonCentang({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

/// Pil status kecil (default emerald).
class PilStatus extends StatelessWidget {
  const PilStatus(this.teks,
      {super.key, this.latar = AppColors.emerald50, this.warna = AppColors.emerald700});

  final String teks;
  final Color latar;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teks,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: warna),
      ),
    );
  }
}

/// Kartu putih berisi baris label-nilai (gaya layar Konfirmasi).
class KartuBaris extends StatelessWidget {
  const KartuBaris(this.baris, {super.key});

  final List<BarisInfo> baris;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.garis),
        boxShadow: bayanganKartu,
      ),
      child: Column(
        children: [
          for (var i = 0; i < baris.length; i++)
            BarisInfo(
              baris[i].label,
              baris[i].nilai,
              tebal: baris[i].tebal,
              terakhir: i == baris.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Satu baris: label slate-500 di kiri, nilai di kanan.
class BarisInfo extends StatelessWidget {
  const BarisInfo(this.label, this.nilai,
      {super.key, this.tebal = false, this.terakhir = false});

  final String label;
  final Widget nilai;
  final bool tebal;
  final bool terakhir;

  /// Versi teks biasa.
  factory BarisInfo.teks(String label, String teks,
          {bool tebal = false, bool terakhir = false}) =>
      BarisInfo(label, Text(teks, textAlign: TextAlign.right),
          tebal: tebal, terakhir: terakhir);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: terakhir
            ? null
            : const Border(bottom: BorderSide(color: AppColors.garis)),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
                ),
                child: nilai,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu kosong bergaris putus-putus.
class KartuKosongPutus extends StatelessWidget {
  const KartuKosongPutus({super.key, required this.judul, required this.sub, this.aksi});

  final String judul;
  final String sub;
  final List<Widget>? aksi;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(warna: AppColors.garis),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(judul,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
            if (aksi != null) ...[
              const SizedBox(height: 16),
              ...aksi!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Memuat pemesanan lengkap (dengan join slot/lokasi/pembayaran).
/// [awal] dipakai langsung bila sudah berisi join slot dan [paksa] false.
class MuatPemesanan extends StatefulWidget {
  const MuatPemesanan({
    super.key,
    required this.id,
    required this.builder,
    this.awal,
    this.paksa = false,
  });

  final int id;
  final Map<String, dynamic>? awal;
  final bool paksa;
  final Widget Function(BuildContext context, Map<String, dynamic> data) builder;

  @override
  State<MuatPemesanan> createState() => _MuatPemesananState();
}

class _MuatPemesananState extends State<MuatPemesanan> {
  late Future<Map<String, dynamic>> _data;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    final a = widget.awal;
    _data = (!widget.paksa && a != null && a['slot'] is Map)
        ? Future.value(a)
        : PemesananService().detail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _data,
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
                onPressed: () => setState(_muat),
                child: const Text('Coba lagi'),
              ),
            ],
          );
        }
        return widget.builder(context, snap.data!);
      },
    );
  }
}
