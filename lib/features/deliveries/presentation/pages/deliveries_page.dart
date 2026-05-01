import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

final _currencyFmt =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMM • HH:mm', 'fr_FR');

// ── Model ─────────────────────────────────────────────────────────────────────

class _OrderRow {
  final String id;
  final String receiptNumber;
  final String? clientName;
  final String? clientPhone;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const _OrderRow({
    required this.id,
    required this.receiptNumber,
    this.clientName,
    this.clientPhone,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory _OrderRow.fromMap(Map<String, dynamic> m) => _OrderRow(
        id:            m['id'] as String,
        receiptNumber: m['receipt_number'] as String,
        clientName:    m['client_name'] as String?,
        clientPhone:   m['client_phone'] as String?,
        totalAmount:   (m['total_amount'] as num).toDouble(),
        status:        m['status'] as String? ?? 'completed',
        createdAt:     DateTime.parse(m['created_at'] as String),
      );
}

// ── Provider (public so receipt_page can invalidate it) ───────────────────────

final deliveriesOrdersProvider = FutureProvider<List<_OrderRow>>((ref) async {
  final data = await Supabase.instance.client
      .from('sales')
      .select(
          'id, receipt_number, client_name, client_phone, total_amount, status, created_at')
      .inFilter('status', ['completed', 'pending_payment'])
      .order('created_at', ascending: false)
      .limit(500);

  return (data as List)
      .map((e) => _OrderRow.fromMap(e as Map<String, dynamic>))
      .toList();
});

// ── Date filter enum ──────────────────────────────────────────────────────────

enum _DateFilter { today, week, month, custom }

// ═══════════════════════════════════════════════════════════════════════════════
// DELIVERIES PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class DeliveriesPage extends ConsumerStatefulWidget {
  const DeliveriesPage({super.key});

  @override
  ConsumerState<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends ConsumerState<DeliveriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  _DateFilter _filter = _DateFilter.today;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_OrderRow> _applyFilter(List<_OrderRow> orders) {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;

    switch (_filter) {
      case _DateFilter.today:
        from = DateTime(now.year, now.month, now.day);
        to   = from.add(const Duration(days: 1));
      case _DateFilter.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        from = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        to   = from.add(const Duration(days: 7));
      case _DateFilter.month:
        from = DateTime(now.year, now.month, 1);
        to   = DateTime(now.year, now.month + 1, 1);
      case _DateFilter.custom:
        if (_customFrom == null || _customTo == null) return orders;
        from = _customFrom!;
        to   = _customTo!.add(const Duration(days: 1));
    }

    return orders.where((o) {
      final d = o.createdAt.toLocal();
      return !d.isBefore(from) && d.isBefore(to);
    }).toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _filter     = _DateFilter.custom;
        _customFrom = picked.start;
        _customTo   = picked.end;
      });
    }
  }

  String get _customLabel {
    if (_customFrom == null || _customTo == null) return 'Période';
    final df = DateFormat('dd/MM', 'fr_FR');
    return '${df.format(_customFrom!)} – ${df.format(_customTo!)}';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(deliveriesOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Livraisons & Retraits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(deliveriesOrdersProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Erreur : $e',
              style: const TextStyle(
                  color: AppColors.error, fontFamily: 'Poppins')),
        ),
        data: (allOrders) {
          final filtered  = _applyFilter(allOrders);
          final pending   = filtered.where((o) => o.status == 'pending_payment').toList();
          final completed = filtered.where((o) => o.status == 'completed').toList();

          return Column(
            children: [
              // ── Filtres date ───────────────────────────────────────────
              _DateFilterBar(
                current:       _filter,
                customLabel:   _customLabel,
                onFilter:      (f) => setState(() => _filter = f),
                onCustomTap:   _pickCustomRange,
              ),

              // ── Résumé chiffres ────────────────────────────────────────
              _SummaryRow(pending: pending, completed: completed),

              // ── Tabs ───────────────────────────────────────────────────
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabs,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: 'En attente (${pending.length})'),
                    Tab(text: 'Validées (${completed.length})'),
                  ],
                ),
              ),

              // ── Listes ────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _OrderList(
                      orders: pending,
                      emptyMessage: 'Aucune commande en attente',
                      emptyIcon: Icons.hourglass_empty_outlined,
                      onRefresh: () async =>
                          ref.invalidate(deliveriesOrdersProvider),
                    ),
                    _OrderList(
                      orders: completed,
                      emptyMessage: 'Aucune commande validée',
                      emptyIcon: Icons.check_circle_outline,
                      onRefresh: () async =>
                          ref.invalidate(deliveriesOrdersProvider),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Date Filter Bar ───────────────────────────────────────────────────────────

class _DateFilterBar extends StatelessWidget {
  final _DateFilter current;
  final String customLabel;
  final ValueChanged<_DateFilter> onFilter;
  final VoidCallback onCustomTap;

  const _DateFilterBar({
    required this.current,
    required this.customLabel,
    required this.onFilter,
    required this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: "Aujourd'hui",
              selected: current == _DateFilter.today,
              onTap: () => onFilter(_DateFilter.today),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Cette semaine',
              selected: current == _DateFilter.week,
              onTap: () => onFilter(_DateFilter.week),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: 'Ce mois',
              selected: current == _DateFilter.month,
              onTap: () => onFilter(_DateFilter.month),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: customLabel,
              selected: current == _DateFilter.custom,
              icon: Icons.date_range_outlined,
              onTap: onCustomTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14,
                  color: selected ? Colors.white : AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<_OrderRow> pending;
  final List<_OrderRow> completed;

  const _SummaryRow({required this.pending, required this.completed});

  @override
  Widget build(BuildContext context) {
    final caCompleted =
        completed.fold<double>(0, (s, o) => s + o.totalAmount);
    final caPending =
        pending.fold<double>(0, (s, o) => s + o.totalAmount);

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'CA encaissé',
              value: _currencyFmt.format(caCompleted),
              color: AppColors.success,
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              label: 'En attente',
              value: _currencyFmt.format(caPending),
              color: AppColors.warning,
              icon: Icons.hourglass_top_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order List ────────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<_OrderRow> orders;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const _OrderList({
    required this.orders,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 56,
                color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final _OrderRow order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPending   = order.status == 'pending_payment';
    final statusColor = isPending ? AppColors.warning : AppColors.success;

    return GestureDetector(
      onTap: () => context.push('/sales/receipt/${order.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: statusColor.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPending
                    ? Icons.hourglass_top_outlined
                    : Icons.check_circle_outline,
                color: statusColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.receiptNumber,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (order.clientName != null &&
                      order.clientName!.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(order.clientName!,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
                  if (order.clientPhone != null &&
                      order.clientPhone!.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.phone_outlined,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(order.clientPhone!,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
                  Row(children: [
                    const Icon(Icons.access_time_outlined,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      _dateFmt.format(order.createdAt.toLocal()),
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.textSecondary),
                    ),
                  ]),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFmt.format(order.totalAmount),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPending ? 'En attente' : 'Validée',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
