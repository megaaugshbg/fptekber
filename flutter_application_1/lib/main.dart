import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/beranda_screen.dart';
import 'screens/login_screen.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const MarkirApp());
}

class MarkirApp extends StatelessWidget {
  const MarkirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markir.in',
      debugShowCheckedModeBanner: false,
      theme: buatTema(),
      home: const AuthGate(),
    );
  }
}

/// Belum login → Login, sudah login → Beranda.
/// Ikut perubahan sesi, jadi pindah halaman otomatis.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Tunggu event sesi awal supaya user yang sudah login
        // tidak sempat melihat layar Login.
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFBBD0F5),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final sudahLogin = supabase.auth.currentSession != null;
        return sudahLogin ? const BerandaScreen() : const LoginScreen();
      },
    );
  }
}