import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user:   user   ?? this.user,
        error:  error,
      );

  bool get isAdmin => user?.isAdmin ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.getCurrentUser()
          .timeout(const Duration(seconds: 15));
      state = user != null
          ? state.copyWith(status: AuthStatus.authenticated, user: user)
          : state.copyWith(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Timeout ou erreur réseau — considéré non connecté
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = state.copyWith(
          status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: _friendlyError(e.message));
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: 'Erreur de connexion');
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'client',
    String? phone,           // ← ajouté
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repo.signUp(
        email:    email,
        password: password,
        name:     name,
        role:     role,
        phone:    phone,     // ← ajouté
      );
      state = state.copyWith(
          status: AuthStatus.authenticated, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: _friendlyError(e.message));
    } catch (e) {
      state = state.copyWith(
          status: AuthStatus.error, error: 'Erreur d\'inscription');
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateProfile(UserModel updated) {
    state = state.copyWith(user: updated);
  }

  String _friendlyError(String msg) {
    if (msg.contains('Invalid login')) return 'Email ou mot de passe incorrect';
    if (msg.contains('already registered')) return 'Email déjà utilisé';
    if (msg.contains('network')) return 'Pas de connexion internet';
    return msg;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

typedef UserProfile = UserModel;

final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authProvider);
  return authState.user;
});

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);

final isAdminProvider = Provider<bool>(
  (ref) => ref.watch(authProvider).isAdmin,
);