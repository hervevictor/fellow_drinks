import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_model.dart';
import '../data/models/category_model.dart';
import '../data/repositories/product_repository.dart';
import '../../landing/providers/public_products_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (_) => ProductRepository(),
);

// ── Catégories ─────────────────────────────────────────────────────────────

final categoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

// ── Filtre catégorie sélectionnée ──────────────────────────────────────────

final selectedCategoryProvider =
    StateProvider<String?>((ref) => null);

// ── Produits avec filtre ───────────────────────────────────────────────────

final productsProvider =
    FutureProvider<List<ProductModel>>((ref) async {
  final categoryId = ref.watch(selectedCategoryProvider);
  return ref.watch(productRepositoryProvider).getProducts(
    categoryId: categoryId,
  );
});

// ── Recherche ──────────────────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredProductsProvider =
    Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return productsAsync.when(
    data: (products) {
      if (query.isEmpty) return AsyncValue.data(products);
      return AsyncValue.data(
        products.where((p) =>
          p.name.toLowerCase().contains(query) ||
          (p.description?.toLowerCase().contains(query) ?? false) ||
          (p.category?.name.toLowerCase().contains(query) ?? false),
        ).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// ── CRUD Notifier ──────────────────────────────────────────────────────────

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;
  final Ref _ref;

  ProductNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  void _invalidateAll() {
    _ref.invalidate(productsProvider);
    _ref.invalidate(publicProductsProvider);
  }

  Future<void> createProduct({
    required String name,
    String? categoryId,
    required double price,
    required int stockQuantity,
    String? imageUrl,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createProduct(
        name:          name,
        categoryId:    categoryId,
        price:         price,
        stockQuantity: stockQuantity,
        imageUrl:      imageUrl,
        description:   description,
      );
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateProduct(id: id, updates: updates);
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteProduct(id);
      _invalidateAll();
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> updateStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      await _repo.updateStock(
          productId: productId, quantity: quantity);
      _ref.invalidate(productsProvider);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>(
  (ref) => ProductNotifier(
    ref.watch(productRepositoryProvider),
    ref,
  ),
);