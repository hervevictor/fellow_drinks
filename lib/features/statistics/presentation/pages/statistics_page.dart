import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

final _currencyFmt =
    NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

// ── Models ────────────────────────────────────────────────────────────────────

class _DayRevenue {
  final DateTime date;
  final double amount;
  final int count;
  const _DayRevenue(this.date, this.amount, this.count);
}

class _TopProduct {
  final String name;
  final double revenue;
  final int quantity;
  const _TopProduct(this.name, this.revenue, this.quantity);
}

class _StatsData {
  final double revenueTotal;
  final double revenueMonth;
  final int salesTotal;
  final int salesMonth;
  final double avgBasket;
  final List<_DayRevenue> last7Days;
  final List<_TopProduct> topProducts;
  final Map<String, double> byPayment;
  const _StatsData({
    required this.revenueTotal,
    required this.revenueMonth,
    required this.salesTotal,
    required this.salesMonth,
    required this.avgBasket,
    required this.last7Days,
    required this.topProducts,
    required this.byPayment,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _statsProvider = FutureProvider<_StatsData>((ref) async {
  final client = Supabase.instance.client;
  final now    = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

  // All completed sales
  final allSales = await client
      .from('sales')
      .select('total_amount, created_at, payment_method')
      .eq('status', 'completed');

  final sales = (allSales as List).cast<Map<String, dynamic>>();

  final revenueTotal = sales.fold<double>(
      0, (s, e) => s + (e['total_amount'] as num).toDouble());
  final salesTotal = sales.length;

  final monthlySales = sales.where((e) =>
      DateTime.parse(e['created_at'] as String).isAfter(
          DateTime.parse(monthStart)));
  final revenueMonth = monthlySales.fold<double>(
      0, (s, e) => s + (e['total_amount'] as num).toDouble());
  final salesMonth = monthlySales.length;

  final avgBasket =
      salesTotal > 0 ? revenueTotal / salesTotal : 0.0;

  // Last 7 days grouped by day
  final last7Days = <_DayRevenue>[];
  for (var i = 6; i >= 0; i--) {
    final day   = now.subtract(Duration(days: i));
    final start = DateTime(day.year, day.month, day.day);
    final end   = start.add(const Duration(days: 1));
    final daySales = sales.where((e) {
      final d = DateTime.parse(e['created_at'] as String);
      return d.isAfter(start) && d.isBefore(end);
    });
    final amount = daySales.fold<double>(
        0, (s, e) => s + (e['total_amount'] as num).toDouble());
    last7Days.add(_DayRevenue(start, amount, daySales.length));
  }

  // Top 5 products by revenue
  final itemsData = await client
      .from('sale_items')
      .select('product_id, quantity, subtotal, products(name)')
      .order('subtotal', ascending: false);

  final Map<String, Map<String, dynamic>> productAgg = {};
  for (final item in (itemsData as List)) {
    final id  = item['product_id'] as String;
    final name = (item['products'] as Map?)?['name'] as String? ?? 'Produit';
    final sub  = (item['subtotal'] as num).toDouble();
    final qty  = (item['quantity'] as num).toInt();
    if (productAgg.containsKey(id)) {
      productAgg[id]!['revenue'] =
          (productAgg[id]!['revenue'] as double) + sub;
      productAgg[id]!['quantity'] =
          (productAgg[id]!['quantity'] as int) + qty;
    } else {
      productAgg[id] = {'name': name, 'revenue': sub, 'quantity': qty};
    }
  }

  final topProducts = productAgg.values
      .map((e) => _TopProduct(
            e['name'] as String,
            e['revenue'] as double,
            e['quantity'] as int,
          ))
      .toList()
    ..sort((a, b) => b.revenue.compareTo(a.revenue));

  // Revenue by payment method
  final Map<String, double> byPayment = {};
  for (final s in sales) {
    final method = (s['payment_method'] as String?) ?? 'cash';
    byPayment[method] =
        (byPayment[method] ?? 0) + (s['total_amount'] as num).toDouble();
  }

  return _StatsData(
    revenueTotal:  revenueTotal,
    revenueMonth:  revenueMonth,
    salesTotal:    salesTotal,
    salesMonth:    salesMonth,
    avgBasket:     avgBasket,
    last7Days:     last7Days,
    topProducts:   topProducts.take(5).toList(),
    byPayment:     byPayment,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════
// STATISTICS PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(_statsProvider),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Erreur : $e',
              style: const TextStyle(
                  color: AppColors.error, fontFamily: 'Poppins')),
        ),
        data: (stats) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(_statsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── KPIs ───────────────────────────────────────────────────────
              _SectionTitle('Vue d\'ensemble'),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: _KpiCard(
                    label: 'CA total',
                    value: _currencyFmt.format(stats.revenueTotal),
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: 'CA ce mois',
                    value: _currencyFmt.format(stats.revenueMonth),
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Ventes totales',
                    value: '${stats.salesTotal}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: 'Panier moyen',
                    value: _currencyFmt.format(stats.avgBasket),
                    icon: Icons.shopping_basket_outlined,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── 7 derniers jours ───────────────────────────────────────────
              _SectionTitle('Revenus — 7 derniers jours'),
              const SizedBox(height: 12),
              _BarChart(days: stats.last7Days),
              const SizedBox(height: 24),

              // ── Top produits ───────────────────────────────────────────────
              _SectionTitle('Top produits par revenu'),
              const SizedBox(height: 12),
              if (stats.topProducts.isEmpty)
                const _EmptyCard(message: 'Aucune vente enregistrée')
              else
                _TopProductsList(
                  products: stats.topProducts,
                  maxRevenue: stats.topProducts.first.revenue,
                ),
              const SizedBox(height: 24),

              // ── Paiements ──────────────────────────────────────────────────
              _SectionTitle('Répartition des paiements'),
              const SizedBox(height: 12),
              _PaymentBreakdown(
                byPayment: stats.byPayment,
                total: stats.revenueTotal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: Offset(0, 2)),
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
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

// ── Bar Chart (custom, no lib) ────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<_DayRevenue> days;
  const _BarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final max = days.fold<double>(0, (m, d) => d.amount > m ? d.amount : m);

    return Container(
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
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final ratio = max > 0 ? d.amount / max : 0.0;
                final label = DateFormat('E', 'fr_FR').format(d.date);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (d.amount > 0)
                          Text(
                            d.count > 0 ? '${d.count}' : '',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            height: (ratio * 100).clamp(4, 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
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
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total 7j : ${_currencyFmt.format(days.fold<double>(0, (s, d) => s + d.amount))}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${days.fold<int>(0, (s, d) => s + d.count)} ventes',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Top Products List ─────────────────────────────────────────────────────────

class _TopProductsList extends StatelessWidget {
  final List<_TopProduct> products;
  final double maxRevenue;
  const _TopProductsList(
      {required this.products, required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
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
        children: products.asMap().entries.map((entry) {
          final i    = entry.key;
          final p    = entry.value;
          final ratio = maxRevenue > 0 ? p.revenue / maxRevenue : 0.0;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: _rankColor(i).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _rankColor(i),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: AppColors.accent,
                              valueColor: AlwaysStoppedAnimation(
                                  _rankColor(i)),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFmt.format(p.revenue),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${p.quantity} vendus',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (i < products.length - 1)
                const Divider(height: 1, indent: 16, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _rankColor(int index) {
    return switch (index) {
      0 => const Color(0xFFF57C00),
      1 => const Color(0xFF607D8B),
      2 => const Color(0xFF795548),
      _ => AppColors.primary,
    };
  }
}

// ── Payment Breakdown ─────────────────────────────────────────────────────────

class _PaymentBreakdown extends StatelessWidget {
  final Map<String, double> byPayment;
  final double total;
  const _PaymentBreakdown(
      {required this.byPayment, required this.total});

  static const _labels = {
    'cash':         ('Espèces',       Icons.payments_outlined,      AppColors.secondary),
    'mobile_money': ('Mobile Money',  Icons.phone_android_outlined,  AppColors.primary),
    'card':         ('Carte bancaire',Icons.credit_card_outlined,   Color(0xFF6A1B9A)),
  };

  @override
  Widget build(BuildContext context) {
    if (byPayment.isEmpty) {
      return const _EmptyCard(message: 'Aucune donnée de paiement');
    }

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
        children: byPayment.entries.map((entry) {
          final method  = entry.key;
          final amount  = entry.value;
          final ratio   = total > 0 ? amount / total : 0.0;
          final info    = _labels[method] ??
              ('Autre', Icons.help_outline, AppColors.textSecondary);
          final (label, icon, color) = info;
          final isLast =
              entry.key == byPayment.keys.last;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(ratio * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: AppColors.accent,
                              valueColor:
                                  AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFmt.format(amount),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
}
