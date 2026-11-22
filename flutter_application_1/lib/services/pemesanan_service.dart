import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_pemesanan.dart';
import 'supabase_config.dart';

/// Pemesanan + pembayaran, check-in, check-out.
/// Semua perubahan data lewat RPC (klien tidak boleh insert/update langsung).
class PemesananService {
  /// Join standar: slot, lokasi (nama, alamat, tarif), dan pembayaran.
  static const String _join =
      '*, slot(kode_slot, tipe, lokasi(nama, alamat, tarif_per_jam)), pembayaran(*)';

  /// CREATE - pesan slot. Mengembalikan pemesanan berstatus menunggu_bayar.
  Future<Map<String, dynamic>> pesan(int slotId) async {
    final res = await supabase.rpc('pesan', params: {'p_slot_id': slotId});
    return Map<String, dynamic>.from(res as Map);
  }

  /// READ - satu pemesanan aktif (menunggu_bayar / dibayar / check_in)
  /// milik user yang login, atau null kalau tidak ada.
  Future<Map<String, dynamic>?> pesananAktif() async {
    return await supabase
        .from('pemesanan')
        .select(_join)
        .inFilter('status', ['menunggu_bayar', 'dibayar', 'check_in'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// READ - riwayat pemesanan milik user yang login, terbaru di atas.
  Future<List<Map<String, dynamic>>> riwayat() async {
    final data = await supabase
        .from('pemesanan')
        .select(_join)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

    /// READ - Riwayat Booking (selesai / dibatalkan), terbaru di atas,
  /// per halaman. [status] null = semua, atau 'selesai' / 'dibatalkan'.
  Future<List<Map<String, dynamic>>> daftarRiwayat({
    String? status,
    int halaman = 0,
    int perHalaman = 10,
  }) async {
    final dari = halaman * perHalaman;
    final data = await supabase
        .from('pemesanan')
        .select(_join)
        .inFilter('status', status == null ? statusRiwayat : [status])
        .order('id', ascending: false)
        .range(dari, dari + perHalaman - 1);
    return List<Map<String, dynamic>>.from(data);
  }

  /// READ - detail satu pemesanan.
  Future<Map<String, dynamic>> detail(int id) async {
    return await supabase.from('pemesanan').select(_join).eq('id', id).single();
  }

  /// UPDATE - ubah jadwal. Sebelum bayar boleh ubah mulai dan durasi,
  /// sesudah bayar hanya mulai. [mulai] harus waktu sebenarnya
  /// (kalau dari jam dinding WIB, ubah dulu dengan dariWib).
  Future<Map<String, dynamic>> ubahJadwal(
    int id,
    DateTime mulai, {
    int? durasi,
  }) async {
    final res = await supabase.rpc('ubah_jadwal', params: {
      'p_pemesanan_id': id,
      'p_mulai': mulai.toUtc().toIso8601String(),
      'p_durasi': ?durasi,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// UPDATE - batalkan pesanan (hanya yang masih menunggu_bayar).
  Future<Map<String, dynamic>> batalkan(int id) async {
    final res = await supabase.rpc('batalkan', params: {'p_pemesanan_id': id});
    return Map<String, dynamic>.from(res as Map);
  }

  /// DELETE - hapus dari riwayat, hanya untuk yang berstatus dibatalkan.
  /// RLS menolak tanpa error, jadi hasil kosong berarti tidak terhapus.
  Future<void> hapus(int id) async {
    final hasil = await supabase.from('pemesanan').delete().eq('id', id).select();
    if (hasil.isEmpty) {
      throw Exception('Hanya riwayat yang dibatalkan yang dapat dihapus.');
    }
  }

  /// Bayar (simulasi). Durasi 1 sampai 6 jam, total = tarif x durasi
  /// (dihitung database). Status pemesanan jadi 'dibayar'.
  Future<Map<String, dynamic>> bayar(
    int id,
    int durasi, {
    String metode = 'QRIS',
  }) async {
    if (durasi < 1 || durasi > 6) {
      throw ArgumentError.value(durasi, 'durasi', 'harus 1 sampai 6 jam');
    }
    final res = await supabase.rpc('bayar', params: {
      'p_pemesanan_id': id,
      'p_durasi': durasi,
      'p_metode': metode,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Check-in saat sampai di lokasi. Slot jadi 'terisi'.
  Future<Map<String, dynamic>> checkIn(int id) async {
    final res = await supabase.rpc('checkin', params: {'p_pemesanan_id': id});
    return Map<String, dynamic>.from(res as Map);
  }

  /// Check-out pakai kode booking hasil scan. total_biaya TIDAK berubah:
  /// sama dengan jumlah yang sudah dibayar.
  Future<Map<String, dynamic>> checkOut(String kodeBooking) async {
    final res = await supabase.rpc('checkout', params: {
      'p_kode_booking': kodeBooking,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Pesan error untuk SnackBar. Pesan dari database sudah berbahasa Indonesia.
  static String pesanError(Object e) {
    if (e is PostgrestException) return e.message;
    if (e is SocketException ||
        e is TimeoutException ||
        e.runtimeType.toString() == 'ClientException') {
      return 'Koneksi terputus. Silakan coba lagi.';
    }
    if (e is ArgumentError) return e.message.toString();
    if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
