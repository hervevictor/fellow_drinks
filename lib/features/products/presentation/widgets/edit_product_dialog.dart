import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';

class EditProductDialog extends ConsumerStatefulWidget {
  final ProductModel product;
  const EditProductDialog({super.key, required this.product});

  @override
  ConsumerState<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends ConsumerState<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _nameCtrl  = TextEditingController(text: widget.product.name);
  late final _priceCtrl = TextEditingController(
      text: widget.product.price.toStringAsFixed(0));
  late final _stockCtrl = TextEditingController(
      text: widget.product.stockQuantity.toString());
  late final _descCtrl  = TextEditingController(
      text: widget.product.description ?? '');

  late String? _selectedCategoryId = widget.product.categoryId;
  File?   _imageFile;      // nouvelle image choisie depuis la galerie
  bool    _uploading = false;
  bool    _loading   = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      String? imageUrl = widget.product.imageUrl;

      // Upload la nouvelle image si l'admin en a choisi une
      if (_imageFile != null) {
        setState(() => _uploading = true);
        imageUrl = await ref
            .read(productRepositoryProvider)
            .uploadProductImage(_imageFile!);
        setState(() => _uploading = false);
      }

      await ref.read(productNotifierProvider.notifier).updateProduct(
        id: widget.product.id,
        updates: {
          'name':           _nameCtrl.text.trim(),
          'category_id':    _selectedCategoryId,
          'price':          double.parse(_priceCtrl.text),
          'stock_quantity': int.parse(_stockCtrl.text),
          'description':    _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          'image_url':      imageUrl,
        },
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e',
                style: GoogleFonts.poppins(fontSize: 13)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; _uploading = false; });
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Supprimer "${widget.product.name}" ?',
            style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref
          .read(productNotifierProvider.notifier)
          .deleteProduct(widget.product.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Image à afficher : nouvelle sélection > URL existante > placeholder
    final hasNewImage     = _imageFile != null;
    final hasExistingUrl  = widget.product.imageUrl != null &&
        widget.product.imageUrl!.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── En-tête ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Modifier le produit',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  Row(children: [
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.error),
                      onPressed: _loading ? null : _confirmDelete,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 12),

              // ── Zone image cliquable ──────────────────────────────────
              GestureDetector(
                onTap: _loading ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasNewImage
                          ? AppColors.primary
                          : AppColors.divider,
                      width: hasNewImage ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      if (hasNewImage)
                        Image.file(_imageFile!, fit: BoxFit.cover)
                      else if (hasExistingUrl)
                        Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(),
                        )
                      else
                        _placeholder(),

                      // Overlay bouton changer
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_camera_outlined,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                hasNewImage || hasExistingUrl
                                    ? 'Changer la photo'
                                    : 'Ajouter une photo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Nom ───────────────────────────────────────────────────
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  prefixIcon: Icon(Icons.local_drink_outlined),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),

              // ── Catégorie ─────────────────────────────────────────────
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: cats
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name,
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedCategoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 12),

              // ── Prix + Stock ──────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prix (FCFA)',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? 'Invalide' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock',
                      prefixIcon: Icon(Icons.inventory_outlined),
                    ),
                    validator: (v) =>
                        int.tryParse(v ?? '') == null ? 'Invalide' : null,
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Description / Vertus ──────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Vertus & description (une par ligne)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // ── Bouton enregistrer ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _uploading
                                  ? 'Upload image...'
                                  : 'Enregistrement...',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ],
                        )
                      : Text('Enregistrer les modifications',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.accent,
        child: const Center(
          child: Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.primary, size: 40),
        ),
      );
}
