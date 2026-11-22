import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'booking_aktif_screen.dart';
import 'riwayat_screen.dart';

/// Sub-tab di menu Booking: 0 Aktif, 1 Riwayat.
/// Dibagi supaya layar lain bisa langsung membuka Riwayat
/// (set nilainya, lalu tabAktif.value = 1).
final ValueNotifier<int> subTabBooking = ValueNotifier<int>(0);

/// Isi tab Booking: pilihan "Aktif | Riwayat" seperti di PPPL.
class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: subTabBooking,
      builder: (context, sub, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: _TabBooking(
                  aktif: sub,
                  onPilih: (i) => subTabBooking.value = i,
                ),
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: sub,
              children: const [
                BookingAktifScreen(),
                RiwayatScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tombol segmen "Aktif | Riwayat".
class _TabBooking extends StatelessWidget {
  const _TabBooking({required this.aktif, required this.onPilih});

  final int aktif;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.permukaanAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.garis),
      ),
      child: Row(
        children: [
          _segmen('Aktif', 0),
          const SizedBox(width: 4),
          _segmen('Riwayat', 1),
        ],
      ),
    );
  }

  Widget _segmen(String label, int i) {
    final dipilih = aktif == i;
    return Expanded(
      child: Material(
        color: dipilih ? AppColors.permukaan : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: dipilih ? 1 : 0,
        shadowColor: AppColors.bayangan,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onPilih(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dipilih ? AppColors.primer : AppColors.slate500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}