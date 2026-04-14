import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

class ProductRepository {
  final _client = Supabase.instance.client;

  // ── Catégories ──────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    final data = await _client
        .from('categories')
        .select()
        .order('name');
    return (data as List)
        .map((e) => CategoryModel.fromMap(e))
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    String? color,
    String? icon,
  }) async {
    final data = await _client.from('categories').insert({
      'name':  name,
      'color': color,
      'icon':  icon,
    }).select().single();
    return CategoryModel.fromMap(data);
  }

  // ── Produits ────────────────────────────────────────────────────────

  Future<List<ProductModel>> getProducts({
    String? categoryId,
    bool activeOnly = true,
  }) async {
    var query = _client
        .from('products')
        .select('*, categories(*)');

    if (activeOnly) {
      query = query.eq('is_active', true);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    final data = await query.order('name');
    return (data as List)
        .map((e) => ProductModel.fromMap(e))
        .toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final data = await _client
        .from('products')
        .select('*, categories(*)')
        .eq('id', id)
        .single();
    return ProductModel.fromMap(data);
  }

  Future<ProductModel> createProduct({
    required String name,
    String? categoryId,
    required double price,
    required int stockQuantity,
    String? imageUrl,
    String? description,
  }) async {
    final data = await _client.from('products').insert({
      'name':           name,
      'category_id':    categoryId,
      'price':          price,
      'stock_quantity': stockQuantity,
      'image_url':      imageUrl,
      'description':    description,
      'is_active':      true,
      'updated_at':     DateTime.now().toIso8601String(),
    }).select('*, categories(*)').single();
    return ProductModel.fromMap(data);
  }

  Future<ProductModel> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    final data = await _client
        .from('products')
        .update(updates)
        .eq('id', id)
        .select('*, categories(*)')
        .single();
    return ProductModel.fromMap(data);
  }

  Future<void> deleteProduct(String id) async {
    await _client
        .from('products')
        .update({'is_active': false})
        .eq('id', id);
  }

  Future<void> updateStock({
    required String productId,
    required int quantity,
  }) async {
    await _client.from('products').update({
      'stock_quantity': quantity,
      'updated_at':     DateTime.now().toIso8601String(),
    }).eq('id', productId);
  }
}

