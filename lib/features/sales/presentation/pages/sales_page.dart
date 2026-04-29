import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/providers/product_provider.dart';
import '../../data/models/sale_model.dart';
import '../../providers/sale_provider.dart';

final _currencyFmt = NumberFormat.currency(
    locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMM • HH:mm', 'fr_FR');

// ═══════════════════════════════════════════════════════════════════════════════
// SALES PAGE — bascule admin/client
// ═══════════════════════════════════════════════════════════════════════════════

class SalesPage extends ConsumerWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return profile.isAdmin
        ? const _AdminSalesPage()
        : const _ClientSalesPage();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VUE ADMIN — liste des ventes + bouton nouvelle vente
// ═══════════════════════════════════════════════════════════════════════════════

class _AdminSalesPage extends ConsumerWidget {
  const _AdminSalesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, 'Ventes', actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(salesListProvider),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewSaleSheet(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle vente',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      ),
      body: salesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(message: e.toString()),
        data: (sales) => sales.isEmpty
            ? const _EmptyBody(
                icon: Icons.receipt_long_outlined,
                message: 'Aucune vente enregistrée')
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async => ref.invalidate(salesListProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SaleCard(
                    sale: sales[i],
                    onTap: () => context.push('/sales/receipt/${sales[i].id}'),
                    onCancel: sales[i].isCompleted
                        ? () => _confirmCancel(context, ref, sales[i])
                        : null,
                  ),
                ),
              ),
      ),
    );
  }

  void _openNewSaleSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewSaleSheet(),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, SaleModel sale) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Annuler la vente',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vente ${sale.receiptNumber}',
              style: const TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Motif d\'annulation',
                hintText: 'Ex: Erreur de saisie...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(saleCreationProvider.notifier).cancelSale(
                    saleId: sale.id,
                    reason: reasonCtrl.text.trim(),
                  );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VUE CLIENT — catalogue + panier
// ═══════════════════════════════════════════════════════════════════════════════

class _ClientSalesPage extends ConsumerWidget {
  const _ClientSalesPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync  = ref.watch(filteredProductsProvider);
    final cartCount      = ref.watch(cartItemCountProvider);
    final cartTotal      = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(
        context,
        'Commander',
        actions: [
          if (cartCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => _openCartSheet(context, ref),
                ),
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: productsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorBody(message: e.toString()),
        data: (products) => Column(
          children: [
            // ── Recherche ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SearchBar(
                onChanged: (q) =>
                    ref.read(searchQueryProvider.notifier).state = q,
              ),
            ),
            // ── Filtres catégories ─────────────────────────────────────────
            const _CategoryChips(),
            // ── Grille produits ────────────────────────────────────────────
            Expanded(
              child: products.isEmpty
                  ? const _EmptyBody(
                      icon: Icons.search_off,
                      message: 'Aucun produit trouvé')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => _ProductOrderCard(
                        product: products[i],
                        onAdd: () => ref
                            .read(cartProvider.notifier)
                            .addItem(products[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // ── Bouton panier flottant ─────────────────────────────────────────────
      bottomNavigationBar: cartCount > 0
          ? _CartBottomBar(
              count: cartCount,
              total: cartTotal,
              onTap: () => _openCartSheet(context, ref),
            )
          : null,
    );
  }

  void _openCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CartSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET — Nouvelle vente (Admin)
// ═══════════════════════════════════════════════════════════════════════════════

class _NewSaleSheet extends ConsumerStatefulWidget {
  const _NewSaleSheet();

  @override
  ConsumerState<_NewSaleSheet> createState() => _NewSaleSheetState();
}

class _NewSaleSheetState extends ConsumerState<_NewSaleSheet> {
  final _clientNameCtrl  = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  String _paymentMethod  = 'cash';

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(filteredProductsProvider);
    final cart          = ref.watch(cartProvider);
    final total         = ref.watch(cartTotalProvider);
    final cartCount     = ref.watch(cartItemCountProvider);
    final creationState = ref.watch(saleCreationProvider);
    final isLoading     = creationState is AsyncLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Nouvelle vente',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (cartCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$cartCount article${cartCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Infos client ──────────────────────────────────────────
                  _SectionLabel(label: 'Informations client (optionnel)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _clientNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom client',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _clientPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Recherche produits ────────────────────────────────────
                  _SectionLabel(label: 'Ajouter des produits'),
                  const SizedBox(height: 8),
                  _SearchBar(
                    onChanged: (q) =>
                        ref.read(searchQueryProvider.notifier).state = q,
                  ),
                  const SizedBox(height: 8),
                  const _CategoryChips(),
                  const SizedBox(height: 8),

                  // ── Grille produits ───────────────────────────────────────
                  productsAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (e, _) => _ErrorBody(message: e.toString()),
                    data: (products) => GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => _ProductOrderCard(
                        product: products[i],
                        onAdd: () => ref
                            .read(cartProvider.notifier)
                            .addItem(products[i]),
                      ),
                    ),
                  ),

                  if (cart.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    // ── Récap panier ─────────────────────────────────────────
                    _SectionLabel(label: 'Récapitulatif'),
                    const SizedBox(height: 8),
                    _CartSummary(items: cart),
                    const SizedBox(height: 16),
                    // ── Total ─────────────────────────────────────────────────
                    _TotalRow(total: total),
                    const SizedBox(height: 20),
                    // ── Paiement ──────────────────────────────────────────────
                    _SectionLabel(label: 'Mode de paiement'),
                    const SizedBox(height: 8),
                    _PaymentPicker(
                      selected: _paymentMethod,
                      onChanged: (v) => setState(() => _paymentMethod = v),
                    ),
                    const SizedBox(height: 20),
                    // ── Bouton valider ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _submit(context),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Valider la vente'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    final sale = await ref.read(saleCreationProvider.notifier).createSale(
          items:         cart,
          clientName:    _clientNameCtrl.text.trim().isEmpty
              ? null
              : _clientNameCtrl.text.trim(),
          clientPhone:   _clientPhoneCtrl.text.trim().isEmpty
              ? null
              : _clientPhoneCtrl.text.trim(),
          paymentMethod: _paymentMethod,
        );

    if (sale != null && context.mounted) {
      Navigator.pop(context);
      context.push('/sales/receipt/${sale.id}');
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEET — Panier Client
// ═══════════════════════════════════════════════════════════════════════════════

class _CartSheet extends ConsumerStatefulWidget {
  const _CartSheet();

  @override
  ConsumerState<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<_CartSheet> {
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    // Afficher l'erreur si createSale échoue
    ref.listen<AsyncValue<void>>(saleCreationProvider, (_, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${next.error}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ));
      }
    });

    final cart          = ref.watch(cartProvider);
    final total         = ref.watch(cartTotalProvider);
    final creationState = ref.watch(saleCreationProvider);
    final isLoading     = creationState is AsyncLoading;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Mon panier',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    child: const Text('Vider',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: cart.isEmpty
                  ? const _EmptyBody(
                      icon: Icons.shopping_cart_outlined,
                      message: 'Votre panier est vide')
                  : ListView(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _CartSummary(items: cart),
                        const SizedBox(height: 16),
                        _TotalRow(total: total),
                        const SizedBox(height: 20),
                        const _SectionLabel(label: 'Mode de paiement'),
                        const SizedBox(height: 8),
                        _PaymentPicker(
                          selected: _paymentMethod,
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => _submit(context),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Passer la commande'),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final cart   = ref.read(cartProvider);
    if (cart.isEmpty) return;
    final router = GoRouter.of(context);
    final nav    = Navigator.of(context);
    final sale   = await ref.read(saleCreationProvider.notifier).createSale(
          items:          cart,
          paymentMethod:  _paymentMethod,
          pendingPayment: true,
        );
    if (sale != null && mounted) {
      nav.pop();
      router.push('/payment', extra: sale);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGETS PARTAGÉS
// ═══════════════════════════════════════════════════════════════════════════════

// ── AppBar helper ─────────────────────────────────────────────────────────────

AppBar _buildAppBar(BuildContext context, String title,
    {List<Widget>? actions}) {
  return AppBar(
    title: Text(title),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppColors.divider),
    ),
  );
}

// ── Payment Picker ────────────────────────────────────────────────────────────

class _PaymentPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PaymentPicker({required this.selected, required this.onChanged});

  static const _methods = [
    ('cash',         Icons.payments_outlined,      'Espèces'),
    ('mobile_money', Icons.phone_android_outlined,  'Mobile Money'),
    ('card',         Icons.credit_card_outlined,    'Carte bancaire'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _methods.map((m) {
        final (value, icon, label) = m;
        final isSelected = selected == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 22,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Rechercher un produit...',
        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
        contentPadding: EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

// ── Category Chips ────────────────────────────────────────────────────────────

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final selected        = ref.watch(selectedCategoryProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
      data: (categories) => SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _chip(
              label: 'Tous',
              selected: selected == null,
              onTap: () =>
                  ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...categories.map((cat) => _chip(
                  label: cat.name,
                  selected: selected == cat.id,
                  onTap: () =>
                      ref.read(selectedCategoryProvider.notifier).state =
                          cat.id,
                )),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Product Order Card ────────────────────────────────────────────────────────

class _ProductOrderCard extends ConsumerWidget {
  final ProductModel product;
  final VoidCallback onAdd;
  const _ProductOrderCard({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart     = ref.watch(cartProvider);
    final cartItem = cart.where((i) => i.product.id == product.id).firstOrNull;
    final qtyInCart = cartItem?.quantity ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
            ),
          ),
          // Infos
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _currencyFmt.format(product.price),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                // Contrôle quantité
                product.isOutOfStock
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Rupture de stock',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.error,
                          ),
                        ),
                      )
                    : qtyInCart == 0
                        ? SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onAdd,
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Ajouter',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () => ref
                                    .read(cartProvider.notifier)
                                    .removeItem(product.id),
                              ),
                              Text(
                                '$qtyInCart',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: onAdd,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.accent,
        child: const Center(
            child: Icon(Icons.local_drink,
                color: AppColors.primary, size: 32)),
      );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}

// ── Sale Card (admin list) ────────────────────────────────────────────────────

class _SaleCard extends StatelessWidget {
  final SaleModel sale;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  const _SaleCard({required this.sale, required this.onTap, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 10,
                offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: sale.isCancelled
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                sale.isCancelled
                    ? Icons.cancel_outlined
                    : Icons.receipt_outlined,
                color: sale.isCancelled ? AppColors.error : AppColors.primary,
                size: 22,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (sale.clientName != null && sale.clientName!.isNotEmpty)
                    Text(
                      sale.clientName!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: sale.isCancelled
                        ? AppColors.error
                        : AppColors.textPrimary,
                    decoration:
                        sale.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusBadge(status: sale.status),
                if (onCancel != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onCancel,
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart Summary ──────────────────────────────────────────────────────────────

class _CartSummary extends ConsumerWidget {
  final List<CartItem> items;
  const _CartSummary({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i    = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${_currencyFmt.format(item.product.price)} × ${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove,
                          onTap: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.product.id),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add,
                          onTap: () => ref
                              .read(cartProvider.notifier)
                              .addItem(item.product),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currencyFmt.format(item.subtotal),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Total Row ─────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  final double total;
  const _TotalRow({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            _currencyFmt.format(total),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Bottom Bar ───────────────────────────────────────────────────────────

class _CartBottomBar extends StatelessWidget {
  final int count;
  final double total;
  final VoidCallback onTap;
  const _CartBottomBar({
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Voir mon panier',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _currencyFmt.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

// ── Empty / Error bodies ──────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyBody({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _ErrorBody extends StatelessWidget {
  final String message;
  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Erreur : $message',
            style: const TextStyle(color: AppColors.error, fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
          ),
        ),
      );
}

