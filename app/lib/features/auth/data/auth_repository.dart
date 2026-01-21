import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';
import '../domain/user_model.dart';

/// Exception personnalisée pour l'authentification
class AuthException implements Exception {
  final String message;
  final int? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException: $message';
}

/// Repository pour la gestion de l'authentification
///
/// Gère toutes les opérations liées à l'authentification:
/// - Inscription
/// - Connexion (email, OAuth)
/// - Déconnexion
/// - Gestion de session
/// - Profil utilisateur
class AuthRepository {
  final AppwriteService _appwrite;

  AuthRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Account get _account => _appwrite.account;
  Databases get _databases => _appwrite.databases;

  // ============================================
  // Gestion de Session
  // ============================================

  /// Vérifie si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Récupère l'utilisateur actuellement connecté
  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('getCurrentUser error: ${e.message}');
      }
      return null;
    }
  }

  /// Récupère la session actuelle
  Future<models.Session?> getCurrentSession() async {
    try {
      return await _account.getSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('getCurrentSession error: ${e.message}');
      }
      return null;
    }
  }

  // ============================================
  // Inscription
  // ============================================

  /// Crée un nouveau compte utilisateur
  Future<models.User> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Créer le compte Appwrite
      final user = await _account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Connecter automatiquement après inscription
      await signInWithEmail(email: email, password: password);

      // Créer le profil utilisateur dans la base de données
      await _createUserProfile(user);

      return user;
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Crée le profil utilisateur dans la collection users
  Future<void> _createUserProfile(models.User user) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: user.$id,
        data: {
          'userId': user.$id,
          'email': user.email,
          'name': user.name,
          'avatar': null,
          'bio': null,
          'points': 0,
          'level': 1,
          'followersCount': 0,
          'followingCount': 0,
          'locationLat': null,
          'locationLng': null,
          'notificationRadius': 10.0,
          'fcmToken': null,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: ${e.message}');
      }
      // Ne pas bloquer l'inscription si le profil échoue
    }
  }

  // ============================================
  // Connexion
  // ============================================

  /// Connexion avec email et mot de passe
  Future<models.Session> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _account.createEmailPasswordSession(
        email: email,
        password: password,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Connexion avec OAuth (Google, Apple, etc.)
  Future<void> signInWithOAuth({
    required OAuthProvider provider,
    String? successUrl,
    String? failureUrl,
  }) async {
    try {
      await _account.createOAuth2Session(
        provider: provider,
        success: successUrl,
        failure: failureUrl,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Connexion anonyme (pour les invités)
  Future<models.Session> signInAnonymously() async {
    try {
      return await _account.createAnonymousSession();
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  // ============================================
  // Déconnexion
  // ============================================

  /// Déconnexion de la session actuelle
  Future<void> signOut() async {
    try {
      await _account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Déconnexion de toutes les sessions
  Future<void> signOutAll() async {
    try {
      await _account.deleteSessions();
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  // ============================================
  // Gestion du mot de passe
  // ============================================

  /// Envoie un email de récupération de mot de passe
  Future<void> sendPasswordRecovery({required String email}) async {
    try {
      await _account.createRecovery(
        email: email,
        url: 'https://fug-app.com/reset-password', // À configurer
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Confirme la récupération de mot de passe
  Future<void> confirmPasswordRecovery({
    required String userId,
    required String secret,
    required String password,
  }) async {
    try {
      await _account.updateRecovery(
        userId: userId,
        secret: secret,
        password: password,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Change le mot de passe (utilisateur connecté)
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  // ============================================
  // Vérification Email
  // ============================================

  /// Envoie un email de vérification
  Future<void> sendEmailVerification() async {
    try {
      await _account.createVerification(
        url: 'https://fug-app.com/verify-email', // À configurer
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Confirme la vérification de l'email
  Future<void> confirmEmailVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      await _account.updateVerification(
        userId: userId,
        secret: secret,
      );
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  // ============================================
  // Profil Utilisateur
  // ============================================

  /// Récupère le profil utilisateur depuis la base de données
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
      );
      return UserModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('getUserProfile error: ${e.message}');
      }
      return null;
    }
  }

  /// Met à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? avatarUrl,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? interests,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (location != null) data['location'] = location;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (interests != null) data['interests'] = interests;

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: data,
      );

      // Mettre à jour aussi le nom dans Account si modifié
      if (name != null) {
        await _account.updateName(name: name);
      }
    } on AppwriteException catch (e) {
      throw AuthException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  // ============================================
  // Helpers
  // ============================================

  /// Convertit les erreurs Appwrite en messages lisibles
  String _getReadableErrorMessage(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Email ou mot de passe incorrect.';
      case 409:
        return 'Un compte existe déjà avec cet email.';
      case 429:
        return 'Trop de tentatives. Veuillez patienter.';
      case 400:
        if (e.message?.contains('password') ?? false) {
          return 'Le mot de passe doit contenir au moins 8 caractères.';
        }
        if (e.message?.contains('email') ?? false) {
          return 'Adresse email invalide.';
        }
        return e.message ?? 'Données invalides.';
      default:
        return e.message ?? 'Une erreur est survenue.';
    }
  }
}
