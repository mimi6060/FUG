import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/appwrite_service.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/user_model.dart';

/// Provider pour le repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider pour l'etat d'authentification
///
/// Gere la session utilisateur et fournit des methodes
/// pour se connecter, s'inscrire et se deconnecter.
final authStateProvider =
    AsyncNotifierProvider<AuthStateNotifier, models.User?>(() {
  return AuthStateNotifier();
});

/// Notifier pour l'etat d'authentification
class AuthStateNotifier extends AsyncNotifier<models.User?> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  Future<models.User?> build() async {
    // Verifier si l'utilisateur est deja connecte
    return _repository.getCurrentUser();
  }

  /// Connexion avec email et mot de passe
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      return _repository.getCurrentUser();
    });
  }

  /// Inscription avec email et mot de passe
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.signUp(
        email: email,
        password: password,
        name: name,
      );
      return _repository.getCurrentUser();
    });
  }

  /// Connexion avec OAuth
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.signInWithOAuth(provider: provider);
      return _repository.getCurrentUser();
    });
  }

  /// Deconnexion
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.signOut();
      return null;
    });
  }

  /// Rafraichir l'etat d'authentification
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getCurrentUser());
  }
}

/// Provider pour l'utilisateur actuellement connecte
///
/// Retourne l'utilisateur Appwrite si connecte, null sinon.
final currentUserProvider = FutureProvider<models.User?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

/// Provider pour le profil complet de l'utilisateur connecte
///
/// Recupere le UserModel depuis la base de donnees.
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final repository = ref.read(authRepositoryProvider);
  return repository.getUserProfile(user.$id);
});

/// Provider pour verifier si l'utilisateur est connecte
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

/// Provider pour les erreurs d'authentification
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Provider pour l'etat de chargement de l'authentification
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isLoading;
});
