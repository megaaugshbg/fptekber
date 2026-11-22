import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'markir_widgets.dart';

/// Tab aktif kerangka utama: 0 Beranda, 1 Booking, 2 Pengaturan.
/// Dibagi supaya layar yang di-push (mis. Konfirmasi) bisa memilih tab
/// tujuan sebelum kembali ke kerangka.
final ValueNotifier<int> tabAktif = ValueNotifier<int>(0);

Future<void> keluarDariAplikasi(BuildContext context) async {
  try {
    await AuthService().keluar();
    // AuthGate otomatis kembali ke halaman Login.
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  } catch (e) {
    if (context.mounted) pesanSnack(context, AuthService.pesanError(e));
  }
}

/// Navbar atas: logo, kolom cari, menu desktop, tombol Keluar.
class NavbarAtas extends StatelessWidget {
  const NavbarAtas({
    super.key,
    this.cari,
    this.onCariBerubah,
    this.nama,
    this.tab,
    this.onTab,
  });

  /// Jika null, kolom cari tidak ditampilkan.
  final TextEditingController? cari;
  final ValueChanged<String>? onCariBerubah;
  final String? nama;
  final int? tab;
  final ValueChanged<int>? onTab;

  Widget _kolomCari() {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: cari,
        onChanged: onCariBerubah,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari mal atau lokasi parkir…',
          filled: true,
          fillColor: AppColors.latar,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          border: _bulat(),
          enabledBorder: _bulat(),
          focusedBorder: _bulat(AppColors.primer),
        ),
      ),
    );
  }

  OutlineInputBorder _bulat([Color warna = AppColors.garis]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: warna),
      );

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= batasDesktop;

    final Widget isi;
    if (desktop) {
      isi = Row(
        children: [
          const LogoMarkir(height: 40),
          Expanded(
            child: cari == null
                ? const SizedBox()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 384),
                      child: _kolomCari(),
                    ),
                  ),
          ),
          if (tab != null && onTab != null) ...[
            _menu('Home', 0),
            _menu('Riwayat', 1),
            _menu('Pengaturan', 2),
            const SizedBox(width: 16),
          ],
          if (nama != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(nama!,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          OutlinedButton(
            onPressed: () => keluarDariAplikasi(context),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              side: const BorderSide(color: AppColors.garis),
            ),
            child: const Text('Keluar', style: TextStyle(fontSize: 14)),
          ),
        ],
      );
    } else {
      isi = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const LogoMarkir(height: 40),
              const Spacer(),
              IconButton(
                tooltip: 'Keluar',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => keluarDariAplikasi(context),
              ),
            ],
          ),
          if (cari != null) ...[
            const SizedBox(height: 8),
            _kolomCari(),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        border: Border(bottom: BorderSide(color: AppColors.garis)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, desktop ? 12 : 8, 16, 12),
          child: isi,
        ),
      ),
    );
  }

  Widget _menu(String label, int i) {
    final aktif = tab == i;
    return InkWell(
      onTap: () => onTab?.call(i),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: aktif ? AppColors.primer : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Navigasi bawah (HP): Beranda, Booking, Pengaturan.
class NavBawah extends StatelessWidget {
  const NavBawah({super.key, required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.garis)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bayangan,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _item(0, 'Beranda', Icons.home_outlined, Icons.home_rounded),
              _item(1, 'Booking', Icons.confirmation_number_outlined,
                  Icons.confirmation_number),
              _item(2, 'Pengaturan', Icons.settings_outlined, Icons.settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, String label, IconData ikon, IconData ikonAktif) {
    final aktif = index == i;
    final warna = aktif ? AppColors.primer : AppColors.slate500;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(i),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(aktif ? ikonAktif : ikon, color: warna, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: warna,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
