import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/landing/presentation/pages/landing_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/sales/presentation/pages/receipt_page.dart';
import '../../features/sales/presentation/pages/sales_history_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/deliveries/presentation/pages/deliveries_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/landing/presentation/pages/product_detail_page.dart';
import '../../features/sales/data/models/sale_model.dart';
import '../../features/sales/presentation/pages/payment_gateway_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session      = Supabase.instance.client.auth.currentSession;
      final loc          = state.matchedLocation;
      final publicRoutes = {'/', '/login', '/register', '/about'};

      // Connecté sur la landing → accueil
      if (session != null && loc == '/') return '/home';

      // Pas connecté → pages protégées → landing
      // /product/:id est public (commence par /product/)
      if (session == null &&
          !publicRoutes.contains(loc) &&
          !loc.startsWith('/product')) {
        return '/';
      }

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
      GoRoute(
        path: '/about',
        builder: (_, __) => const AboutPage(),
      ),
      // Détail produit — public, pas de nav bar
      GoRoute(
        path: '/product/:id',
        builder: (_, state) => ProductDetailPage(
          productId: state.pathParameters['id']!,
        ),
      ),
      // Passerelle de paiement — plein écran, sans nav bar
      GoRoute(
        path: '/payment',
        builder: (_, state) => PaymentGatewayPage(
          sale: state.extra as SaleModel,
        ),
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
            path: '/sales/history',
            builder: (_, __) => const SalesHistoryPage(),
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
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});