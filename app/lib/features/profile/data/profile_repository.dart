import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';
import '../../auth/domain/user_model.dart';
import '../domain/profile_model.dart';

/// Exception personnalisee pour les operations de profil
class ProfileException implements Exception {
  final String message;
  final int? code;

  ProfileException(this.message, {this.code});

  @override
  String toString() => 'ProfileException: $message';
}

/// Repository pour la gestion des profils utilisateur
///
/// Gere toutes les operations liees aux profils:
/// - Recuperation du profil
/// - Mise a jour du profil
/// - Upload d'avatar
/// - Statistiques
class ProfileRepository {
  final AppwriteService _appwrite;

  ProfileRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Databases get _databases => _appwrite.databases;
  Storage get _storage => _appwrite.storage;

  // ===========================================
  // Recuperation de profil
  // ===========================================

  /// Recupere le profil d'un utilisateur par son ID
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      // Recuperer le document utilisateur
      final userDoc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
      );

      final user = UserModel.fromJson(userDoc.data);

      // Recuperer les stats de followers
      final followersCount = await _getFollowersCount(userId);
      final followingCount = await _getFollowingCount(userId);

      return ProfileModel(
        user: user,
        followersCount: followersCount,
        followingCount: followingCount,
        totalEventsCreated: user.eventsCreated,
        totalEventsAttended: user.eventsAttended,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw ProfileException(
        e.message ?? 'Erreur lors de la recuperation du profil.',
        code: e.code,
      );
    }
  }

  /// Recupere le profil de l'utilisateur connecte
  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final account = await _appwrite.account.get();
      return getProfile(account.$id);
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Utilisateur non connecte.',
        code: e.code,
      );
    }
  }

  /// Recupere le nombre de followers
  Future<int> _getFollowersCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'follows',
        queries: [
          Query.equal('followingId', userId),
          Query.limit(1),
        ],
      );
      return result.total;
    } catch (e) {
      return 0;
    }
  }

  /// Recupere le nombre de personnes suivies
  Future<int> _getFollowingCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'follows',
        queries: [
          Query.equal('followerId', userId),
          Query.limit(1),
        ],
      );
      return result.total;
    } catch (e) {
      return 0;
    }
  }

  // ===========================================
  // Mise a jour du profil
  // ===========================================

  /// Met a jour le profil utilisateur
  Future<ProfileModel> updateProfile({
    required String userId,
    String? name,
    String? bio,
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

      // Mettre a jour le nom dans Account si modifie
      if (name != null) {
        await _appwrite.account.updateName(name: name);
      }

      // Recuperer le profil mis a jour
      final profile = await getProfile(userId);
      if (profile == null) {
        throw ProfileException('Profil non trouve apres mise a jour.');
      }
      return profile;
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de la mise a jour du profil.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Gestion de l'avatar
  // ===========================================

  /// Upload un nouvel avatar
  ///
  /// Retourne l'URL de l'avatar uploadee
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Generer un ID unique pour le fichier
      final fileId = ID.unique();

      // Upload le fichier
      await _storage.createFile(
        bucketId: AppwriteConfig.avatarsBucketId,
        fileId: fileId,
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: 'avatar_$userId.jpg',
        ),
      );

      // Construire l'URL de l'avatar
      final avatarUrl = _appwrite.getFilePreviewUrl(
        bucketId: AppwriteConfig.avatarsBucketId,
        fileId: fileId,
        width: 400,
        height: 400,
      );

      // Mettre a jour le profil avec la nouvelle URL
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'avatarUrl': avatarUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return avatarUrl;
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de l\'upload de l\'avatar.',
        code: e.code,
      );
    }
  }

  /// Upload un avatar depuis des bytes (pour le web)
  Future<String> uploadAvatarFromBytes({
    required String userId,
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final fileId = ID.unique();

      await _storage.createFile(
        bucketId: AppwriteConfig.avatarsBucketId,
        fileId: fileId,
        file: InputFile.fromBytes(
          bytes: bytes,
          filename: filename,
        ),
      );

      final avatarUrl = _appwrite.getFilePreviewUrl(
        bucketId: AppwriteConfig.avatarsBucketId,
        fileId: fileId,
        width: 400,
        height: 400,
      );

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'avatarUrl': avatarUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return avatarUrl;
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de l\'upload de l\'avatar.',
        code: e.code,
      );
    }
  }

  /// Supprime l'avatar actuel
  Future<void> deleteAvatar(String userId) async {
    try {
      // Recuperer l'URL actuelle pour extraire le fileId
      final profile = await getProfile(userId);
      if (profile?.avatarUrl == null) return;

      // Extraire le fileId de l'URL
      final uri = Uri.parse(profile!.avatarUrl!);
      final pathSegments = uri.pathSegments;
      final fileIndex = pathSegments.indexOf('files');
      if (fileIndex != -1 && fileIndex + 1 < pathSegments.length) {
        final fileId = pathSegments[fileIndex + 1];

        // Supprimer le fichier
        await _storage.deleteFile(
          bucketId: AppwriteConfig.avatarsBucketId,
          fileId: fileId,
        );
      }

      // Mettre a jour le profil
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        documentId: userId,
        data: {
          'avatarUrl': null,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de la suppression de l\'avatar.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Recherche d'utilisateurs
  // ===========================================

  /// Recherche des utilisateurs par nom
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.search('name', query),
          Query.limit(limit),
        ],
      );

      return result.documents
          .map((doc) => UserModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de la recherche.',
        code: e.code,
      );
    }
  }

  /// Liste les utilisateurs recemment actifs
  Future<List<UserModel>> getRecentUsers({int limit = 20}) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: [
          Query.orderDesc('updatedAt'),
          Query.limit(limit),
        ],
      );

      return result.documents
          .map((doc) => UserModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw ProfileException(
        e.message ?? 'Erreur lors de la recuperation des utilisateurs.',
        code: e.code,
      );
    }
  }
}
