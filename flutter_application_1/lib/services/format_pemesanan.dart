/// Helper murni (tanpa UI) untuk waktu, durasi, dan rupiah pada pemesanan.
library;

const Duration _selisihWib = Duration(hours: 7);

/// Ubah waktu apa pun menjadi "jam dinding" WIB (UTC+7), eksplisit
/// dan tidak bergantung zona perangkat. Hasilnya berflag UTC, tapi
/// komponen jam/tanggalnya adalah jam WIB. Jangan kirim ke database.
DateTime keWib(DateTime t) => t.toUtc().add(_selisihWib);

/// Kebalikan [keWib]: ubah jam dinding WIB menjadi waktu UTC sebenarnya
/// (kurangi 7 jam), aman dikirim ke ubahJadwal.
DateTime dariWib(DateTime jamDindingWib) {
  final j = jamDindingWib;
  return DateTime.utc(j.year, j.month, j.day, j.hour, j.minute, j.second,
      j.millisecond, j.microsecond)
      .subtract(_selisihWib);
}

String _dua(int n) => n.toString().padLeft(2, '0');

/// Format d-m-Y H:i dalam WIB, contoh: 05-03-2026 07:00.
String formatTanggalWib(DateTime t) {
  final w = keWib(t);
  return '${_dua(w.day)}-${_dua(w.month)}-${w.year} '
      '${_dua(w.hour)}:${_dua(w.minute)}';
}

/// Durasi dibulatkan ke atas per jam, minimal 1 jam (dihitung dari detik,
/// sama dengan pembulatan di database).
int _jamKeAtas(Duration selisih) {
  final detik = selisih.inSeconds;
  if (detik <= 0) return 1;
  return (detik + 3599) ~/ 3600;
}

/// Durasi pemakaian sebenarnya (check-in sampai check-out).
int hitungDurasiAktual(DateTime checkIn, DateTime checkOut) =>
    _jamKeAtas(checkOut.difference(checkIn));

/// Durasi yang sudah dibayar (waktu_selesai - waktu_mulai).
int hitungDurasiDibayar(DateTime mulai, DateTime selesai) =>
    _jamKeAtas(selesai.difference(mulai));

/// Jumlah jam yang melebihi durasi dibayar, minimal 0.
int melebihiJam(int durasiAktual, int durasiDibayar) =>
    durasiAktual > durasiDibayar ? durasiAktual - durasiDibayar : 0;

/// Format rupiah, contoh: Rp 15.000.
String formatRupiah(num nilai) {
  final bulat = nilai.round();
  final digit = bulat.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digit.length; i++) {
    if (i > 0 && (digit.length - i) % 3 == 0) buf.write('.');
    buf.write(digit[i]);
  }
  return '${bulat < 0 ? '-' : ''}Rp $buf';
}

/// Pembanding natural untuk kode slot (huruf lalu angka): A1, A2, A10.
int bandingkanKodeSlot(String a, String b) {
  final pa = _pecahKode(a);
  final pb = _pecahKode(b);
  final n = pa.length < pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = pa[i];
    final y = pb[i];
    final angkaX = int.tryParse(x);
    final angkaY = int.tryParse(y);
    final int c;
    if (angkaX != null && angkaY != null) {
      c = angkaX.compareTo(angkaY);
    } else {
      c = x.compareTo(y);
    }
    if (c != 0) return c;
  }
  return pa.length.compareTo(pb.length);
}

List<String> _pecahKode(String s) =>
    RegExp(r'\d+|\D+').allMatches(s).map((m) => m.group(0)!).toList();

/// Urutkan daftar slot (Map dengan 'kode_slot') secara natural.
List<Map<String, dynamic>> urutkanSlot(List<Map<String, dynamic>> slot) {
  final hasil = [...slot];
  hasil.sort((a, b) => bandingkanKodeSlot(
      (a['kode_slot'] ?? '').toString(), (b['kode_slot'] ?? '').toString()));
  return hasil;
}
