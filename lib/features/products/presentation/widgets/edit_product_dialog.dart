import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const EditProductDialog({super.key, required this.product});

  @override
  ConsumerState<EditProductDialog> createState() =>
      _EditProductDialogState();
}

class _EditProductDialogState
    extends ConsumerState<EditProductDialog> {
  final _formKey   = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(
      text: widget.product.name);
  late final _priceCtrl = TextEditingController(
      text: widget.product.price.toStringAsFixed(0));
  late final _stockCtrl = TextEditingController(
      text: widget.product.stockQuantity.toString());
  late final _descCtrl  = TextEditingController(
      text: widget.product.description ?? '');
  late String? _selectedCategoryId = widget.product.categoryId;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(productNotifierProvider.notifier)
          .updateProduct(
            id: widget.product.id,
            updates: {
              'name':           _nameCtrl.text.trim(),
              'category_id':    _selectedCategoryId,
              'price':          double.parse(_priceCtrl.text),
              'stock_quantity': int.parse(_stockCtrl.text),
              'description':    _descCtrl.text.trim().isEmpty
                  ? null : _descCtrl.text.trim(),
            },
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600)),
        content: Text(
            'Supprimer "${widget.product.name}" ?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.poppins(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(productNotifierProvider.notifier)
          .deleteProduct(widget.product.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text('Modifier produit',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: _delete,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  prefixIcon: Icon(Icons.local_drink_outlined),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),

              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: cats.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name,
                        style: GoogleFonts.poppins(
                            fontSize: 14)),
                  )).toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix (F)',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null
                            ? 'Invalide' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      prefixIcon:
                          Icon(Icons.inventory_outlined),
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null
                            ? 'Invalide' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                      : Text('Enregistrer',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

