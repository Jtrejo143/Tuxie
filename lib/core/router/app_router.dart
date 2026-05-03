// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/shell/screens/main_shell.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/finance/screens/finance_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/placeholder_screens.dart';

// ── ROUTES ────────────────────────────────────────────────────────
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

// ── AUTH STATE ────────────────────────────────────────────────────
enum AuthState { loading, loggedOut, needsHousehold, ready }

// ── AUTH NOTIFIER ─────────────────────────────────────────────────
class AuthNotifier extends ChangeNotifier {
  AuthState _state = AuthState.loading;
  AuthState get state => _state;

  AuthNotifier() {
    debugPrint('🐱 AuthNotifier created');
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('🐱 Auth stream fired: ${data.event}');
      resolve();
    });
    resolve();
  }

  Future<void> resolve() async {
    debugPrint('🐱 resolve() called');

    final session = Supabase.instance.client.auth.currentSession;
    debugPrint('🐱 currentSession is ${session == null ? "NULL" : "PRESENT (user: ${session.user.id})"}');

    if (session == null) {
      debugPrint('🐱 → loggedOut');
      _state = AuthState.loggedOut;
      notifyListeners();
      return;
    }

    // Check token expiry locally before hitting the server
    final expiry = session.expiresAt;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    debugPrint('🐱 Token expiry: $expiry, now: $now, expired: ${expiry != null && expiry < now}');

    if (expiry != null && expiry < now) {
      debugPrint('🐱 Token expired locally → signing out → loggedOut');
      await Supabase.instance.client.auth.signOut();
      _state = AuthState.loggedOut;
      notifyListeners();
      return;
    }

    try {
      final userId = session.user.id;
      debugPrint('🐱 Querying household_members for userId: $userId');

      final result = await Supabase.instance.client
          .from('household_members')
          .select('household_id')
          .eq('profile_id', userId)
          .maybeSingle();

      debugPrint('🐱 household_members result: $result');

      if (result != null) {
        debugPrint('🐱 → ready');
        _state = AuthState.ready;
      } else {
        debugPrint('🐱 → needsHousehold');
        _state = AuthState.needsHousehold;
      }
    } on AuthException catch (e) {
      debugPrint('🐱 AuthException: $e → loggedOut');
      await Supabase.instance.client.auth.signOut();
      _state = AuthState.loggedOut;
    } catch (e) {
      debugPrint('🐱 Unexpected error: $e → loggedOut');
      await Supabase.instance.client.auth.signOut();
      _state = AuthState.loggedOut;
    }

    notifyListeners();
  }
}

final authNotifier = AuthNotifier();

// ChangeNotifierProvider — correctly creates reactive subscriptions.
// When AuthNotifier calls notifyListeners(), all FutureProviders
// doing ref.watch(authNotifierProvider) automatically re-run,
// fixing stale data bugs across all screens on user switch.
final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return authNotifier;
});

// ── ROUTER ────────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: notifier,

    redirect: (context, state) {
      final auth = notifier.state;
      final path = state.fullPath ?? '';
      debugPrint('🐱 redirect called — auth: $auth, path: $path');

      final isAuthRoute = path == Routes.login || path == Routes.signup;
      final isOnboarding = path == Routes.onboarding;

      switch (auth) {
        case AuthState.loading:
          debugPrint('🐱 redirect → null (loading)');
          return null;
        case AuthState.loggedOut:
          if (!isAuthRoute) {
            debugPrint('🐱 redirect → ${Routes.login}');
            return Routes.login;
          }
          return null;
        case AuthState.needsHousehold:
          if (!isOnboarding) {
            debugPrint('🐱 redirect → ${Routes.onboarding}');
            return Routes.onboarding;
          }
          return null;
        case AuthState.ready:
          if (isAuthRoute || isOnboarding) {
            debugPrint('🐱 redirect → ${Routes.home}');
            return Routes.home;
          }
          return null;
      }
// exhaustive fallback
    },

    routes: [
      GoRoute(path: Routes.login,      builder: (c, s) => const LoginScreen()),
      GoRoute(path: Routes.signup,     builder: (c, s) => const SignupScreen()),
      GoRoute(path: Routes.onboarding, builder: (c, s) => const OnboardingScreen()),

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
      body: Center(child: Text('Page not found: ${state.fullPath}')),
    ),
  );
});