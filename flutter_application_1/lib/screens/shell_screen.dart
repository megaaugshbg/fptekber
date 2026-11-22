import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/kerangka_markir.dart';
import '../widgets/markir_widgets.dart';
import 'beranda_screen.dart';
import 'booking_screen.dart';
import 'segera_hadir_screen.dart';

/// Kerangka setelah login: navbar atas, tab, dan navigasi bawah (HP).
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final _cari = TextEditingController();
  Timer? _debounce;
  String _kataKunci = '';
  late final Future<Map<String, dynamic>> _profil;

  @override
  void initState() {
    super.initState();
    tabAktif.value = 0;
    _profil = AuthService().ambilProfil();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cari.dispose();
    super.dispose();
  }

  /// Tunggu 400 ms setelah user berhenti mengetik, baru cari.
  void _onCari(String teks) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _kataKunci = teks.trim());
    });
  }

  void _hapusCari() {
    _debounce?.cancel();
    _cari.clear();
    setState(() => _kataKunci = '');
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= batasDesktop;
    return ValueListenableBuilder<int>(
      valueListenable: tabAktif,
      builder: (context, tab, _) {
        return Scaffold(
          body: Column(
            children: [
              FutureBuilder<Map<String, dynamic>>(
                future: _profil,
                builder: (context, snap) => NavbarAtas(
                  cari: tab == 0 ? _cari : null,
                  onCariBerubah: _onCari,
                  nama: snap.data?['nama'] as String?,
                  tab: tab,
                  onTab: (i) => tabAktif.value = i,
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: tab,
                  children: [
                    BerandaScreen(
                      profil: _profil,
                      kataKunci: _kataKunci,
                      onHapusPencarian: _hapusCari,
                    ),
                    const BookingScreen(),
                    const SegeraHadirView(judul: 'Pengaturan'),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: desktop
              ? null
              : NavBawah(index: tab, onTap: (i) => tabAktif.value = i),
        );
      },
    );
  }
}
