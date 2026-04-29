import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/theme/app_theme.dart';
import '../../providers/sale_provider.dart';
import '../../data/models/sale_model.dart';

final _currencyFmt = NumberFormat.currency(
    locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');

// ═══════════════════════════════════════════════════════════════════════════════
// RECEIPT PAGE
// ═══════════════════════════════════════════════════════════════════════════════

class ReceiptPage extends ConsumerWidget {
  final String saleId;
  const ReceiptPage({super.key, required this.saleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saleAsync = ref.watch(saleDetailProvider(saleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reçu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/sales'),
        ),
        actions: [
          saleAsync.when(
            data: (sale) => IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () => _printReceipt(context, sale),
              tooltip: 'Imprimer',
            ),
            loading: () => const SizedBox.shrink(),
            error:   (_, __) => const SizedBox.shrink(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: saleAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text(
            'Erreur : $e',
            style: const TextStyle(color: AppColors.error, fontFamily: 'Poppins'),
          ),
        ),
        data: (sale) => _ReceiptBody(sale: sale),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, SaleModel sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'FELLOW DRINK',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Boissons naturelles',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 8),

            // Infos reçu
            pw.Text('Reçu : ${sale.receiptNumber}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date : ${_dateFmt.format(sale.createdAt.toLocal())}'),
            if (sale.clientName != null && sale.clientName!.isNotEmpty)
              pw.Text('Client : ${sale.clientName}'),
            if (sale.clientPhone != null && sale.clientPhone!.isNotEmpty)
              pw.Text('Tél : ${sale.clientPhone}'),
            pw.SizedBox(height: 12),
            pw.Divider(),

            // Lignes
            pw.Text('Détail de la commande',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
            pw.SizedBox(height: 8),
            ...sale.items.map((item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          item.product?.name ?? 'Produit',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                      pw.Text(
                        '${item.quantity} × ${_currencyFmt.format(item.unitPrice)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Text(
                        _currencyFmt.format(item.subtotal),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),

            pw.Divider(thickness: 2),
            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 15)),
                pw.Text(
                  _currencyFmt.format(sale.totalAmount),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                'Merci pour votre confiance !',
                style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'Recu_${sale.receiptNumber}',
    );
  }
}

// ── Corps du reçu ─────────────────────────────────────────────────────────────

class _ReceiptBody extends StatelessWidget {
  final SaleModel sale;
  const _ReceiptBody({required this.sale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Status banner ───────────────────────────────────────────────
          if (sale.isCancelled)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vente annulée${sale.cancelledReason != null ? ' : ${sale.cancelledReason}' : ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Carte reçu ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.08),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header reçu
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: sale.isCancelled
                        ? AppColors.error.withValues(alpha: 0.05)
                        : AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: sale.isCancelled
                              ? AppColors.error.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          sale.isCancelled
                              ? Icons.cancel_outlined
                              : Icons.check_circle_outline,
                          color: sale.isCancelled
                              ? AppColors.error
                              : AppColors.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'FELLOW DRINK',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const Text(
                        'Boissons naturelles',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Infos reçu ────────────────────────────────────────
                      _InfoRow(
                        label: 'N° Reçu',
                        value: sale.receiptNumber,
                        bold: true,
                      ),
                      _InfoRow(
                        label: 'Date',
                        value: _dateFmt.format(sale.createdAt.toLocal()),
                      ),
                      if (sale.clientName != null &&
                          sale.clientName!.isNotEmpty)
                        _InfoRow(
                            label: 'Client', value: sale.clientName!),
                      if (sale.clientPhone != null &&
                          sale.clientPhone!.isNotEmpty)
                        _InfoRow(
                            label: 'Téléphone', value: sale.clientPhone!),
                      _InfoRow(
                        label: 'Paiement',
                        value: sale.paymentLabel,
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.divider),
                      ),

                      // ── Lignes de vente ────────────────────────────────────
                      if (sale.items.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Produits commandés',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...sale.items.map((item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product?.name ?? 'Produit',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${_currencyFmt.format(item.unitPrice)} × ${item.quantity}',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _currencyFmt.format(item.subtotal),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: AppColors.divider),
                        ),
                      ],

                      // ── Total ──────────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _currencyFmt.format(sale.totalAmount),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: sale.isCancelled
                                  ? AppColors.error
                                  : AppColors.primary,
                              decoration: sale.isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                  ),
                  child: const Text(
                    'Merci pour votre confiance ! 🙏',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Bouton retour ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/sales'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour aux ventes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}