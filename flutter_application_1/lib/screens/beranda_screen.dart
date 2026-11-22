import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/format_pemesanan.dart';
import '../services/lokasi_service.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/markir_widgets.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  final _auth = AuthService();
  final _lokasi = LokasiService();
  final _cari = TextEditingController();
  Timer? _debounce;

  int _tab = 1; // 0 Pengaturan, 1 Beranda, 2 Akun

  late Future<Map<String, dynamic>> _profil;
  late Future<List<Map<String, dynamic>>> _daftarLokasi;

  @override
  void initState() {
    super.initState();
    _profil = _auth.ambilProfil();
    _daftarLokasi = _lokasi.cariLokasi();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _muatLokasi() {
    setState(() {
      _daftarLokasi = _lokasi.cariLokasi(kataKunci: _cari.text);
    });
  }

  /// Tunggu 400 ms setelah user berhenti mengetik, baru cari.
  void _onCariBerubah(String _) {
    setState(() {}); // untuk memunculkan tombol hapus
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _muatLokasi();
    });
  }

  Future<void> _keluar() async {
    try {
      await _auth.keluar();
      // AuthGate otomatis kembali ke halaman Login.
    } catch (e) {
      if (mounted) pesanSnack(context, AuthService.pesanError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LogoMarkir(besar: false),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => pesanSnack(context, 'Notifikasi belum tersedia'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _isiPengaturan(),
          _isiBeranda(),
          _isiAkun(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.abu,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }

  // ---------- Tab Beranda ----------

  Widget _isiBeranda() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _profil,
          builder: (context, snap) {
            final nama = (snap.data?['nama'] as String?) ?? 'Penyewa';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $nama!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mau parkir di mana hari ini?',
                  style: TextStyle(color: AppColors.abu),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _cari,
          onChanged: _onCariBerubah,
          onSubmitted: (_) => _muatLokasi(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Cari lokasi parkir...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _cari.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _cari.clear();
                      _muatLokasi();
                    },
                  ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Lokasi Parkir',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _daftarLokasi,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return KartuPutih(
                child: Column(
                  children: [
                    const Text('Gagal memuat lokasi. Periksa koneksi kamu.'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _muatLokasi,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              );
            }
            final data = snap.data ?? [];
            if (data.isEmpty) {
              return const KartuPutih(
                child: Text(
                  'Tidak ada lokasi dengan slot tersedia.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: [
                for (final l in data)
                  _KartuLokasi(
                    data: l,
                    // TODO: arahkan ke halaman Pilih Slot (screen 5).
                    onTap: () => pesanSnack(
                      context,
                      'Halaman pilih slot akan dibuat selanjutnya',
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------- Tab Pengaturan ----------

  Widget _isiPengaturan() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 56, color: AppColors.biru),
          SizedBox(height: 12),
          Text(
            'Pengaturan akan hadir di versi berikutnya',
            style: TextStyle(color: AppColors.abu),
          ),
        ],
      ),
    );
  }

  // ---------- Tab Akun ----------

  Widget _isiAkun() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profil,
      builder: (context, snap) {
        final p = snap.data ?? <String, dynamic>{};
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.biruMuda,
                child: Icon(Icons.person, size: 44, color: AppColors.navy),
              ),
            ),
            const SizedBox(height: 20),
            KartuPutih(
              child: Column(
                children: [
                  _baris('Nama', (p['nama'] as String?) ?? '-'),
                  const Divider(height: 24),
                  _baris('Email', supabase.auth.currentUser?.email ?? '-'),
                  const Divider(height: 24),
                  _baris('No. Telepon', (p['no_telp'] as String?) ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _keluar,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.merah,
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.merah),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _baris(String label, String nilai) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: AppColors.abu)),
        ),
        Expanded(
          child: Text(
            nilai,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.teks,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu satu lokasi parkir.
class _KartuLokasi extends StatelessWidget {
  const _KartuLokasi({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nama = (data['nama'] as String?) ?? '-';
    final alamat = (data['alamat'] as String?) ?? '';
    final tarif = data['tarif_per_jam'] as num?;
    final slot = (data['slot_tersedia'] as int?) ?? 0;
    final jarak = data['jarak_km'] as double?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.biruMuda,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_parking_rounded,
                      color: AppColors.navy, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.teks,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alamat,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.abu,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _chip('$slot slot tersedia', AppColors.hijau),
                          if (tarif != null)
                            _chip('${formatRupiah(tarif)}/jam',
                                AppColors.navy),
                          if (jarak != null)
                            _chip(
                              '${jarak.toStringAsFixed(1).replaceAll('.', ',')} km',
                              AppColors.abu,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.abu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String teks, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: warna,
        ),
      ),
    );
  }
}