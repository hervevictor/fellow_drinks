import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final String saleId;
  const ReceiptPage({super.key, required this.saleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reçu #$saleId')),
      body: const Center(child: Text('Reçu — étape 7')),
    );
  }
}

