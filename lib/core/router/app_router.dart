// lib/core/router/app_router.dart
// GoRouter config — handles navigation and auth guard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/shell/screens/main_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/placeholder_screens.dart';

// Route name constants
class Routes {
  static const login      = '/login';
  static const signup     = '/signup';
  static const onboarding = '/onboarding';
  static const home       = '/';
  static const calendar   = '/calendar';
  static const capture    = '/capture';
  static const finance    = '/finance';
  static const more       = '/more';
  static const goals      = '/more/goals';
  static const health     = '/more/health';
  static const inventory  = '/more/inventory';
  static const chat       = '/more/chat';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,

    // Auth redirect guard
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.fullPath == Routes.login ||
                          state.fullPath == Routes.signup ||
                          state.fullPath == Routes.onboarding;

      // Not logged in → send to login
      if (!isLoggedIn && !isAuthRoute) return Routes.login;

      // Logged in but no household → send to onboarding
      // (household check happens inside onboarding_screen)

      // Logged in and on auth page → send home
      if (isLoggedIn && isAuthRoute) return Routes.home;

      return null; // no redirect needed
    },

    routes: [
      // Auth routes (no shell)
      GoRoute(path: Routes.login,      builder: (c, s) => const LoginScreen()),
      GoRoute(path: Routes.signup,     builder: (c, s) => const SignupScreen()),
      GoRoute(path: Routes.onboarding, builder: (c, s) => const OnboardingScreen()),

      // Main app shell (contains bottom nav)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: Routes.home,     builder: (c, s) => const HomeScreen()),
          GoRoute(path: Routes.calendar, builder: (c, s) => const CalendarScreen()),
          GoRoute(path: Routes.capture,  builder: (c, s) => const CaptureScreen()),
          GoRoute(path: Routes.finance,  builder: (c, s) => const FinanceScreen()),
          GoRoute(
            path: Routes.more,
            builder: (c, s) => const MoreScreen(),
            routes: [
              GoRoute(path: 'goals',     builder: (c, s) => const GoalsScreen()),
              GoRoute(path: 'health',    builder: (c, s) => const HealthScreen()),
              GoRoute(path: 'inventory', builder: (c, s) => const InventoryScreen()),
              GoRoute(path: 'chat',      builder: (c, s) => const ChatScreen()),
            ],
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.fullPath}'),
      ),
    ),
  );
});
