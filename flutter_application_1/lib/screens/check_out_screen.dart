import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/data_pemesanan.dart';
import '../services/pemesanan_service.dart';
import '../state/sesi_booking.dart';
import '../theme/app_theme.dart';
import '../widgets/komponen_pemesanan.dart';
import '../widgets/markir_widgets.dart';
import 'check_out_berhasil_screen.dart';
import 'struk_screen.dart';

/// Ubah huruf kecil jadi kapital saat mengetik.
class _HurufKapital extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue lama, TextEditingValue baru) {
    return baru.copyWith(text: baru.text.toUpperCase());
  }
}

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key, required this.pemesanan});

  /// Pemesanan berstatus check_in.
  final Map<String, dynamic> pemesanan;

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final _kode = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sudahCheckOut = false;

  @override
  void dispose() {
    _kode.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final kode = _kode.text.trim();
    setState(() {
      _loading = true;
      _error = null;
      _sudahCheckOut = false;
    });
    try {
      final svc = PemesananService();
      final hasil = await svc.checkOut(kode);
      final id = ((hasil['id'] ?? widget.pemesanan['id']) as num).toInt();
      // Ambil data lengkap (join lokasi/slot/pembayaran); jika gagal pakai hasil RPC.
      Map<String, dynamic> data;
      try {
        data = await svc.detail(id);
      } catch (_) {
        data = {...widget.pemesanan, ...hasil};
      }
      strukTerakhir.value = data;
      segarkanData();
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CheckOutBerhasilScreen(data: data)),
      );
    } catch (e) {
      if (!mounted) return;
      final pesan = PemesananService.pesanError(e);
      setState(() {
        _error = pesan;
        _sudahCheckOut = pesan.toLowerCase().contains('sudah check-out');
        _loading = false;
      });
    }
  }

  /// Cari struk booking yang sudah check-out (sesi ini, lalu riwayat).
  Future<void> _lihatStruk() async {
    final kode = _kode.text.trim();
    Map<String, dynamic>? data;
    final terakhir = strukTerakhir.value;
    if (terakhir != null && kodePesanan(terakhir) == kode) data = terakhir;
    if (data == null) {
      try {
        final semua = await PemesananService().riwayat();
        for (final r in semua) {
          if (kodePesanan(r) == kode && r['status'] == 'selesai') {
            data = r;
            break;
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    if (data == null) {
      pesanSnack(context, 'Struk untuk kode ini tidak ditemukan.');
      return;
    }
    final struk = data;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StrukScreen(data: struk)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pemesanan;
    return KerangkaLayarBooking(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TombolKembali('Kembali ke booking aktif'),
          const SizedBox(height: 4),
          const JudulLayar('Check-out',
              'Scan barcode booking di gerbang keluar untuk menyelesaikan parkir.'),
          KartuPutih(
            child: Column(
              children: [
                Text(kodeSlotDari(p),
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 4),
                Text(namaLokasiDari(p),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Normal · masuk ${tampilWib(waktuCheckIn(p))}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.slate500)),
                const SizedBox(height: 6),
                Text('Kode booking: ${kodePesanan(p)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            BannerPesan(_error!),
            if (_sudahCheckOut)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _lihatStruk,
                  child: const Text('Lihat struk'),
                ),
              ),
            const SizedBox(height: 12),
          ],
          LabelField(
            'Kode barcode',
            child: TextField(
              controller: _kode,
              autofocus: true,
              enabled: !_loading,
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [_HurufKapital()],
              onSubmitted: (_) => _loading ? null : _scan(),
              decoration: InputDecoration(
                hintText: 'Contoh: MKR-000123',
                counterText: '',
                fillColor: AppColors.latar,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.garis),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // TODO(kamera): ganti ketikan manual dengan pemindaian kamera
          // (butuh paket pemindai barcode; ditunda).
          const Text(
            'Simulasi pemindaian: ketik kode booking yang tertera pada barcode '
            '(format MKR- diikuti 6 angka, mis. MKR-000123).',
            style: TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 20),
          TombolUtama(
            label: _error == null ? 'Scan Barcode' : 'Coba lagi',
            loading: _loading,
            onPressed: _scan,
          ),
        ],
      ),
    );
  }
}
