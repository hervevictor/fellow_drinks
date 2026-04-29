import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sale_model.dart';

class SaleRepository {
  final _client = Supabase.instance.client;

  static const _saleSelect =
      '*, sale_items(*, products(*, categories(*)))';

  Future<List<SaleModel>> getSales() async {
    final data = await _client
        .from('sales')
        .select(_saleSelect)
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((e) => SaleModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<SaleModel> getSaleById(String id) async {
    final data = await _client
        .from('sales')
        .select(_saleSelect)
        .eq('id', id)
        .single();
    return SaleModel.fromMap(data);
  }

  Future<SaleModel> createSale({
    required List<CartItem> items,
    String? clientName,
    String? clientPhone,
    String? paymentMethod,
    String? paymentReference,
    bool pendingPayment = false,
  }) async {
    final userId    = _client.auth.currentUser?.id;
    final total     = items.fold<double>(0, (sum, i) => sum + i.subtotal);
    final receiptNo = 'FD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    // Insert sale header
    final row = <String, dynamic>{
      'receipt_number': receiptNo,
      'client_name':    clientName,
      'client_phone':   clientPhone,
      'total_amount':   total,
      'status':         pendingPayment ? 'pending_payment' : 'completed',
      'payment_method': paymentMethod ?? 'cash',
      'created_by':     userId,
      'created_at':     DateTime.now().toIso8601String(),
    };
    if (paymentReference != null) row['payment_reference'] = paymentReference;

    final saleData = await _client.from('sales').insert(row).select().single();

    final saleId = saleData['id'] as String;

    // Insert sale items
    final saleItems = items.map((i) => {
      'sale_id':    saleId,
      'product_id': i.product.id,
      'quantity':   i.quantity,
      'unit_price': i.product.price,
      'subtotal':   i.subtotal,
    }).toList();

    await _client.from('sale_items').insert(saleItems);

    // Decrement stock for each item
    for (final item in items) {
      final newStock = (item.product.stockQuantity - item.quantity)
          .clamp(0, item.product.stockQuantity);
      await _client.from('products').update({
        'stock_quantity': newStock,
        'updated_at':     DateTime.now().toIso8601String(),
      }).eq('id', item.product.id);
    }

    return getSaleById(saleId);
  }

  Future<void> cancelSale({
    required String saleId,
    String? reason,
  }) async {
    await _client.from('sales').update({
      'status':           'cancelled',
      'cancelled_at':     DateTime.now().toIso8601String(),
      'cancelled_reason': reason,
    }).eq('id', saleId);
  }

  Future<SaleModel> confirmPayment({
    required String saleId,
    String? paymentReference,
  }) async {
    final updates = <String, dynamic>{'status': 'completed'};
    if (paymentReference != null) updates['payment_reference'] = paymentReference;
    final data = await _client
        .from('sales')
        .update(updates)
        .eq('id', saleId)
        .select(_saleSelect)
        .single();
    return SaleModel.fromMap(data);
  }

  Future<SaleModel> updatePaymentReference({
    required String saleId,
    required String reference,
  }) async {
    final data = await _client
        .from('sales')
        .update({'payment_reference': reference})
        .eq('id', saleId)
        .select(_saleSelect)
        .single();
    return SaleModel.fromMap(data);
  }
}
