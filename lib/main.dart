// lib/main.dart
// Tuxie — entry point

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/tuxie_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await initSupabase();

  runApp(
    // Riverpod scope wraps entire app for state management
    const ProviderScope(
      child: TuxieApp(),
    ),
  );
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
