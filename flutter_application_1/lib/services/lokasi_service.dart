import 'dart:math';

import 'supabase_config.dart';

/// Pencarian lokasi parkir dan denah slot.
class LokasiService {
  /// Cari lokasi yang punya slot tersedia untuk tipe tertentu.
  /// tipe: 'normal' | 'woman' | 'priority' | 'ev'
  /// Kalau latUser/lngUser diisi, hasil diurutkan dari yang terdekat
  /// dan tiap lokasi dapat field 'jarak_km'.
  Future<List<Map<String, dynamic>>> cariLokasi({
    required String tipe,
    String kataKunci = '',
    double? latUser,
    double? lngUser,
  }) async {
    var query = supabase
        .from('lokasi')
        .select('*, slot!inner(id)')
        .eq('slot.tipe', tipe)
        .eq('slot.status', 'tersedia');

    if (kataKunci.trim().isNotEmpty) {
      query = query.ilike('nama', '%${kataKunci.trim()}%');
    }

    final data = await query;
    final hasil = List<Map<String, dynamic>>.from(data);

    for (final l in hasil) {
      l['slot_tersedia'] = (l['slot'] as List).length;
      l.remove('slot');
      if (latUser != null && lngUser != null) {
        l['jarak_km'] = _jarakKm(
          latUser,
          lngUser,
          (l['latitude'] as num).toDouble(),
          (l['longitude'] as num).toDouble(),
        );
      }
    }

    if (latUser != null && lngUser != null) {
      hasil.sort((a, b) =>
          (a['jarak_km'] as double).compareTo(b['jarak_km'] as double));
    }
    return hasil;
  }

  /// Denah slot satu lokasi, otomatis update saat ada yang memesan.
  /// Pakai di StreamBuilder.
  Stream<List<Map<String, dynamic>>> streamSlot(int lokasiId) {
    return supabase
        .from('slot')
        .stream(primaryKey: ['id'])
        .eq('lokasi_id', lokasiId)
        .order('kode_slot');
  }

  /// Jarak garis lurus (rumus haversine), cukup untuk menampilkan "1,2 km".
  double _jarakKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
