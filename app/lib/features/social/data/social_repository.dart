import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';
import '../../auth/domain/user_model.dart';

/// Exception personnalisee pour les operations sociales
class SocialException implements Exception {
  final String message;
  final int? code;

  SocialException(this.message, {this.code});

  @override
  String toString() => 'SocialException: $message';
}

/// Modele representant une relation de suivi
class FollowRelation {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  const FollowRelation({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  factory FollowRelation.fromJson(Map<String, dynamic> json) {
    return FollowRelation(
      id: json['\$id'] as String,
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Repository pour la gestion des fonctionnalites sociales
///
/// Gere:
/// - Follow/Unfollow
/// - Liste des followers/following
/// - Recherche d'utilisateurs
/// - Blocage
class SocialRepository {
  final AppwriteService _appwrite;

  /// Collection des relations de suivi
  static const String _followsCollection = 'followers';

  /// Collection des blocages
  static const String _blocksCollection = 'blocks';

  SocialRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Databases get _databases => _appwrite.databases;

  // ===========================================
  // Follow / Unfollow
  // ===========================================

  /// Verifie si un utilisateur suit un autre
  Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        queries: [
          Query.equal('followerId', followerId),
          Query.equal('followingId', followingId),
          Query.limit(1),
        ],
      );

      return result.documents.isNotEmpty;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error checking follow status: ${e.message}');
      }
      return false;
    }
  }

  /// Suit un utilisateur
  Future<void> follow({
    required String followerId,
    required String followingId,
  }) async {
    if (followerId == followingId) {
      throw SocialException('Vous ne pouvez pas vous suivre vous-meme.');
    }

    try {
      // Verifier si deja suivi
      final alreadyFollowing = await isFollowing(
        followerId: followerId,
        followingId: followingId,
      );

      if (alreadyFollowing) {
        throw SocialException('Vous suivez deja cet utilisateur.');
      }

      // Creer la relation de suivi
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        documentId: ID.unique(),
        data: {
          'followerId': followerId,
          'followingId': followingId,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(followerId)),
          Permission.read(Role.user(followingId)),
          Permission.delete(Role.user(followerId)),
        ],
      );

      // TODO: Envoyer une notification au suivi
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors du suivi.',
        code: e.code,
      );
    }
  }

  /// Arrete de suivre un utilisateur
  Future<void> unfollow({
    required String followerId,
    required String followingId,
  }) async {
    try {
      // Trouver la relation de suivi
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        queries: [
          Query.equal('followerId', followerId),
          Query.equal('followingId', followingId),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        throw SocialException('Vous ne suivez pas cet utilisateur.');
      }

      // Supprimer la relation
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        documentId: result.documents.first.$id,
      );
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de l\'arret du suivi.',
        code: e.code,
      );
    }
  }

  /// Bascule l'etat de suivi
  Future<bool> toggleFollow({
    required String followerId,
    required String followingId,
  }) async {
    final following = await isFollowing(
      followerId: followerId,
      followingId: followingId,
    );

    if (following) {
      await unfollow(followerId: followerId, followingId: followingId);
      return false;
    } else {
      await follow(followerId: followerId, followingId: followingId);
      return true;
    }
  }

  // ===========================================
  // Listes de followers / following
  // ===========================================

  /// Recupere la liste des followers d'un utilisateur
  Future<List<UserModel>> getFollowers({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Recuperer les relations de suivi
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        queries: [
          Query.equal('followingId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      // Recuperer les profils des followers
      final followers = <UserModel>[];
      for (final doc in result.documents) {
        final followerId = doc.data['followerId'] as String;
        try {
          final userDoc = await _databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            documentId: followerId,
          );
          followers.add(UserModel.fromJson(userDoc.data));
        } catch (e) {
          // Ignorer les utilisateurs supprimes
        }
      }

      return followers;
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de la recuperation des followers.',
        code: e.code,
      );
    }
  }

  /// Recupere la liste des utilisateurs suivis
  Future<List<UserModel>> getFollowing({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Recuperer les relations de suivi
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
        queries: [
          Query.equal('followerId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      // Recuperer les profils des suivis
      final following = <UserModel>[];
      for (final doc in result.documents) {
        final followingId = doc.data['followingId'] as String;
        try {
          final userDoc = await _databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            documentId: followingId,
          );
          following.add(UserModel.fromJson(userDoc.data));
        } catch (e) {
          // Ignorer les utilisateurs supprimes
        }
      }

      return following;
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de la recuperation des suivis.',
        code: e.code,
      );
    }
  }

  /// Recupere le nombre de followers
  Future<int> getFollowersCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
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
  Future<int> getFollowingCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _followsCollection,
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
  // Recherche d'utilisateurs
  // ===========================================

  /// Recherche des utilisateurs par nom
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 20,
    String? excludeUserId,
  }) async {
    try {
      final queries = <String>[
        Query.search('name', query),
        Query.limit(limit),
      ];

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: queries,
      );

      var users = result.documents
          .map((doc) => UserModel.fromJson(doc.data))
          .toList();

      // Exclure l'utilisateur specifie (generalement soi-meme)
      if (excludeUserId != null) {
        users = users.where((u) => u.id != excludeUserId).toList();
      }

      return users;
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de la recherche.',
        code: e.code,
      );
    }
  }

  /// Recupere les utilisateurs suggeres (basé sur interets communs)
  Future<List<UserModel>> getSuggestedUsers({
    required String userId,
    required List<String> interests,
    int limit = 10,
  }) async {
    try {
      // Recuperer des utilisateurs avec des interets similaires
      final queries = <String>[
        Query.limit(limit * 2), // Marge pour filtrage
        Query.orderDesc('rating'),
      ];

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.usersCollectionId,
        queries: queries,
      );

      var users = result.documents
          .map((doc) => UserModel.fromJson(doc.data))
          .where((u) => u.id != userId)
          .toList();

      // Filtrer ceux deja suivis
      final following = await getFollowing(userId: userId);
      final followingIds = following.map((u) => u.id).toSet();
      users = users.where((u) => !followingIds.contains(u.id)).toList();

      // Trier par nombre d'interets communs
      if (interests.isNotEmpty) {
        users.sort((a, b) {
          final commonA = a.interests.where((i) => interests.contains(i)).length;
          final commonB = b.interests.where((i) => interests.contains(i)).length;
          return commonB.compareTo(commonA);
        });
      }

      return users.take(limit).toList();
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de la recuperation des suggestions.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Blocage
  // ===========================================

  /// Verifie si un utilisateur est bloque
  Future<bool> isBlocked({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _blocksCollection,
        queries: [
          Query.equal('blockerId', blockerId),
          Query.equal('blockedId', blockedId),
          Query.limit(1),
        ],
      );
      return result.documents.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Bloque un utilisateur
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    if (blockerId == blockedId) {
      throw SocialException('Vous ne pouvez pas vous bloquer vous-meme.');
    }

    try {
      // Verifier si deja bloque
      final alreadyBlocked = await isBlocked(
        blockerId: blockerId,
        blockedId: blockedId,
      );

      if (alreadyBlocked) {
        throw SocialException('Cet utilisateur est deja bloque.');
      }

      // Creer le blocage
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _blocksCollection,
        documentId: ID.unique(),
        data: {
          'blockerId': blockerId,
          'blockedId': blockedId,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(blockerId)),
          Permission.delete(Role.user(blockerId)),
        ],
      );

      // Supprimer la relation de suivi si elle existe
      try {
        await unfollow(followerId: blockerId, followingId: blockedId);
      } catch (e) {
        // Pas grave si pas suivi
      }
      try {
        await unfollow(followerId: blockedId, followingId: blockerId);
      } catch (e) {
        // Pas grave si pas suivi
      }
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors du blocage.',
        code: e.code,
      );
    }
  }

  /// Debloque un utilisateur
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _blocksCollection,
        queries: [
          Query.equal('blockerId', blockerId),
          Query.equal('blockedId', blockedId),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        throw SocialException('Cet utilisateur n\'est pas bloque.');
      }

      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _blocksCollection,
        documentId: result.documents.first.$id,
      );
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors du deblocage.',
        code: e.code,
      );
    }
  }

  /// Recupere la liste des utilisateurs bloques
  Future<List<UserModel>> getBlockedUsers({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _blocksCollection,
        queries: [
          Query.equal('blockerId', userId),
          Query.limit(limit),
        ],
      );

      final blockedUsers = <UserModel>[];
      for (final doc in result.documents) {
        final blockedId = doc.data['blockedId'] as String;
        try {
          final userDoc = await _databases.getDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.usersCollectionId,
            documentId: blockedId,
          );
          blockedUsers.add(UserModel.fromJson(userDoc.data));
        } catch (e) {
          // Ignorer les utilisateurs supprimes
        }
      }

      return blockedUsers;
    } on AppwriteException catch (e) {
      throw SocialException(
        e.message ?? 'Erreur lors de la recuperation des utilisateurs bloques.',
        code: e.code,
      );
    }
  }
}
