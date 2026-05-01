import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../chat/providers/chat_provider.dart';
import '../../providers/home_stats_provider.dart';

// ─── Formatters ──────────────────────────────────────────────────────────────

final _currencyFmt = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);
final _dateFmt = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // ── Nav Admin ────────────────────────────────────────────────────────────────
  static const _adminNav = [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home,              label: 'Accueil',  path: '/home'),
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale,     label: 'Ventes',   path: '/sales'),
    _NavItem(icon: Icons.local_shipping_outlined,activeIcon: Icons.local_shipping,    label: 'Livraisons',path: '/deliveries'),
    _NavItem(icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart,         label: 'Stats',    path: '/statistics'),
    _NavItem(icon: Icons.chat_bubble_outline,    activeIcon: Icons.chat_bubble,       label: 'Messages', path: '/chat'),
  ];

  // ── Nav Client ───────────────────────────────────────────────────────────────
  static const _clientNav = [
    _NavItem(icon: Icons.home_outlined,          activeIcon: Icons.home,              label: 'Accueil',   path: '/home'),
    _NavItem(icon: Icons.storefront_outlined,    activeIcon: Icons.storefront,        label: 'Catalogue', path: '/products'),
    _NavItem(icon: Icons.add_shopping_cart_outlined, activeIcon: Icons.add_shopping_cart, label: 'Commander', path: '/sales'),
    _NavItem(icon: Icons.chat_bubble_outline,    activeIcon: Icons.chat_bubble,       label: 'Chat',      path: '/chat'),
    _NavItem(icon: Icons.person_outline,         activeIcon: Icons.person,            label: 'Profil',    path: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin    = ref.watch(isAdminProvider);
    final navItems   = isAdmin ? _adminNav : _clientNav;
    final unread     = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    final location   = GoRouterState.of(context).uri.toString();

    final currentIndex = () {
      final i = navItems.indexWhere((n) => location.startsWith(n.path));
      return i < 0 ? 0 : i;
    }();

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(navItems[i].path),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: navItems.map((item) {
          final isChatItem = item.path == '/chat';
          final badgeCount = isChatItem ? unread : 0;
          final showBadge  = badgeCount > 0;
          return BottomNavigationBarItem(
            icon: showBadge
                ? Badge(
                    label: Text('$badgeCount',
                        style: const TextStyle(fontSize: 10)),
                    child: Icon(item.icon),
                  )
                : Icon(item.icon),
            activeIcon: showBadge
                ? Badge(
                    label: Text('$badgeCount',
                        style: const TextStyle(fontSize: 10)),
                    child: Icon(item.activeIcon),
                  )
                : Icon(item.activeIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOME PAGE — bascule admin / client selon le rôle
// ═══════════════════════════════════════════════════════════════════════════════

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Auth encore en cours d'initialisation → spinner
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final profile = authState.user;
    if (profile == null) {
      // Non connecté → rediriger vers login après le frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return profile.isAdmin
        ? _AdminHomePage(profile: profile)
        : _ClientHomePage(profile: profile);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VUE ADMIN
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminHomePage extends ConsumerWidget {
  final UserProfile profile;
  const _AdminHomePage({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync     = ref.watch(adminHomeStatsProvider);
    final recentAsync    = ref.watch(recentSalesProvider);
    final lowStockAsync  = ref.watch(lowStockProductsProvider);
    final pendingCount   = ref.watch(pendingOrdersStreamProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(adminHomeStatsProvider);
          ref.invalidate(recentSalesProvider);
          ref.invalidate(lowStockProductsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            _buildAdminAppBar(context, profile, pendingCount),

            // ── Cartes stats ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: statsAsync.when(
                  loading: () => _StatsSkeletonGrid(),
                  error:   (e, _) => _ErrorCard(message: 'Impossible de charger les stats'),
                  data:    (stats) => _AdminStatsGrid(stats: stats),
                ),
              ),
            ),

            // ── Actions rapides ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _QuickActionsSection(context),
              ),
            ),

            // ── Stock faible ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: lowStockAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error:   (e, _) => const SizedBox.shrink(),
                  data:    (products) => products.isEmpty
                      ? const SizedBox.shrink()
                      : _LowStockSection(products: products),
                ),
              ),
            ),

            // ── Dernières ventes ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: recentAsync.when(
                  loading: () => _ListSkeleton(),
                  error:   (e, _) => _ErrorCard(message: 'Impossible de charger les ventes'),
                  data:    (sales) => _RecentSalesSection(
                    sales: sales,
                    onSeeAll: () => context.go('/sales'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _QuickActionsSection(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_shopping_cart,
        label: 'Nouvelle\nvente',
        color: AppColors.primary,
        onTap: () => context.go('/sales'),
      ),
      _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Produits',
        color: AppColors.secondary,
        onTap: () => context.go('/products'),
      ),
      _QuickAction(
        icon: Icons.local_shipping_outlined,
        label: 'Livraisons',
        color: AppColors.warning,
        onTap: () => context.go('/deliveries'),
      ),
      _QuickAction(
        icon: Icons.bar_chart,
        label: 'Statistiques',
        color: const Color(0xFF1565C0),
        onTap: () => context.go('/statistics'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Actions rapides'),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map((a) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _QuickActionCard(action: a),
                  )))
              .toList(),
        ),
      ],
    );
  }

  SliverAppBar _buildAdminAppBar(BuildContext context, UserProfile profile, int pendingCount) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      pinned: true,
      floating: false,
      snap: false,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_drink, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${profile.displayName} 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('EEEE dd MMMM', 'fr_FR').format(DateTime.now()),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        pendingCount > 0
            ? Badge(
                label: Text(
                  pendingCount > 9 ? '9+' : '$pendingCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () => context.go('/deliveries'),
                  tooltip: '$pendingCount commandes en attente',
                ),
              )
            : IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary),
                onPressed: () => context.go('/deliveries'),
              ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary,
              child: Text(
                profile.displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VUE CLIENT
// ═══════════════════════════════════════════════════════════════════════════════

class _ClientHomePage extends ConsumerWidget {
  final UserProfile profile;
  const _ClientHomePage({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync   = ref.watch(clientStatsProvider);
    final historyAsync = ref.watch(clientHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(clientStatsProvider);
          ref.invalidate(clientHistoryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── AppBar client ────────────────────────────────────────────────
            _buildClientAppBar(profile),

            // ── Bannière de bienvenue ────────────────────────────────────────
            SliverToBoxAdapter(
              child: _WelcomeBanner(profile: profile),
            ),

            // ── Stats résumé client ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: statsAsync.when(
                  loading: () => _StatsSkeletonRow(),
                  error:   (e, _) => const SizedBox.shrink(),
                  data:    (stats) => _ClientStatsRow(stats: stats),
                ),
              ),
            ),

            // ── Historique commandes ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: historyAsync.when(
                  loading: () => _ListSkeleton(),
                  error:   (e, _) => _ErrorCard(message: 'Impossible de charger votre historique'),
                  data:    (history) => _ClientHistorySection(history: history),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildClientAppBar(UserProfile profile) {
    return SliverAppBar(
      backgroundColor: AppColors.surface,
      floating: true,
      snap: true,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_drink, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Fellow Drink',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
              onPressed: () {},
            ),
            Positioned(
              right: 8, top: 8,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => context.go('/profile'),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.secondary,
                child: Text(
                  profile.displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════════════════

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Admin Stats Grid ─────────────────────────────────────────────────────────

class _AdminStatsGrid extends StatelessWidget {
  final AdminHomeStats stats;
  const _AdminStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: "Tableau de bord"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _StatCard(
                label: 'CA ce mois',
                value: _currencyFmt.format(stats.caAujourdhui),
                icon: Icons.payments_outlined,
                color: AppColors.primary,
                large: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'En attente',
                value: '${stats.ventesAujourdhui}',
                icon: Icons.hourglass_top_outlined,
                color: stats.ventesAujourdhui > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Stock faible',
                value: '${stats.produitsStockFaible}',
                icon: Icons.warning_amber_outlined,
                color: stats.produitsStockFaible > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Ventes ce mois',
                value: '${stats.livraisonsEnCours}',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool large;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: large ? 20 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Card ────────────────────────────────────────────────────────

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Low Stock Section ────────────────────────────────────────────────────────

class _LowStockSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _LowStockSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '⚠️ Stock faible',
          actionLabel: 'Gérer',
          onAction: () => context.go('/products'),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: products.asMap().entries.map((entry) {
              final i       = entry.key;
              final product = entry.value;
              final qty     = product['stock_quantity'] as int? ?? 0;
              final isLast  = i == products.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.local_drink,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            product['name'] as String? ?? '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: qty == 0
                                ? AppColors.error.withValues(alpha: 0.12)
                                : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            qty == 0 ? 'Rupture' : '$qty restant${qty > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: qty == 0
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, indent: 68, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Recent Sales Section ─────────────────────────────────────────────────────

class _RecentSalesSection extends StatelessWidget {
  final List<ClientActivity> sales;
  final VoidCallback onSeeAll;
  const _RecentSalesSection({required this.sales, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Dernières ventes',
          actionLabel: 'Voir tout',
          onAction: onSeeAll,
        ),
        const SizedBox(height: 12),
        if (sales.isEmpty)
          _EmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'Aucune vente aujourd\'hui',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: sales.asMap().entries.map((entry) {
                final i    = entry.key;
                final sale = entry.value;
                final isLast = i == sales.length - 1;

                return Column(
                  children: [
                    _SaleRow(sale: sale),
                    if (!isLast)
                      const Divider(
                          height: 1, indent: 16, color: AppColors.divider),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SaleRow extends StatelessWidget {
  final ClientActivity sale;
  const _SaleRow({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isCancelled = sale.status == 'cancelled';

    return GestureDetector(
      onTap: () => context.push('/sales/receipt/${sale.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isCancelled
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCancelled ? Icons.cancel_outlined : Icons.receipt_outlined,
                color: isCancelled ? AppColors.error : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.receiptNumber,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (sale.clientName != null && sale.clientName!.isNotEmpty)
                    Text(
                      sale.clientName!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    _dateFmt.format(sale.createdAt.toLocal()),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFmt.format(sale.totalAmount),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isCancelled
                        ? AppColors.error
                        : AppColors.textPrimary,
                    decoration: isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: sale.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Client Welcome Banner ─────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final UserProfile profile;
  const _WelcomeBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${profile.displayName} 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bienvenue sur Fellow Drink',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => context.go('/chat'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Contacter le support',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.local_drink, color: Colors.white38, size: 64),
        ],
      ),
    );
  }
}

// ── Client Stats Row ─────────────────────────────────────────────────────────

class _ClientStatsRow extends StatelessWidget {
  final ClientStats stats;
  const _ClientStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Commandes',
              value: '${stats.totalCommandes}',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Total dépensé',
              value: _currencyFmt.format(stats.totalDepense),
              icon: Icons.payments_outlined,
              color: AppColors.secondary,
              large: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'En cours',
              value: '${stats.commandesEnCours}',
              icon: Icons.pending_outlined,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Client History Section ───────────────────────────────────────────────────

class _ClientHistorySection extends StatelessWidget {
  final List<ClientActivity> history;
  const _ClientHistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'Mes commandes',
          actionLabel: 'Voir tout',
          onAction: () => context.push('/sales/history'),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          _EmptyState(
            icon: Icons.shopping_bag_outlined,
            message: 'Aucune commande pour le moment',
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: history.asMap().entries.map((entry) {
                final i    = entry.key;
                final sale = entry.value;
                final isLast = i == history.length - 1;

                return Column(
                  children: [
                    _SaleRow(sale: sale),
                    if (!isLast)
                      const Divider(
                          height: 1, indent: 16, color: AppColors.divider),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed'       => ('Complété', AppColors.success),
      'cancelled'       => ('Annulé', AppColors.error),
      'pending_payment' => ('En attente', AppColors.warning),
      'in_transit'      => ('En transit', const Color(0xFF1565C0)),
      'delivered'       => ('Livré', AppColors.success),
      _                 => (status, AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────────────

class _StatsSkeletonGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _SkeletonBox(height: 100)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 100)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _SkeletonBox(height: 100)),
            const SizedBox(width: 10),
            Expanded(child: _SkeletonBox(height: 100)),
          ],
        ),
      ],
    );
  }
}

class _StatsSkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(child: _SkeletonBox(height: 90)),
          const SizedBox(width: 10),
          Expanded(child: _SkeletonBox(height: 90)),
          const SizedBox(width: 10),
          Expanded(child: _SkeletonBox(height: 90)),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SkeletonBox(height: 64),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  const _SkeletonBox({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}