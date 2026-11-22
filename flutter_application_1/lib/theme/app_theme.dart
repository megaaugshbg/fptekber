import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const navy = Color(0xFF1E2A78);
  static const biru = Color(0xFF7D98D6);
  static const biruMuda = Color(0xFFBBD0F5);
  static const latar = Color(0xFFF4F7FD);
  static const teks = Color(0xFF1F2937);
  static const abu = Color(0xFF6B7280);
  static const hijau = Color(0xFF16A34A);
  static const merah = Color(0xFFDC2626);
}

ThemeData buatTema() {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFD1D9EE)),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
    scaffoldBackgroundColor: AppColors.latar,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.navy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.navy,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.navy, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.merah),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.merah, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.biru,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.navy),
    ),
  );
}