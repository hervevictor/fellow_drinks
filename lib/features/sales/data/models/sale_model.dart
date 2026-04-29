import 'package:equatable/equatable.dart';
import '../../../products/data/models/product_model.dart';

// ── SaleItem (ligne de vente) ────────────────────────────────────────────────

class SaleItemModel extends Equatable {
  final String id;
  final String saleId;
  final String productId;
  final ProductModel? product;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItemModel({
    required this.id,
    required this.saleId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemModel.fromMap(Map<String, dynamic> map) => SaleItemModel(
        id:        map['id'] as String,
        saleId:    map['sale_id'] as String,
        productId: map['product_id'] as String,
        product:   map['products'] != null
            ? ProductModel.fromMap(map['products'] as Map<String, dynamic>)
            : null,
        quantity:  map['quantity'] as int,
        unitPrice: (map['unit_price'] as num).toDouble(),
        subtotal:  (map['subtotal'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [id, saleId, productId, quantity];
}

// ── SaleModel (entête vente) ─────────────────────────────────────────────────

class SaleModel extends Equatable {
  final String id;
  final String receiptNumber;
  final String? clientName;
  final String? clientPhone;
  final double totalAmount;
  final String status; // completed | cancelled | pending
  final String? paymentMethod;   // cash | mobile_money | card
  final String? paymentReference; // transaction ref (mobile money / card)
  final DateTime? cancelledAt;
  final String? cancelledReason;
  final String? createdBy;
  final DateTime createdAt;
  final List<SaleItemModel> items;

  const SaleModel({
    required this.id,
    required this.receiptNumber,
    this.clientName,
    this.clientPhone,
    required this.totalAmount,
    required this.status,
    this.paymentMethod,
    this.paymentReference,
    this.cancelledAt,
    this.cancelledReason,
    this.createdBy,
    required this.createdAt,
    this.items = const [],
  });

  factory SaleModel.fromMap(Map<String, dynamic> map) => SaleModel(
        id:               map['id'] as String,
        receiptNumber:    map['receipt_number'] as String,
        clientName:       map['client_name'] as String?,
        clientPhone:      map['client_phone'] as String?,
        totalAmount:      (map['total_amount'] as num).toDouble(),
        status:           map['status'] as String? ?? 'completed',
        paymentMethod:    map['payment_method'] as String?,
        paymentReference: map['payment_reference'] as String?,
        cancelledAt:      map['cancelled_at'] != null
            ? DateTime.parse(map['cancelled_at'] as String)
            : null,
        cancelledReason:  map['cancelled_reason'] as String?,
        createdBy:        map['created_by'] as String?,
        createdAt:        DateTime.parse(map['created_at'] as String),
        items: map['sale_items'] != null
            ? (map['sale_items'] as List)
                .map((e) => SaleItemModel.fromMap(e as Map<String, dynamic>))
                .toList()
            : [],
      );

  // QR data encoded in this sale
  String get qrData =>
      'FD:$receiptNumber:$id:${paymentMethod ?? 'cash'}';

  String get paymentLabel {
    return switch (paymentMethod) {
      'mobile_money' => 'Mobile Money',
      'card'         => 'Carte bancaire',
      _              => 'Espèces',
    };
  }

  bool get isCompleted       => status == 'completed';
  bool get isCancelled       => status == 'cancelled';
  bool get isPendingPayment  => status == 'pending_payment';

  @override
  List<Object?> get props => [id, receiptNumber, status, totalAmount];
}

// ── CartItem (panier local, pas en DB) ───────────────────────────────────────

class CartItem extends Equatable {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}


