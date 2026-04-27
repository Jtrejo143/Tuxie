// lib/core/supabase/supabase_config.dart
// Supabase client — single source of truth for the connection

import 'package:supabase_flutter/supabase_flutter.dart';

// ── REPLACE THESE WITH YOUR ACTUAL VALUES ────────────────────────
// Found in: Supabase Dashboard → Settings → API
const supabaseUrl  = 'https://wxbcaxoeavfazeokdjdw.supabase.co';
const supabaseAnon = 'sb_publishable_hUKwmiX9xk2B2pXQa2w-gg_gR36q6l0';
// ─────────────────────────────────────────────────────────────────

// Shorthand accessor used throughout the app
// Usage: supabase.from('tasks').select()
final supabase = Supabase.instance.client;

// Initialize — called once in main.dart before runApp
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnon,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );
}
