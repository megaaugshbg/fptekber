import 'dart:async';

import 'package:flutter/material.dart';

import '../services/format_pemesanan.dart';
import '../services/lokasi_service.dart';
import '../services/pemesanan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';
import 'konfirmasi_pesanan_screen.dart';

const _garisDenah = Color(0x38111178); // primer 22%

class PilihSlotScreen extends StatefulWidget {
  const PilihSlotScreen({super.key, required this.lokasi});

  /// Satu baris dari LokasiService.cariLokasi (id, nama, alamat, tarif_per_jam).
  final Map<String, dynamic> lokasi;

  @override
  State<PilihSlotScreen> createState() => _PilihSlotScreenState();
}

class _PilihSlotScreenState extends State<PilihSlotScreen> {
  final _pemesanan = PemesananService();
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  List<Map<String, dynamic>>? _slot; // null = belum ada data
  Object? _errorStream;
  int? _dipilih; // id slot
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final id = (widget.lokasi['id'] as num).toInt();
    _sub = LokasiService().streamSlot(id).listen(
      (rows) {
        if (!mounted) return;
        setState(() {
          _slot = rows;
          _errorStream = null;
          // Slot yang dipilih direbut orang lain → batalkan pilihan.
          if (_dipilih != null) {
            final s = rows.where((r) => r['id'] == _dipilih);
            if (s.isEmpty || s.first['status'] != 'tersedia') {
              _dipilih = null;
              _error = 'Slot telah dipesan pengguna lain. Silakan pilih slot lain.';
            }
          }
        });
      },
      onError: (Object e) {
        if (mounted) setState(() => _errorStream = e);
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _tersedia(Map<String, dynamic> s) => s['status'] == 'tersedia';

  void _pilih(Map<String, dynamic> s) {
    setState(() {
      _error = null;
      _dipilih = _dipilih == s['id'] ? null : (s['id'] as num).toInt();
    });
  }

  Future<void> _pesan() async {
    final id = _dipilih;
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final hasil = await _pemesanan.pesan(id);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => KonfirmasiPesananScreen(pemesanan: hasil),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = PemesananService.pesanError(e);
        _dipilih = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    final desktop = lebar >= batasDesktop;
    final dua = lebar >= 1024;
    final nama = (widget.lokasi['nama'] as String?) ?? '-';
    final alamat = (widget.lokasi['alamat'] as String?) ?? '';

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded),
          label: const Text('Kembali'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
        ),
        const SizedBox(height: 4),
        Text('Pilih Slot Parkir',
            style: TextStyle(
                fontSize: dua ? 30 : 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('$nama · $alamat',
            style:
                const TextStyle(fontSize: 14, color: AppColors.slate500)),
        const SizedBox(height: 16),
      ],
    );

    final denah = _kolomDenah(desktop);
    final ringkasan = _ringkasan();

    return Scaffold(
      body: Column(
        children: [
          const NavbarAtas(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1152),
                child: dua
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            header,
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(child: denah),
                                  ),
                                  const SizedBox(width: 24),
                                  // Panel ringkasan tetap di tempat (sticky).
                                  SizedBox(
                                    width: 380,
                                    child: SingleChildScrollView(
                                        child: ringkasan),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          header,
                          denah,
                          const SizedBox(height: 16),
                          ringkasan,
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: desktop
          ? null
          : NavBawah(
              index: 0,
              onTap: (i) {
                tabAktif.value = i;
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
    );
  }

  // ---------- Denah ----------

  Widget _kolomDenah(bool desktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          BannerPesan(_error!),
          const SizedBox(height: 12),
        ],
        KartuPutih(
          radius: 24,
          padding: EdgeInsets.all(desktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _legenda(),
              const SizedBox(height: 20),
              _denah(desktop),
              const SizedBox(height: 16),
              Text(
                '↓ Pintu Masuk',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legenda() {
    final n = _slot?.where(_tersedia).length ?? 0;
    Widget item(Color isi, Color? garis, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isi,
                borderRadius: BorderRadius.circular(4),
                border: garis == null ? null : Border.all(color: garis),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        item(AppColors.slate500, null, 'Terisi'),
        item(AppColors.permukaan, AppColors.primer, 'Tersedia ($n)'),
        item(AppColors.primerSoft, AppColors.primer, 'Dipilih'),
      ],
    );
  }

  Widget _denah(bool desktop) {
    if (_errorStream != null && _slot == null) {
      return const BannerPesan('Denah slot gagal dimuat. Silakan coba lagi.');
    }
    final slot = _slot;
    if (slot == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (slot.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Belum ada slot di lokasi ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.slate500)),
      );
    }

    final urut = urutkanSlot(slot);
    final tengah = (urut.length / 2).ceil();
    final kiri = urut.sublist(0, tengah);
    final kanan = urut.sublist(tengah);
    final tinggi = desktop ? 104.0 : 84.0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _garisDenah, width: 2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final s in kiri) _bay(s, tinggi, kiri: true),
                ],
              ),
            ),
            SizedBox(
              width: desktop ? 90 : 40,
              child: const GarisVertikalPutus(),
            ),
            Expanded(
              child: Column(
                children: [
                  for (final s in kanan) _bay(s, tinggi, kiri: false),
                  // Jaga tinggi jika kolom kanan lebih pendek.
                  if (kanan.length < kiri.length) SizedBox(height: tinggi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bay(Map<String, dynamic> s, double tinggi, {required bool kiri}) {
    final terisi = !_tersedia(s);
    final dipilih = _dipilih == s['id'];
    final kode = (s['kode_slot'] ?? '').toString();

    final sisiLuar = kiri
        ? const Border(
            left: BorderSide(color: _garisDenah, width: 2),
            bottom: BorderSide(color: _garisDenah, width: 2),
          )
        : const Border(
            right: BorderSide(color: _garisDenah, width: 2),
            bottom: BorderSide(color: _garisDenah, width: 2),
          );

    Widget isi = Stack(
      children: [
        if (terisi)
          Center(
            child: Transform.flip(
              flipX: !kiri,
              child: const Icon(Icons.directions_car_filled,
                  size: 40, color: AppColors.slate500),
            ),
          ),
        if (dipilih)
          Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey('mobil-${s['id']}'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * -28),
                  child: child,
                ),
              ),
              child: Transform.flip(
                flipX: !kiri,
                child: const Icon(Icons.directions_car_filled,
                    size: 40, color: AppColors.primer),
              ),
            ),
          ),
        Positioned(
          bottom: 6,
          left: kiri ? 10 : null,
          right: kiri ? null : 10,
          child: Opacity(
            opacity: terisi ? 0.45 : 1,
            child: Text(
              dipilih ? '$kode · Terpilih' : kode,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primer,
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      height: tinggi,
      decoration: BoxDecoration(
        border: sisiLuar,
        color: dipilih ? AppColors.primerSoft : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: terisi ? null : () => _pilih(s),
          hoverColor: AppColors.primerSoft,
          highlightColor: AppColors.primerSoft,
          child: isi,
        ),
      ),
    );
  }

  // ---------- Ringkasan ----------

  Widget _ringkasan() {
    final tarif = widget.lokasi['tarif_per_jam'] as num?;
    final tersedia = _slot?.where(_tersedia).length;
    final kodeDipilih = _slot
        ?.where((s) => s['id'] == _dipilih)
        .map((s) => (s['kode_slot'] ?? '').toString())
        .firstOrNull;

    Widget baris(String label, String nilai) => Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.garis)),
          ),
          child: Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.slate500)),
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

    return KartuPutih(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Ringkasan Pesanan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          baris('Tempat', (widget.lokasi['nama'] as String?) ?? '-'),
          baris('Tipe parkir', 'Normal'),
          baris('Slot tersedia', tersedia?.toString() ?? '-'),
          if (kodeDipilih != null) baris('Slot dipilih', kodeDipilih),
          const SizedBox(height: 16),
          const Text('Tarif parkir',
              style: TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(height: 2),
          Text(
            tarif == null ? '-' : '${formatRupiah(tarif)} / jam',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          TombolUtama(
            label: 'Pesan Slot',
            loading: _loading,
            onPressed: _dipilih == null ? null : _pesan,
          ),
          const SizedBox(height: 10),
          TombolOutline(
            label: 'Batal',
            onPressed: _loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
