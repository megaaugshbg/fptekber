import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/format_pemesanan.dart';

void main() {
  final t0 = DateTime.utc(2026, 3, 5, 10);

  group('durasi (detik, dibulatkan ke atas)', () {
    test('hitungDurasiAktual', () {
      int d(int detik) =>
          hitungDurasiAktual(t0, t0.add(Duration(seconds: detik)));
      expect(d(3600), 1);
      expect(d(3601), 2);
      expect(d(0), 1);
      expect(d(7199), 2);
      expect(d(7200), 2);
      expect(d(-10), 1);
    });

    test('hitungDurasiDibayar', () {
      expect(hitungDurasiDibayar(t0, t0.add(const Duration(hours: 3))), 3);
      expect(
          hitungDurasiDibayar(t0, t0.add(const Duration(hours: 3, seconds: 1))),
          4);
    });
  });

  group('melebihiJam', () {
    test('minimal 0', () {
      expect(melebihiJam(1, 3), 0);
      expect(melebihiJam(3, 3), 0);
      expect(melebihiJam(5, 3), 2);
    });
  });

  group('WIB', () {
    test('lintas hari', () {
      final t = DateTime.utc(2026, 3, 5, 20, 0);
      expect(formatTanggalWib(t), '06-03-2026 03:00');
    });

    test('lintas tahun', () {
      expect(formatTanggalWib(DateTime.utc(2026, 12, 31, 17, 30)),
          '01-01-2027 00:30');
    });

    test('tanpa lintas hari', () {
      expect(formatTanggalWib(DateTime.utc(2026, 3, 5, 0, 0)),
          '05-03-2026 07:00');
    });

    test('bolak-balik keWib dan dariWib', () {
      final asli = DateTime.utc(2026, 3, 5, 20, 15, 30);
      final wib = keWib(asli);
      expect(wib.hour, 3);
      expect(wib.day, 6);
      expect(dariWib(wib), asli);
      final dinding = DateTime(2026, 3, 1, 5, 0);
      expect(dariWib(dinding), DateTime.utc(2026, 2, 28, 22, 0));
      expect(keWib(dariWib(dinding)).hour, 5);
    });
  });

  group('formatRupiah', () {
    test('pemisah ribuan', () {
      expect(formatRupiah(0), 'Rp 0');
      expect(formatRupiah(999), 'Rp 999');
      expect(formatRupiah(15000), 'Rp 15.000');
      expect(formatRupiah(1234567), 'Rp 1.234.567');
    });
  });

  group('urutan slot natural', () {
    test('A1, A2, ..., A10', () {
      final slot = ['A10', 'A2', 'B1', 'A1', 'A11', 'A9']
          .map((k) => {'kode_slot': k})
          .toList();
      final hasil = urutkanSlot(slot).map((s) => s['kode_slot']).toList();
      expect(hasil, ['A1', 'A2', 'A9', 'A10', 'A11', 'B1']);
    });

    test('tidak mengubah daftar asal', () {
      final slot = [
        {'kode_slot': 'A2'},
        {'kode_slot': 'A1'},
      ];
      urutkanSlot(slot);
      expect(slot.first['kode_slot'], 'A2');
    });
  });
}
