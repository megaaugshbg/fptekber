import 'package:flutter/foundation.dart';

/// Struk check-out terakhir di sesi ini (pemesanan lengkap hasil check-out).
/// Hanya di memori, hilang saat aplikasi ditutup.
final ValueNotifier<Map<String, dynamic>?> strukTerakhir =
    ValueNotifier<Map<String, dynamic>?>(null);

/// Naik setiap kali data pemesanan berubah (pesan, bayar, check-in/out,
/// batal). Beranda dan Booking Aktif mendengarkan ini untuk memuat ulang.
final ValueNotifier<int> versiData = ValueNotifier<int>(0);

void segarkanData() => versiData.value++;
