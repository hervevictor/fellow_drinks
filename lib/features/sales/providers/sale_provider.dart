import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sale_model.dart';
import '../data/repositories/sale_repository.dart';
import '../../products/data/models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../../home/providers/home_stats_provider.dart';

// ── Repository ─────────────────────────────────────────────────────────────────

final saleRepositoryProvider = Provider<SaleRepository>(
  (_) => SaleRepository(),
);

// ── Sales list (admin) ─────────────────────────────────────────────────────────

final salesListProvider = FutureProvider<List<SaleModel>>((ref) async {
  return ref.watch(saleRepositoryProvider).getSales();
});

// ── Sale detail ────────────────────────────────────────────────────────────────

final saleDetailProvider =
    FutureProvider.family<SaleModel, String>((ref, id) async {
  return ref.watch(saleRepositoryProvider).getSaleById(id);
});

// ── Cart ───────────────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void addItem(ProductModel product) {
    final idx = state.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      final current = state[idx];
      final maxQty  = product.stockQuantity;
      if (current.quantity >= maxQty) return;
      state = [
        ...state.sublist(0, idx),
        current.copyWith(quantity: current.quantity + 1),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(String productId) {
    final idx = state.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    final current = state[idx];
    if (current.quantity <= 1) {
      state = [...state.sublist(0, idx), ...state.sublist(idx + 1)];
    } else {
      state = [
        ...state.sublist(0, idx),
        current.copyWith(quantity: current.quantity - 1),
        ...state.sublist(idx + 1),
      ];
    }
  }

  void clear() => state = const [];
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>(
  (_) => CartNotifier(),
);

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, i) => sum + i.subtotal);
});

// ── Sale creation notifier ─────────────────────────────────────────────────────

class SaleCreationNotifier extends StateNotifier<AsyncValue<void>> {
  final SaleRepository _repo;
  final Ref _ref;

  SaleCreationNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<SaleModel?> createSale({
    required List<CartItem> items,
    String? clientName,
    String? clientPhone,
    String? paymentMethod,
    bool pendingPayment = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sale = await _repo.createSale(
        items:          items,
        clientName:     clientName,
        clientPhone:    clientPhone,
        paymentMethod:  paymentMethod,
        pendingPayment: pendingPayment,
      );
      _ref.read(cartProvider.notifier).clear();
      _ref.invalidate(salesListProvider);
      _ref.invalidate(clientHistoryProvider);
      _ref.invalidate(clientStatsProvider);
      _ref.invalidate(filteredProductsProvider);
      state = const AsyncValue.data(null);
      return sale;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<void> cancelSale({
    required String saleId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelSale(saleId: saleId, reason: reason);
      _ref.invalidate(salesListProvider);
      _ref.invalidate(saleDetailProvider(saleId));
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<SaleModel?> confirmPayment({
    required String saleId,
    String? paymentReference,
  }) async {
    state = const AsyncValue.loading();
    try {
      final sale = await _repo.confirmPayment(
        saleId:           saleId,
        paymentReference: paymentReference,
      );
      _ref.invalidate(salesListProvider);
      _ref.invalidate(saleDetailProvider(saleId));
      state = const AsyncValue.data(null);
      return sale;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return null;
    }
  }
}

final saleCreationProvider =
    StateNotifierProvider<SaleCreationNotifier, AsyncValue<void>>(
  (ref) => SaleCreationNotifier(
    ref.watch(saleRepositoryProvider),
    ref,
  ),
);
