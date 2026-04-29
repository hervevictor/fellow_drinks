import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Model stats admin ────────────────────────────────────────────────────────

class AdminHomeStats {
  final double caAujourdhui;
  final int ventesAujourdhui;
  final int produitsStockFaible;
  final int livraisonsEnCours;

  const AdminHomeStats({
    required this.caAujourdhui,
    required this.ventesAujourdhui,
    required this.produitsStockFaible,
    required this.livraisonsEnCours,
  });
}

// ── Model activité client ────────────────────────────────────────────────────

class ClientActivity {
  final String id;
  final String receiptNumber;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final String? clientName;

  const ClientActivity({
    required this.id,
    required this.receiptNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.clientName,
  });

  factory ClientActivity.fromMap(Map<String, dynamic> map) => ClientActivity(
        id:            map['id'] as String,
        receiptNumber: map['receipt_number'] as String,
        totalAmount:   (map['total_amount'] as num).toDouble(),
        status:        map['status'] as String? ?? 'completed',
        createdAt:     DateTime.parse(map['created_at'] as String),
        clientName:    map['client_name'] as String?,
      );
}

// ── Provider stats admin ─────────────────────────────────────────────────────

final adminHomeStatsProvider = FutureProvider<AdminHomeStats>((ref) async {
  final client = Supabase.instance.client;
  final today  = DateTime.now();
  final start  = DateTime(today.year, today.month, today.day).toIso8601String();
  final end    = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

  // CA + nb ventes du jour
  final salesData = await client
      .from('sales')
      .select('total_amount, status')
      .eq('status', 'completed')
      .gte('created_at', start)
      .lte('created_at', end);

  final sales      = salesData as List;
  final ca         = sales.fold<double>(0, (sum, s) => sum + (s['total_amount'] as num).toDouble());
  final nbVentes   = sales.length;

  // Produits stock faible (≤ 5)
  final stockData = await client
      .from('products')
      .select('id')
      .eq('is_active', true)
      .lte('stock_quantity', 5);
  final nbStockFaible = (stockData as List).length;

  // Livraisons en cours
  final delivData = await client
      .from('deliveries')
      .select('id')
      .inFilter('status', ['pending', 'in_transit']);
  final nbLivraisons = (delivData as List).length;

  return AdminHomeStats(
    caAujourdhui:        ca,
    ventesAujourdhui:    nbVentes,
    produitsStockFaible: nbStockFaible,
    livraisonsEnCours:   nbLivraisons,
  );
});

// ── Provider dernières ventes (admin) ────────────────────────────────────────

final recentSalesProvider = FutureProvider<List<ClientActivity>>((ref) async {
  final data = await Supabase.instance.client
      .from('sales')
      .select()
      .order('created_at', ascending: false)
      .limit(5);

  return (data as List).map((e) => ClientActivity.fromMap(e)).toList();
});

// ── Provider produits stock faible (admin) ───────────────────────────────────

final lowStockProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client
      .from('products')
      .select('id, name, stock_quantity, image_url')
      .eq('is_active', true)
      .lte('stock_quantity', 5)
      .order('stock_quantity')
      .limit(5);

  return (data as List).cast<Map<String, dynamic>>();
});

// ── Provider historique client ────────────────────────────────────────────────

final clientHistoryProvider = FutureProvider<List<ClientActivity>>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return [];

  final data = await Supabase.instance.client
      .from('sales')
      .select()
      .eq('created_by', session.user.id)
      .order('created_at', ascending: false)
      .limit(10);

  return (data as List).map((e) => ClientActivity.fromMap(e)).toList();
});

// ── Provider stats résumé client ─────────────────────────────────────────────

class ClientStats {
  final int totalCommandes;
  final double totalDepense;
  final int commandesEnCours;

  const ClientStats({
    required this.totalCommandes,
    required this.totalDepense,
    required this.commandesEnCours,
  });
}

final clientStatsProvider = FutureProvider<ClientStats>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return const ClientStats(totalCommandes: 0, totalDepense: 0, commandesEnCours: 0);

  final data = await Supabase.instance.client
      .from('sales')
      .select('total_amount, status')
      .eq('created_by', session.user.id);

  final list        = data as List;
  final total       = list.length;
  final depense     = list.fold<double>(0, (s, e) => s + (e['total_amount'] as num).toDouble());
  final enCours     = list.where((e) => e['status'] == 'pending_payment').length;

  return ClientStats(
    totalCommandes:   total,
    totalDepense:     depense,
    commandesEnCours: enCours,
  );
});

