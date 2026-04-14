import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../widgets/product_card.dart';
import '../widgets/add_product_dialog.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync  = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final productsAsync    = ref.watch(filteredProductsProvider);
    final searchCtrl       = TextEditingController(
      text: ref.watch(searchQueryProvider),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddProductDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) =>
                  ref.read(searchQueryProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchCtrl.clear();
                          ref.read(searchQueryProvider.notifier)
                              .state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filtres catégories
          categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return _CategoryChip(
                      label: 'Tous',
                      selected: selectedCategory == null,
                      onTap: () => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = null,
                    );
                  }
                  final cat = categories[i - 1];
                  return _CategoryChip(
                    label: cat.name,
                    selected: selectedCategory == cat.id,
                    onTap: () => ref
                        .read(selectedCategoryProvider.notifier)
                        .state = cat.id,
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 36),
            error: (_, __) => const SizedBox(height: 36),
          ),
          const SizedBox(height: 12),

          // Liste produits
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('Aucun produit trouvé',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          )),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 100),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) =>
                      ProductCard(product: products[i]),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                  style: GoogleFonts.poppins(
                      color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(0xFFEEEEEE),
          ),
        ),
        child: Text(label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? Colors.white
                : AppColors.textSecondary,
          )),
      ),
    );
  }
}


