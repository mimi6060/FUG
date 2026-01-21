import 'package:appwrite/appwrite.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';
import '../../../core/providers/auth_provider.dart';

/// Modele representant une demande de suppression de compte
///
/// Contient les informations sur la demande de suppression
/// incluant la date de demande et la date prevue de suppression.
class AccountDeletionRequest extends Equatable {
  /// ID unique de la demande
  final String id;

  /// ID de l'utilisateur concerné
  final String userId;

  /// Date de la demande de suppression
  final DateTime requestedAt;

  /// Date prevue de suppression effective (30 jours apres la demande)
  final DateTime scheduledDeletionAt;

  /// Statut de la demande: pending, cancelled, completed
  final String status;

  /// Motif d'annulation (si applicable)
  final String? cancellationReason;

  const AccountDeletionRequest({
    required this.id,
    required this.userId,
    required this.requestedAt,
    required this.scheduledDeletionAt,
    required this.status,
    this.cancellationReason,
  });

  /// Cree une AccountDeletionRequest depuis un document JSON
  factory AccountDeletionRequest.fromJson(Map<String, dynamic> json) {
    return AccountDeletionRequest(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      scheduledDeletionAt: DateTime.parse(json['scheduledDeletionAt'] as String),
      status: json['status'] as String,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }

  /// Convertit en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'requestedAt': requestedAt.toIso8601String(),
      'scheduledDeletionAt': scheduledDeletionAt.toIso8601String(),
      'status': status,
      'cancellationReason': cancellationReason,
    };
  }

  /// Verifie si la demande peut encore etre annulee
  bool get canBeCancelled =>
      status == 'pending' && DateTime.now().isBefore(scheduledDeletionAt);

  /// Nombre de jours restants avant la suppression
  int get daysUntilDeletion {
    if (!canBeCancelled) return 0;
    return scheduledDeletionAt.difference(DateTime.now()).inDays;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        requestedAt,
        scheduledDeletionAt,
        status,
        cancellationReason,
      ];
}

/// Exception personnalisee pour les operations de compte
class AccountException implements Exception {
  final String message;
  final int? code;

  AccountException(this.message, {this.code});

  @override
  String toString() => 'AccountException: $message';
}

/// Repository pour la gestion des operations de compte
///
/// Gere les demandes de suppression de compte conformement au RGPD:
/// - Demande de suppression avec delai de grace de 30 jours
/// - Annulation de la demande pendant le delai de grace
/// - Verification du mot de passe avant suppression
class AccountRepository {
  final AppwriteService _appwrite;

  AccountRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Account get _account => _appwrite.account;
  Databases get _databases => _appwrite.databases;

  /// Collection ID pour les demandes de suppression
  static const String _deletionRequestsCollection = 'account_deletion_requests';

  // ============================================
  // Suppression de compte (RGPD)
  // ============================================

  /// Demande la suppression du compte utilisateur
  ///
  /// Cree une demande de suppression avec un delai de grace de 30 jours.
  /// L'utilisateur peut annuler pendant cette periode.
  ///
  /// [userId] - ID de l'utilisateur
  /// [password] - Mot de passe pour verification
  ///
  /// Throws [AccountException] si le mot de passe est incorrect
  /// ou si une demande est deja en cours.
  Future<AccountDeletionRequest> requestAccountDeletion({
    required String userId,
    required String password,
  }) async {
    try {
      // Verifier le mot de passe en tentant une operation authentifiee
      await _verifyPassword(password);

      // Verifier s'il y a deja une demande en cours
      final existingRequest = await getPendingDeletionRequest(userId);
      if (existingRequest != null && existingRequest.canBeCancelled) {
        throw AccountException(
          'Une demande de suppression est deja en cours.',
          code: 409,
        );
      }

      // Creer la demande de suppression
      final now = DateTime.now();
      final scheduledDeletion = now.add(const Duration(days: 30));

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'requestedAt': now.toIso8601String(),
          'scheduledDeletionAt': scheduledDeletion.toIso8601String(),
          'status': 'pending',
          'cancellationReason': null,
        },
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      return AccountDeletionRequest.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw AccountException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Annule une demande de suppression en cours
  ///
  /// [requestId] - ID de la demande a annuler
  /// [reason] - Motif d'annulation (optionnel)
  ///
  /// Throws [AccountException] si la demande ne peut plus etre annulee.
  Future<void> cancelAccountDeletion({
    required String requestId,
    String? reason,
  }) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        documentId: requestId,
        data: {
          'status': 'cancelled',
          'cancellationReason': reason ?? 'Annule par l\'utilisateur',
        },
      );
    } on AppwriteException catch (e) {
      throw AccountException(
        _getReadableErrorMessage(e),
        code: e.code,
      );
    }
  }

  /// Recupere la demande de suppression en cours pour un utilisateur
  ///
  /// Retourne null si aucune demande n'est en cours.
  Future<AccountDeletionRequest?> getPendingDeletionRequest(
    String userId,
  ) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: _deletionRequestsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.equal('status', 'pending'),
          Query.orderDesc('requestedAt'),
          Query.limit(1),
        ],
      );

      if (result.documents.isEmpty) {
        return null;
      }

      return AccountDeletionRequest.fromJson(result.documents.first.data);
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('getPendingDeletionRequest error: ${e.message}');
      }
      return null;
    }
  }

  /// Liste des donnees qui seront supprimees
  ///
  /// Retourne une description des categories de donnees
  /// qui seront supprimees lors de la suppression du compte.
  List<String> getDataToBeDeleted() {
    return [
      'Votre profil et informations personnelles (nom, email, bio)',
      'Votre photo de profil',
      'Vos evenements FUG crees',
      'Votre historique de participations',
      'Vos relations (followers et abonnements)',
      'Vos badges et points de murgilarite',
      'Vos notifications',
      'Vos preferences et parametres',
    ];
  }

  /// Liste des donnees qui seront anonymisees (non supprimees)
  ///
  /// Certaines donnees sont conservees de maniere anonyme
  /// pour des raisons statistiques ou legales.
  List<String> getDataToBeAnonymized() {
    return [
      'Les evenements auxquels vous avez participe (votre nom sera remplace par "Utilisateur supprime")',
      'Les statistiques agregees de l\'application',
    ];
  }

  // ============================================
  // Helpers
  // ============================================

  /// Verifie le mot de passe de l'utilisateur
  ///
  /// Tente une operation authentifiee pour verifier
  /// que le mot de passe est correct.
  Future<void> _verifyPassword(String password) async {
    try {
      // Recuperer l'email de l'utilisateur connecte
      final user = await _account.get();

      // Tenter une re-authentification avec le mot de passe
      // Cela verifie implicitement que le mot de passe est correct
      await _account.createEmailPasswordSession(
        email: user.email,
        password: password,
      );

      // Supprimer la session creee (on garde la session originale)
      // Note: Dans une vraie implementation, on utiliserait une API
      // de verification de mot de passe dediee si disponible
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw AccountException(
          'Mot de passe incorrect.',
          code: 401,
        );
      }
      rethrow;
    }
  }

  /// Convertit les erreurs Appwrite en messages lisibles
  String _getReadableErrorMessage(AppwriteException e) {
    switch (e.code) {
      case 401:
        return 'Mot de passe incorrect.';
      case 404:
        return 'Demande non trouvee.';
      case 409:
        return 'Une demande est deja en cours.';
      default:
        return e.message ?? 'Une erreur est survenue.';
    }
  }
}

// ============================================
// Providers Riverpod
// ============================================

/// Provider pour le repository de compte
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Provider pour recuperer la demande de suppression en cours
///
/// Retourne null si aucune demande n'est en cours.
final pendingDeletionRequestProvider =
    FutureProvider.family<AccountDeletionRequest?, String>((ref, userId) async {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getPendingDeletionRequest(userId);
});

/// Provider pour les donnees qui seront supprimees
final dataToBeDeletedProvider = Provider<List<String>>((ref) {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getDataToBeDeleted();
});

/// Provider pour les donnees qui seront anonymisees
final dataToBeAnonymizedProvider = Provider<List<String>>((ref) {
  final repository = ref.read(accountRepositoryProvider);
  return repository.getDataToBeAnonymized();
});

/// Notifier pour gerer les demandes de suppression
class AccountDeletionNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Demande la suppression du compte
  Future<AccountDeletionRequest> requestDeletion({
    required String userId,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(accountRepositoryProvider);
      final request = await repository.requestAccountDeletion(
        userId: userId,
        password: password,
      );

      // Invalider le cache de la demande en cours
      ref.invalidate(pendingDeletionRequestProvider(userId));

      state = const AsyncValue.data(null);
      return request;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Annule la demande de suppression
  Future<void> cancelDeletion({
    required String requestId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repository = ref.read(accountRepositoryProvider);
      await repository.cancelAccountDeletion(requestId: requestId);

      // Invalider le cache de la demande en cours
      ref.invalidate(pendingDeletionRequestProvider(userId));

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

/// Provider pour le notifier de suppression de compte
final accountDeletionNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AccountDeletionNotifier, void>(() {
  return AccountDeletionNotifier();
});
