// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/tuxie_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('🐱 main: initializing Supabase...');
    await initSupabase();
    debugPrint('🐱 main: Supabase initialized');

    // Validate stored session against server
    final session = supabase.auth.currentSession;
    debugPrint('🐱 main: session present=${session != null}');

    if (session != null) {
      try {
        debugPrint('🐱 main: validating session...');
        await supabase
            .from('profiles')
            .select('id')
            .eq('id', session.user.id)
            .single();
        debugPrint('🐱 main: session valid');
      } catch (e) {
        debugPrint('🐱 main: session invalid — signing out ($e)');
        await supabase.auth.signOut();
      }
    }

    debugPrint('🐱 main: launching app...');
    runApp(const ProviderScope(child: TuxieApp()));
    debugPrint('🐱 main: app launched');

  } catch (e, stack) {
    debugPrint('🐱 main: FATAL ERROR — $e');
    debugPrint('🐱 main: stack — $stack');

    // Show error screen instead of blank crash
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🐱', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text('Tuxie failed to start',
                  style: TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(e.toString(),
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

class TuxieApp extends ConsumerWidget {
  const TuxieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('🐱 TuxieApp: building');
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Tuxie',
      theme: tuxieTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}