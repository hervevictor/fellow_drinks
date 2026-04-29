import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/product_model.dart';
import '../widgets/edit_product_dialog.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    return GestureDetector(
      onTap: () {
        if (isAdmin) {
          showDialog(
            context: context,
            builder: (_) => EditProductDialog(product: product),
          );
        } else {
          context.push('/product/${product.id}');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.accent,
                          child: const Icon(Icons.local_drink,
                              color: AppColors.primary, size: 40),
                        ),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Catégorie
                  if (product.category != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(
                            232, 125, 30, 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(product.category!.name,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryDark,
                        )),
                    ),

                  // Nom
                  Text(product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),

                  // Prix + stock
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} F',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        )),
                      _StockBadge(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.accent,
    child: const Center(
      child: Icon(Icons.local_drink,
          color: AppColors.primary, size: 40),
    ),
  );
}

class _StockBadge extends StatelessWidget {
  final ProductModel product;
  const _StockBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    String label;

    if (product.isOutOfStock) {
      bg = const Color.fromRGBO(211, 47, 47, 0.1);
      fg = AppColors.error;
      label = 'Rupture';
    } else if (product.isLowStock) {
      bg = const Color.fromRGBO(245, 124, 0, 0.1);
      fg = AppColors.warning;
      label = '${product.stockQuantity} rest.';
    } else {
      bg = const Color.fromRGBO(56, 142, 60, 0.1);
      fg = AppColors.success;
      label = '${product.stockQuantity}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        )),
    );
  }
}

