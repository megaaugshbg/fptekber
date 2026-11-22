/// Pembaca data pemesanan (Map dari Supabase) tanpa UI, supaya mudah diuji.
///
/// Nama kolom waktu/pembayaran dikumpulkan di sini. Jika nama kolom asli di
/// database berbeda, cukup ubah daftar kandidat di file ini.
library;

import 'format_pemesanan.dart';

// ---- Nama kolom (urutan = prioritas) ----
// Skema asli (information_schema):
//   pemesanan: id, kode_booking, user_id, slot_id, waktu_mulai, waktu_selesai,
//              check_in_at, check_out_at, total_biaya, status, created_at
//   pembayaran: id, pemesanan_id, metode, jumlah, status, dibayar_at
// Nama setelah yang pertama hanya cadangan.
const _kolomMulai = ['waktu_mulai', 'mulai'];
const _kolomSelesai = ['waktu_selesai', 'selesai_pada'];
const _kolomCheckIn = ['check_in_at', 'waktu_checkin', 'waktu_check_in', 'checkin_at'];
const _kolomCheckOut = ['check_out_at', 'waktu_checkout', 'waktu_check_out', 'checkout_at'];
const _kolomTotal = ['total_biaya', 'total'];
const _kolomJumlahBayar = ['jumlah', 'jumlah_bayar', 'nominal', 'total_bayar', 'total'];
const _kolomMetode = ['metode', 'metode_pembayaran'];
const _kolomWaktuBayar = ['dibayar_at', 'waktu_bayar', 'dibayar_pada', 'paid_at'];
const _kolomDurasi = ['durasi', 'durasi_jam'];

/// Kode pesanan tampilan, mis. MKR-000123.
String kodePesanan(Map<String, dynamic> p) {
  final kode = p['kode_booking'];
  if (kode is String && kode.isNotEmpty) return kode;
  return 'MKR-${(p['id'] ?? '').toString().padLeft(6, '0')}';
}

/// Label status pemesanan (status asli di database).
String labelStatus(String? s) {
  switch (s) {
    case 'menunggu_bayar':
      return 'Menunggu bayar';
    case 'dibayar':
      return 'Dibayar';
    case 'check_in':
      return 'Check-in';
    case 'selesai':
      return 'Selesai';
    case 'dibatalkan':
      return 'Dibatalkan';
    default:
      return s ?? '-';
  }
}

/// Nomor transaksi, mis. TRX-000042 (id pembayaran, 6 digit nol di depan).
String nomorTransaksi(Object? idPembayaran) =>
    'TRX-${(idPembayaran ?? '').toString().padLeft(6, '0')}';

/// Tombol/tujuan utama tab Booking Aktif menurut status pemesanan.
enum AksiBooking { lanjutBayar, checkIn, parkirBerlangsung, tidakAda }

AksiBooking aksiBooking(String? status) {
  switch (status) {
    case 'menunggu_bayar':
      return AksiBooking.lanjutBayar;
    case 'dibayar':
      return AksiBooking.checkIn;
    case 'check_in':
      return AksiBooking.parkirBerlangsung;
    default:
      return AksiBooking.tidakAda;
  }
}

// ---- Pembaca umum ----

dynamic _ambil(Map? m, List<String> kunci) {
  if (m == null) return null;
  for (final k in kunci) {
    final v = m[k];
    if (v != null) return v;
  }
  return null;
}

/// Parse waktu dari database. Teks tanpa zona waktu dianggap UTC.
DateTime? parseWaktu(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  var s = v.toString().trim();
  if (s.isEmpty) return null;
  final adaZona = s.endsWith('Z') || RegExp(r'[+-]\d{2}(:?\d{2})?$').hasMatch(s);
  if (!adaZona) s = '${s.replaceFirst(' ', 'T')}Z';
  return DateTime.tryParse(s);
}

num? _angka(Object? v) {
  if (v is num) return v;
  if (v is String) return num.tryParse(v);
  return null;
}

/// Teks waktu WIB untuk tampilan, mis. "05-03-2026 07:00 WIB".
String tampilWib(DateTime? t) => t == null ? '-' : '${formatTanggalWib(t)} WIB';

// ---- Slot & lokasi ----

Map<String, dynamic> slotDari(Map<String, dynamic> p) =>
    Map<String, dynamic>.from((p['slot'] as Map?) ?? const {});

Map<String, dynamic> lokasiDari(Map<String, dynamic> p) =>
    Map<String, dynamic>.from((slotDari(p)['lokasi'] as Map?) ?? const {});

String kodeSlotDari(Map<String, dynamic> p) =>
    (slotDari(p)['kode_slot'] ?? '-').toString();

String namaLokasiDari(Map<String, dynamic> p) =>
    (lokasiDari(p)['nama'] ?? '-').toString();

String alamatLokasiDari(Map<String, dynamic> p) =>
    (lokasiDari(p)['alamat'] ?? '-').toString();

num? tarifPerJamDari(Map<String, dynamic> p) =>
    _angka(lokasiDari(p)['tarif_per_jam']);

// ---- Pembayaran ----

/// Baris pembayaran terbaru (join bisa berupa list atau satu objek).
Map<String, dynamic>? pembayaranDari(Map<String, dynamic> p) {
  final b = p['pembayaran'];
  if (b is Map) return Map<String, dynamic>.from(b);
  if (b is List && b.isNotEmpty) {
    final baris = b.whereType<Map>().map(Map<String, dynamic>.from).toList();
    if (baris.isEmpty) return null;
    baris.sort((x, y) =>
        ((_angka(y['id']) ?? 0)).compareTo((_angka(x['id']) ?? 0)));
    return baris.first;
  }
  return null;
}

Object? idPembayaran(Map<String, dynamic> p) => pembayaranDari(p)?['id'];

String? metodePembayaran(Map<String, dynamic> p) =>
    _ambil(pembayaranDari(p), _kolomMetode)?.toString();

DateTime? waktuBayar(Map<String, dynamic> p) =>
    parseWaktu(_ambil(pembayaranDari(p), _kolomWaktuBayar));

/// Jumlah yang sudah dibayar. Cadangan: total_biaya pada pemesanan.
num? jumlahDibayar(Map<String, dynamic> p) =>
    _angka(_ambil(pembayaranDari(p), _kolomJumlahBayar)) ??
    _angka(_ambil(p, _kolomTotal));

num? totalBiaya(Map<String, dynamic> p) =>
    _angka(_ambil(p, _kolomTotal)) ?? jumlahDibayar(p);

// ---- Waktu & durasi ----

DateTime? waktuMulai(Map<String, dynamic> p) => parseWaktu(_ambil(p, _kolomMulai));
DateTime? waktuSelesai(Map<String, dynamic> p) => parseWaktu(_ambil(p, _kolomSelesai));
DateTime? waktuCheckIn(Map<String, dynamic> p) => parseWaktu(_ambil(p, _kolomCheckIn));
DateTime? waktuCheckOut(Map<String, dynamic> p) => parseWaktu(_ambil(p, _kolomCheckOut));

/// Jam yang dibayar: dari mulai-selesai, lalu kolom durasi, lalu jumlah / tarif.
int? durasiDibayar(Map<String, dynamic> p) {
  final mulai = waktuMulai(p);
  final selesai = waktuSelesai(p);
  if (mulai != null && selesai != null) {
    return hitungDurasiDibayar(mulai, selesai);
  }
  final d = _angka(_ambil(p, _kolomDurasi));
  if (d != null) return d.round();
  final jumlah = jumlahDibayar(p);
  final tarif = tarifPerJamDari(p);
  if (jumlah != null && tarif != null && tarif > 0) {
    return (jumlah / tarif).round();
  }
  return null;
}

/// "N jam" atau "-".
String teksJam(int? n) => n == null ? '-' : '$n jam';

// ---- Riwayat ----

/// Status yang masuk Riwayat Booking (pesanan aktif ada di tab Aktif).
const statusRiwayat = ['selesai', 'dibatalkan'];

/// Label tipe slot, sama dengan PPPL.
String labelTipe(String? tipe) {
  switch (tipe) {
    case 'normal':
      return 'Normal Parking';
    case 'woman':
      return 'Woman Parking';
    case 'priority':
      return 'Priority Parking';
    case 'ev':
      return 'EV Charging Parking';
    default:
      return tipe ?? '-';
  }
}

String tipeSlotDari(Map<String, dynamic> p) =>
    labelTipe(slotDari(p)['tipe']?.toString());

/// Waktu pesanan dibuat (created_at).
DateTime? waktuDipesan(Map<String, dynamic> p) => parseWaktu(p['created_at']);

/// Tanggal yang ditampilkan di daftar riwayat:
/// selesai = waktu keluar, dibatalkan = waktu dipesan.
DateTime? waktuRiwayat(Map<String, dynamic> p) => p['status'] == 'selesai'
    ? (waktuCheckOut(p) ?? waktuDipesan(p))
    : waktuDipesan(p);
