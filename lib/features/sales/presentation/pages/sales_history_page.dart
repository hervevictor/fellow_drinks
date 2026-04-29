import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/sale_model.dart';

final _currencyFmt = NumberFormat.currency(
    locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');

// ── Filter state ───────────────────────────────────────────────────────────────

enum _HistoryFilter { all, completed, cancelled }

final _historyFilterProvider =
    StateProvider<_HistoryFilter>((_) => _HistoryFilter.all);

// ── Full client history provider ───────────────────────────────────────────────

final clientFullHistoryProvider =
    FutureProvider<List<SaleModel>>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return [];

  final data = await Supabase.instance.client
      .from('sales')
      .select('*, sale_items(*, products(*, categories(*)))')
      .eq('created_by', session.user.id)
      .order('created_at', ascending: false);

  return (data as List)
      .map((e) => SaleModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

// ═══════════════════════════════════════════════════════════════════════════════
// SALES HISTORY PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class SalesHistoryPage extends ConsumerWidget {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter      = ref.watch(_historyFilterProvider);
    final historyAsync = ref.watch(clientFullHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes commandes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(clientFullHistoryProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _FilterBar(current: filter),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => _ErrorView(message: e.toString()),
        data: (all) {
          final sales = switch (filter) {
            _HistoryFilter.completed => all.where((s) => s.isCompleted).toList(),
            _HistoryFilter.cancelled => all.where((s) => s.isCancelled).toList(),
            _HistoryFilter.all       => all,
          };

          if (sales.isEmpty) {
            return _EmptyView(
              message: filter == _HistoryFilter.all
                  ? 'Aucune commande pour l\'instant'
                  : 'Aucune commande dans ce filtre',
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.invalidate(clientFullHistoryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _OrderCard(sale: sales[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  final _HistoryFilter current;
  const _FilterBar({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _Chip(
            label: 'Toutes',
            selected: current == _HistoryFilter.all,
            onTap: () => ref.read(_historyFilterProvider.notifier).state =
                _HistoryFilter.all,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Complétées',
            selected: current == _HistoryFilter.completed,
            color: AppColors.success,
            onTap: () => ref.read(_historyFilterProvider.notifier).state =
                _HistoryFilter.completed,
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Annulées',
            selected: current == _HistoryFilter.cancelled,
            color: AppColors.error,
            onTap: () => ref.read(_historyFilterProvider.notifier).state =
                _HistoryFilter.cancelled,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.divider,
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

// ── Order card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final SaleModel sale;
  const _OrderCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final isCancel = sale.isCancelled;

    return GestureDetector(
      onTap: () => context.push('/sales/receipt/${sale.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: isCancel
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCancel
                        ? Icons.cancel_outlined
                        : Icons.receipt_long_outlined,
                    color: isCancel ? AppColors.error : AppColors.primary,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isCancel
                            ? AppColors.error
                            : AppColors.textPrimary,
                        decoration: isCancel
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

            // ── Items preview ────────────────────────────────────────────────
            if (sale.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              ...sale.items.take(3).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.product?.name ?? 'Produit'}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '× ${item.quantity}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (sale.items.length > 3)
                Text(
                  '+ ${sale.items.length - 3} autre(s) article(s)',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],

            // ── Payment method ───────────────────────────────────────────────
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  sale.paymentLabel,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Voir le reçu →',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'completed' => ('Complété', AppColors.success),
      'cancelled' => ('Annulé', AppColors.error),
      'pending'   => ('En attente', AppColors.warning),
      _           => (status, AppColors.textSecondary),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                )),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text('Erreur : $message',
            style: const TextStyle(
                color: AppColors.error, fontFamily: 'Poppins')),
      );
}
