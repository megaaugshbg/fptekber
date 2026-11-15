import 'package:supabase_flutter/supabase_flutter.dart';

/// Ganti dua nilai ini dengan punya project kalian:
/// Supabase Dashboard > Project Settings > API (atau menu "Connect").
const String supabaseUrl = 'https://hyznldjpikhpigokhcno.supabase.co';
const String supabaseAnonKey = 'sb_publishable_M0t-C9A_JBAlT9-xMAGcIg_o5MGoYsI'; 

/// Dipanggil sekali di main() sebelum runApp().
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseAnonKey,
    );
}

/// Shortcut supaya service lain cukup tulis `supabase.from(...)`.
SupabaseClient get supabase => Supabase.instance.client;
