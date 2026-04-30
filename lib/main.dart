// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/tuxie_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  // On startup, validate the stored session against the server.
  // If the user no longer exists or the token is rejected, sign out cleanly.
  // This handles deleted test users and expired sessions permanently.
  final session = supabase.auth.currentSession;
  if (session != null) {
    try {
      await supabase.from('profiles')
          .select('id')
          .eq('id', session.user.id)
          .single();
    } catch (_) {
      // Profile not found or token rejected — clear the session
      debugPrint('🐱 Stale session detected on startup — signing out');
      await supabase.auth.signOut();
    }
  }

  runApp(const ProviderScope(child: TuxieApp()));
}

class TuxieApp extends ConsumerWidget {
  const TuxieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Tuxie',
      theme: tuxieTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}