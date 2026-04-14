import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/sales/presentation/pages/receipt_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/deliveries/presentation/pages/deliveries_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/about/presentation/pages/about_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session    = Supabase.instance.client.auth.currentSession;
      final loc        = state.matchedLocation;
      final authRoutes = {'/login', '/register'};
      // '/' , '/about' et '/home' sont accessibles sans connexion
      final publicRoutes = {'/', '/login', '/register', '/about', '/home'};

      // Connecté → jamais sur la landing ni login/register
      if (session != null && (loc == '/' || authRoutes.contains(loc))) return '/home';

      // Pas connecté → jamais sur les pages protégées (sauf celles listées)
      if (session == null && !publicRoutes.contains(loc)) return '/';

      return null;
    },
    routes: [
      // ── Pages publiques ──────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (_, __) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      // /about hors ShellRoute → pas de nav bar, accessible sans session
      GoRoute(
        path: '/about',
        builder: (_, __) => const AboutPage(),
      ),

      // ── Pages avec nav bar (ShellRoute) ─────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: '/sales',
            builder: (_, __) => const SalesPage(),
          ),
          GoRoute(
            path: '/sales/receipt/:id',
            builder: (_, state) => ReceiptPage(
              saleId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (_, __) => const ProductsPage(),
          ),
          GoRoute(
            path: '/statistics',
            builder: (_, __) => const StatisticsPage(),
          ),
          GoRoute(
            path: '/deliveries',
            builder: (_, __) => const DeliveriesPage(),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const ChatPage(),
          ),
        ],
      ),
    ],
  );
});