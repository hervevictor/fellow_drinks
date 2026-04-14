import 'package:supabase_flutter/supabase_flutter.dart';
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
    if (response.user == null) throw Exception('Connexion échouée');
    return _fetchProfile(response.user!.id);
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'client',
    String? phone,           // ← ajouté
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user == null) throw Exception('Inscription échouée');

    await _client.from('profiles').insert({
      'id':         response.user!.id,
      'email':      email,
      'name':       name,
      'role':       role,
      'phone':      phone,   // ← ajouté
      'created_at': DateTime.now().toIso8601String(),
    });

    return _fetchProfile(response.user!.id);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _fetchProfile(user.id);
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
    return UserModel.fromMap(data);
  }

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}