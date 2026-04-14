import 'package:equatable/equatable.dart';
import 'category_model.dart';

class ProductModel extends Equatable {
  final String id;
  final String name;
  final String? categoryId;
  final CategoryModel? category;
  final double price;
  final int stockQuantity;
  final String? imageUrl;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.category,
    required this.price,
    required this.stockQuantity,
    this.imageUrl,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id:            map['id'] as String,
        name:          map['name'] as String,
        categoryId:    map['category_id'] as String?,
        category:      map['categories'] != null
            ? CategoryModel.fromMap(
                map['categories'] as Map<String, dynamic>)
            : null,
        price:         (map['price'] as num).toDouble(),
        stockQuantity: map['stock_quantity'] as int? ?? 0,
        imageUrl:      map['image_url'] as String?,
        description:   map['description'] as String?,
        isActive:      map['is_active'] as bool? ?? true,
        createdAt:     DateTime.parse(map['created_at'] as String),
        updatedAt:     DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'name':           name,
        'category_id':    categoryId,
        'price':          price,
        'stock_quantity': stockQuantity,
        'image_url':      imageUrl,
        'description':    description,
        'is_active':      isActive,
      };

  ProductModel copyWith({
    String? name,
    String? categoryId,
    double? price,
    int? stockQuantity,
    String? imageUrl,
    String? description,
    bool? isActive,
  }) =>
      ProductModel(
        id:            id,
        name:          name ?? this.name,
        categoryId:    categoryId ?? this.categoryId,
        category:      category,
        price:         price ?? this.price,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        imageUrl:      imageUrl ?? this.imageUrl,
        description:   description ?? this.description,
        isActive:      isActive ?? this.isActive,
        createdAt:     createdAt,
        updatedAt:     DateTime.now(),
      );

  bool get isLowStock => stockQuantity <= 5;
  bool get isOutOfStock => stockQuantity == 0;

  @override
  List<Object?> get props =>
      [id, name, categoryId, price, stockQuantity, isActive];
}

