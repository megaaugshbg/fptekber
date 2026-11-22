import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/data_pemesanan.dart';

void main() {
  group('nomorTransaksi', () {
    test('6 digit dengan nol di depan', () {
      expect(nomorTransaksi(42), 'TRX-000042');
      expect(nomorTransaksi('7'), 'TRX-000007');
    });
    test('lebih dari 6 digit tidak dipotong', () {
      expect(nomorTransaksi(1234567), 'TRX-1234567');
    });
  });

  group('aksiBooking', () {
    test('status -> tombol', () {
      expect(aksiBooking('menunggu_bayar'), AksiBooking.lanjutBayar);
      expect(aksiBooking('dibayar'), AksiBooking.checkIn);
      expect(aksiBooking('check_in'), AksiBooking.parkirBerlangsung);
      expect(aksiBooking('selesai'), AksiBooking.tidakAda);
      expect(aksiBooking(null), AksiBooking.tidakAda);
    });
  });

  group('kodePesanan & labelStatus', () {
    test('pakai kode_booking, cadangan dari id', () {
      expect(kodePesanan({'id': 5, 'kode_booking': 'MKR-000005'}), 'MKR-000005');
      expect(kodePesanan({'id': 123}), 'MKR-000123');
    });
    test('label', () {
      expect(labelStatus('dibayar'), 'Dibayar');
      expect(labelStatus('x'), 'x');
    });
  });

  group('pembayaran & waktu', () {
    test('join list: ambil id terbesar', () {
      final p = {
        'pembayaran': [
          {'id': 3, 'jumlah': 10000},
          {'id': 9, 'jumlah': 20000, 'metode': 'QRIS'},
        ],
      };
      expect(idPembayaran(p), 9);
      expect(jumlahDibayar(p), 20000);
      expect(metodePembayaran(p), 'QRIS');
    });

    test('join objek tunggal & cadangan total_biaya', () {
      expect(idPembayaran({'pembayaran': {'id': 4}}), 4);
      expect(jumlahDibayar({'total_biaya': 15000, 'pembayaran': []}), 15000);
    });

    test('parseWaktu tanpa zona dianggap UTC', () {
      expect(parseWaktu('2026-03-05T10:00:00'), DateTime.utc(2026, 3, 5, 10));
      expect(parseWaktu('2026-03-05 10:00:00+00'), DateTime.utc(2026, 3, 5, 10));
      expect(parseWaktu(null), isNull);
    });

    test('durasiDibayar dari mulai-selesai', () {
      final p = {
        'waktu_mulai': '2026-03-05T10:00:00Z',
        'waktu_selesai': '2026-03-05T13:00:00Z',
      };
      expect(durasiDibayar(p), 3);
    });

    // Baris pemesanan dengan nama kolom asli dari information_schema.
    final asli = <String, dynamic>{
      'id': 12,
      'kode_booking': 'MKR-000012',
      'waktu_mulai': '2026-03-05T10:00:00+00:00',
      'waktu_selesai': '2026-03-05T12:00:00+00:00',
      'check_in_at': '2026-03-05T10:05:00+00:00',
      'check_out_at': '2026-03-05T12:30:00+00:00',
      'total_biaya': 20000,
      'status': 'selesai',
      'pembayaran': [
        {
          'id': 7,
          'pemesanan_id': 12,
          'metode': 'QRIS',
          'jumlah': 20000,
          'status': 'berhasil',
          'dibayar_at': '2026-03-05T09:58:00+00:00',
        },
      ],
    };

    test('membaca check_in_at dan check_out_at', () {
      expect(waktuCheckIn(asli), DateTime.utc(2026, 3, 5, 10, 5));
      expect(waktuCheckOut(asli), DateTime.utc(2026, 3, 5, 12, 30));
    });

    test('membaca dibayar_at, jumlah, metode, id pembayaran', () {
      expect(waktuBayar(asli), DateTime.utc(2026, 3, 5, 9, 58));
      expect(jumlahDibayar(asli), 20000);
      expect(metodePembayaran(asli), 'QRIS');
      expect(nomorTransaksi(idPembayaran(asli)), 'TRX-000007');
    });

    test('total_biaya dan durasi dari waktu_mulai/waktu_selesai', () {
      expect(totalBiaya(asli), 20000);
      expect(durasiDibayar(asli), 2);
    });

    test('check_in_at diutamakan dibanding nama cadangan', () {
      final p = {
        'check_in_at': '2026-03-05T10:00:00Z',
        'waktu_checkin': '2026-03-05T11:00:00Z',
      };
      expect(waktuCheckIn(p), DateTime.utc(2026, 3, 5, 10));
    });

    test('tampil WIB dari kolom asli', () {
      expect(tampilWib(waktuCheckIn(asli)), '05-03-2026 17:05 WIB');
      expect(tampilWib(waktuBayar(asli)), '05-03-2026 16:58 WIB');
    });

    test('tampilWib', () {
      expect(tampilWib(DateTime.utc(2026, 3, 5, 0)), '05-03-2026 07:00 WIB');
      expect(tampilWib(null), '-');
    });
  });
}
