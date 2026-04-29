import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../products/data/models/product_model.dart';

/// Produits visibles publiquement (landing page — sans auth requise).
final publicProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final data = await Supabase.instance.client
      .from('products')
      .select('*, categories(*)')
      .eq('is_active', true)
      .order('name');

  return (data as List)
      .map((e) => ProductModel.fromMap(e as Map<String, dynamic>))
      .toList();
});

/// Un seul produit par id (page détail publique).
final publicProductDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  final data = await Supabase.instance.client
      .from('products')
      .select('*, categories(*)')
      .eq('id', id)
      .eq('is_active', true)
      .maybeSingle();

  if (data == null) return null;
  return ProductModel.fromMap(data);
});
