import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Dilempar kalau slot sudah keburu dipesan orang lain.
class SlotTidakTersediaException implements Exception {
  @override
  String toString() => 'Slot sudah tidak tersedia, silakan pilih slot lain';
}

/// CRUD pemesanan + pembayaran, check-in, check-out.
class PemesananService {
  String get _userId => supabase.auth.currentUser!.id;

  /// CREATE - pesan slot. total_biaya dihitung otomatis di database.
  Future<Map<String, dynamic>> pesan({
    required int slotId,
    required DateTime mulai,
    required DateTime selesai,
  }) async {
    try {
      return await supabase
          .from('pemesanan')
          .insert({
            'user_id': _userId,
            'slot_id': slotId,
            'waktu_mulai': mulai.toUtc().toIso8601String(),
            'waktu_selesai': selesai.toUtc().toIso8601String(),
          })
          .select('*, slot(kode_slot, tipe, lokasi(nama, tarif_per_jam))')
          .single();
    } on PostgrestException catch (e) {
      // 23505 = unique violation -> slot sudah punya pemesanan aktif
      if (e.code == '23505') throw SlotTidakTersediaException();
      rethrow;
    }
  }

  /// READ - riwayat pemesanan milik user yang login, terbaru di atas.
  Future<List<Map<String, dynamic>>> riwayat() async {
    final data = await supabase
        .from('pemesanan')
        .select('*, slot(kode_slot, tipe, lokasi(nama, alamat)), pembayaran(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// READ - detail satu pemesanan.
  Future<Map<String, dynamic>> detail(int id) async {
    return await supabase
        .from('pemesanan')
        .select('*, slot(kode_slot, tipe, lokasi(nama, alamat, tarif_per_jam)), pembayaran(*)')
        .eq('id', id)
        .single();
  }

  /// UPDATE - ubah jadwal. Hanya bisa sebelum check-in (dijaga RLS).
  Future<Map<String, dynamic>> ubahJadwal({
    required int id,
    required DateTime mulai,
    required DateTime selesai,
  }) async {
    return await supabase
        .from('pemesanan')
        .update({
          'waktu_mulai': mulai.toUtc().toIso8601String(),
          'waktu_selesai': selesai.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
  }

  /// UPDATE - batalkan. Slot otomatis kembali tersedia.
  Future<void> batalkan(int id) async {
    await supabase
        .from('pemesanan')
        .update({'status': 'dibatalkan'})
        .eq('id', id);
  }

  /// DELETE - hapus dari riwayat (yang belum dibayar / sudah dibatalkan).
  Future<void> hapus(int id) async {
    await supabase.from('pemesanan').delete().eq('id', id);
  }

  /// Bayar (simulasi QRIS). Status pemesanan jadi 'dibayar'.
  Future<Map<String, dynamic>> bayar(int id, {String metode = 'QRIS'}) async {
    final res = await supabase.rpc('bayar', params: {
      'p_pemesanan_id': id,
      'p_metode': metode,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Check-in saat sampai di lokasi. Slot jadi 'terisi'.
  Future<Map<String, dynamic>> checkIn(int id) async {
    final res = await supabase.rpc('checkin', params: {'p_pemesanan_id': id});
    return Map<String, dynamic>.from(res as Map);
  }

  /// Check-out pakai kode booking hasil scan. Mengembalikan total biaya akhir.
  Future<Map<String, dynamic>> checkOut(String kodeBooking) async {
    final res = await supabase.rpc('checkout', params: {
      'p_kode_booking': kodeBooking,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  /// Pesan error dari database (raise exception di SQL) untuk SnackBar.
  static String pesanError(Object e) {
    if (e is SlotTidakTersediaException) return e.toString();
    if (e is PostgrestException) {
      if (e.code == 'PGRST116') {
        return 'Pemesanan tidak bisa diubah (sudah check-in atau tidak ditemukan)';
      }
      return e.message;
    }
    return 'Terjadi kesalahan, coba lagi';
  }
}
