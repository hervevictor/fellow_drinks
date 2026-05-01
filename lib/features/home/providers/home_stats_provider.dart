import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Flux temps réel du nb de commandes en attente (pour la cloche admin)
final pendingOrdersStreamProvider = StreamProvider<int>((ref) {
  return Supabase.instance.client
      .from('sales')
      .stream(primaryKey: ['id'])
      .map((data) => data.where((e) => e['status'] == 'pending_payment').length);
});

// ── Model stats admin ────────────────────────────────────────────────────────

class AdminHomeStats {
  final double caAujourdhui;      // CA mois en cours (completed)
  final int ventesAujourdhui;     // commandes en attente (pending_payment)
  final int produitsStockFaible;
  final int livraisonsEnCours;    // ventes non-annulées ce mois

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
  final client     = Supabase.instance.client;
  final now        = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

  // CA ce mois = completed uniquement
  final caData = await client
      .from('sales')
      .select('total_amount')
      .eq('status', 'completed')
      .gte('created_at', monthStart);

  final ca = (caData as List)
      .fold<double>(0, (sum, s) => sum + (s['total_amount'] as num).toDouble());

  // Commandes en attente = TOUTES les pending_payment (peu importe la date)
  final pendingData = await client
      .from('sales')
      .select('id')
      .eq('status', 'pending_payment');

  final nbVentes = (pendingData as List).length;

  // Produits stock faible (≤ 5)
  final stockData = await client
      .from('products')
      .select('id')
      .eq('is_active', true)
      .lte('stock_quantity', 5);
  final nbStockFaible = (stockData as List).length;

  // Ventes ce mois (non-annulées)
  final monthSalesData = await client
      .from('sales')
      .select('id')
      .neq('status', 'cancelled')
      .gte('created_at', monthStart);

  final nbVentesMois = (monthSalesData as List).length;

  return AdminHomeStats(
    caAujourdhui:        ca,
    ventesAujourdhui:    nbVentes,
    produitsStockFaible: nbStockFaible,
    livraisonsEnCours:   nbVentesMois,
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

