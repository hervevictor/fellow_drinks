import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Connexion échouée');

    // Essayer de charger le profil, créer si absent
    final profile = await _fetchOrCreateProfile(user);
    if (profile == null) throw Exception('Profil introuvable');
    return profile;
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'client',
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) throw Exception('Inscription échouée');

    // Upsert pour éviter le conflit si le trigger a déjà créé le profil
    await _client.from('profiles').upsert({
      'id':         user.id,
      'email':      email,
      'name':       name,
      'role':       role,
      'phone':      phone,
      'created_at': DateTime.now().toIso8601String(),
    });

    return await _fetchProfile(user.id);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id)
          .timeout(const Duration(seconds: 8));
    } on Exception {
      return await _fetchOrCreateProfile(user);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Tente de lire le profil ; si absent, le crée depuis les metadata auth.
  Future<UserModel?> _fetchOrCreateProfile(User user) async {
    try {
      return await _fetchProfile(user.id)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    // Profil absent ou timeout → upsert minimal
    try {
      final metadata = user.userMetadata ?? {};
      await _client.from('profiles').upsert({
        'id':         user.id,
        'email':      user.email ?? '',
        'name':       metadata['name']      as String? ??
                      metadata['full_name'] as String?,
        'role':       'client',
        'created_at': DateTime.now().toIso8601String(),
      });
      return await _fetchProfile(user.id)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    final user = UserModel.fromMap(data);
    return _enforceAdminRole(user);
  }

  // Si l'email est dans la liste adminEmails, force role='admin'
  // et met à jour Supabase si nécessaire.
  Future<UserModel> _enforceAdminRole(UserModel user) async {
    final shouldBeAdmin =
        AppConstants.adminEmails.contains(user.email.toLowerCase().trim());

    if (shouldBeAdmin && !user.isAdmin) {
      // Met à jour la DB pour que les autres appareils voient le bon rôle
      await _client
          .from('profiles')
          .update({'role': 'admin'})
          .eq('id', user.id);
      return user.copyWith(role: 'admin');
    }
    return user;
  }

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
