import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/models/product_model.dart';
import '../../providers/public_products_provider.dart';
import '../../../auth/providers/auth_provider.dart';

final _currencyFmt = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

class ProductDetailPage extends ConsumerWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(publicProductDetailProvider(productId));
    final isLoggedIn   = ref.watch(authProvider).status == AuthStatus.authenticated;

    return productAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/'),
          ),
        ),
        body: const Center(child: Text('Produit introuvable')),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => context.go('/'),
              ),
            ),
            body: const Center(child: Text('Produit introuvable')),
          );
        }
        return _ProductDetailView(
          product: product,
          isLoggedIn: isLoggedIn,
        );
      },
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  final ProductModel product;
  final bool isLoggedIn;

  const _ProductDetailView({
    required this.product,
    required this.isLoggedIn,
  });

  Color get _categoryColor {
    final hex = product.category?.color;
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Image hero + AppBar flottant ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: GestureDetector(
              onTap: () => context.go('/'),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _HeroPlaceholder(color: _categoryColor),
                    )
                  : _HeroPlaceholder(color: _categoryColor),
            ),
          ),

          // ── Contenu ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie + badge stock
                  Row(
                    children: [
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            product.category!.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                      const Spacer(),
                      _StockBadge(product: product),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Nom
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Prix
                  Text(
                    _currencyFmt.format(product.price),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Badges certifications
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                          icon: Icons.eco_outlined,
                          label: '100% Naturel',
                          color: AppColors.secondary),
                      _Badge(
                          icon: Icons.no_food_outlined,
                          label: 'Sans conservateur',
                          color: AppColors.success),
                      _Badge(
                          icon: Icons.verified_outlined,
                          label: 'Certifié ITRA',
                          color: AppColors.primary),
                      _Badge(
                          icon: Icons.flag_outlined,
                          label: 'Made in Togo',
                          color: AppColors.warning),
                    ],
                  ),

                  // Description / vertus
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 12),
                    Text(
                      'Vertus & bienfaits',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _VertusSection(description: product.description!),
                  ],

                  const SizedBox(height: 28),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 20),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: product.isOutOfStock
                          ? null
                          : () {
                              if (isLoggedIn) {
                                context.go('/sales');
                              } else {
                                context.go('/register');
                              }
                            },
                      icon: Icon(
                        isLoggedIn
                            ? Icons.shopping_cart_outlined
                            : Icons.person_add_outlined,
                        size: 20,
                      ),
                      label: Text(
                        product.isOutOfStock
                            ? 'Rupture de stock'
                            : isLoggedIn
                                ? 'Commander maintenant'
                                : 'Créer un compte pour commander',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(
                          Icons.arrow_back_outlined, size: 18),
                      label: Text(
                        'Voir tous les produits',
                        style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero placeholder ──────────────────────────────────────────────────────────

class _HeroPlaceholder extends StatelessWidget {
  final Color color;
  const _HeroPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.local_drink,
            color: color.withValues(alpha: 0.3), size: 96),
      ),
    );
  }
}

// ── Stock badge ───────────────────────────────────────────────────────────────

class _StockBadge extends StatelessWidget {
  final ProductModel product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    final (label, color) = product.isOutOfStock
        ? ('Rupture', AppColors.error)
        : product.isLowStock
            ? ('Stock limité', AppColors.warning)
            : ('En stock', AppColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge certif ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vertus ────────────────────────────────────────────────────────────────────

class _VertusSection extends StatelessWidget {
  final String description;
  const _VertusSection({required this.description});

  @override
  Widget build(BuildContext context) {
    // Séparer par lignes ou points numérotés
    final lines = description
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return Text(
        description,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: lines.asMap().entries.map((entry) {
          final i    = entry.key;
          final line = entry.value;
          final isLast = i == lines.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        // Enlever les "1. " "- " au début si présents
                        line.replaceFirst(RegExp(r'^[\d]+\.\s*'), '')
                            .replaceFirst(RegExp(r'^[-*•]\s*'), ''),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1, indent: 46, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}
