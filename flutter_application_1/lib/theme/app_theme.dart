import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token warna PPPL "Markir.In".
class AppColors {
  AppColors._();

  static const latar = Color(0xFFFFFBE8);
  static const permukaan = Color(0xFFFFFFFF);
  static const permukaanAlt = Color(0xFFF6EFD2);
  static const garis = Color(0xFFEBE1B8);
  static const primer = Color(0xFF111178);
  static const primerPressed = Color(0xFF0C0C5A);
  static const primerSoft = Color(0xFFE6E5F2);
  static const onPrimer = Color(0xFFFFFBE8);
  static const slate500 = Color(0xFF64748B);
  static const slate200 = Color(0xFFE2E8F0);
  static const merah = Color(0xFFDC2626);
  static const merah50 = Color(0xFFFEF2F2);
  static const merah200 = Color(0xFFFECACA);
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const bayangan = Color(0x1F111178); // rgba(17,17,120,0.12)
}

/// Bayangan lembut untuk kartu.
List<BoxShadow> get bayanganKartu => const [
      BoxShadow(
        color: AppColors.bayangan,
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ];

ThemeData buatTema() {
  OutlineInputBorder border(Color warna, [double lebar = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: warna, width: lebar),
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primer,
      primary: AppColors.primer,
      onPrimary: AppColors.onPrimer,
      surface: AppColors.permukaan,
      error: AppColors.merah,
    ),
    scaffoldBackgroundColor: AppColors.latar,
  );

  final teks = GoogleFonts.instrumentSansTextTheme(base.textTheme).apply(
    bodyColor: AppColors.primer,
    displayColor: AppColors.primer,
  );

  return base.copyWith(
    textTheme: teks,
    primaryTextTheme: teks,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.permukaan,
      foregroundColor: AppColors.primer,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: teks.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.permukaan,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: AppColors.slate500),
      border: border(AppColors.slate200),
      enabledBorder: border(AppColors.slate200),
      focusedBorder: border(AppColors.primer, 1.5),
      errorBorder: border(AppColors.merah),
      focusedErrorBorder: border(AppColors.merah, 1.5),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.instrumentSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) return AppColors.permukaanAlt;
          if (s.contains(WidgetState.pressed) ||
              s.contains(WidgetState.hovered)) {
            return AppColors.primerPressed;
          }
          return AppColors.primer;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled)) {
            return AppColors.primer.withValues(alpha: 0.6);
          }
          return AppColors.onPrimer;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primer,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppColors.primer, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.instrumentSans(
            fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primer),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.garis,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.primer,
      contentTextStyle: TextStyle(color: AppColors.onPrimer),
    ),
  );
}
