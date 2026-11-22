import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'markir_widgets.dart';

/// Kerangka halaman Login/Registrasi ala PPPL.
/// HP: logo di atas, kartu menempel ke bawah layar.
/// Lebar (>= 900): dua kolom, panel primer di kiri, kartu form di kanan.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= batasDesktop) return _desktop(context, c);
            return _mobile(context);
          },
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (Navigator.canPop(context))
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BackButton(),
                ),
              const LogoMarkir(height: 44),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.permukaan,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(
                    top: BorderSide(color: AppColors.garis),
                    left: BorderSide(color: AppColors.garis),
                    right: BorderSide(color: AppColors.garis),
                  ),
                  boxShadow: bayanganKartu,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktop(BuildContext context, BoxConstraints c) {
    final tinggi = (c.maxHeight - 48).clamp(480.0, 640.0);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1152),
          child: SizedBox(
            height: tinggi,
            child: Row(
              children: [
                const Expanded(child: _PanelKiri()),
                const SizedBox(width: 24),
                SizedBox(
                  width: 448,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.permukaan,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.garis),
                      boxShadow: bayanganKartu,
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(child: LogoMarkir(height: 44)),
                            const SizedBox(height: 24),
                            child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelKiri extends StatelessWidget {
  const _PanelKiri();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.primer,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Padding(
              padding: EdgeInsets.all(32),
              child: Align(
                alignment: Alignment.topLeft,
                child: LogoMarkir(height: 44, krem: true),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Color(0x00000000)],
                  ),
                ),
                child: const Text(
                  'Pesan slot parkir sebelum berangkat, datang tinggal scan.',
                  style: TextStyle(
                    color: AppColors.onPrimer,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
