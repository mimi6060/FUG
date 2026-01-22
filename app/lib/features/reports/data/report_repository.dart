import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';
import '../domain/report_model.dart';
import '../domain/moderation_action_model.dart';

/// Exception personnalisee pour les signalements
class ReportException implements Exception {
  final String message;
  final int? code;

  ReportException(this.message, {this.code});

  @override
  String toString() => 'ReportException: $message';
}

/// Repository pour la gestion des signalements (DSA compliance)
class ReportRepository {
  final AppwriteService _appwrite;

  ReportRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Databases get _databases => _appwrite.databases;

  // =============================================
  // Creation de signalements
  // =============================================

  /// Cree un nouveau signalement de contenu
  /// Conforme DSA: les utilisateurs doivent pouvoir signaler facilement
  Future<ReportModel> createReport({
    required String reporterId,
    required ReportContentType contentType,
    required String contentId,
    required ReportCategory category,
    String? description,
  }) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollectionId,
        documentId: ID.unique(),
        data: {
          'reporterId': reporterId,
          'contentType': contentType.value,
          'contentId': contentId,
          'category': category.value,
          'description': description,
          'status': ReportStatus.pending.value,
          'createdAt': DateTime.now().toIso8601String(),
        },
        permissions: [
          // Reporter can read their own report
          Permission.read(Role.user(reporterId)),
          // Moderators team can manage
          Permission.read(Role.team('moderators')),
          Permission.update(Role.team('moderators')),
          Permission.delete(Role.team('moderators')),
        ],
      );

      return ReportModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw ReportException(
        e.message ?? 'Erreur lors de la creation du signalement.',
        code: e.code,
      );
    }
  }

  // =============================================
  // Recuperation des signalements (utilisateur)
  // =============================================

  /// Recupere les signalements faits par un utilisateur
  Future<List<ReportModel>> getMyReports({
    required String userId,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollectionId,
        queries: [
          Query.equal('reporterId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      return result.documents
          .map((doc) => ReportModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw ReportException(
        e.message ?? 'Erreur lors de la recuperation des signalements.',
        code: e.code,
      );
    }
  }

  /// Recupere un signalement par son ID
  Future<ReportModel?> getReport(String reportId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollectionId,
        documentId: reportId,
      );

      return ReportModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw ReportException(
        e.message ?? 'Erreur lors de la recuperation du signalement.',
        code: e.code,
      );
    }
  }

  /// Verifie si un contenu a deja ete signale par l'utilisateur
  Future<bool> hasAlreadyReported({
    required String userId,
    required String contentId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollectionId,
        queries: [
          Query.equal('reporterId', userId),
          Query.equal('contentId', contentId),
          Query.limit(1),
        ],
      );

      return result.total > 0;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error checking existing report: ${e.message}');
      }
      return false;
    }
  }

  // =============================================
  // Actions de moderation (utilisateur)
  // =============================================

  /// Recupere les actions de moderation contre l'utilisateur
  /// Conforme DSA: transparence sur les decisions de moderation
  Future<List<ModerationActionModel>> getMyModerationActions({
    required String userId,
    int limit = 25,
    int offset = 0,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'moderation_actions',
        queries: [
          Query.equal('targetUserId', userId),
          Query.orderDesc('createdAt'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      return result.documents
          .map((doc) => ModerationActionModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw ReportException(
        e.message ?? 'Erreur lors de la recuperation des actions de moderation.',
        code: e.code,
      );
    }
  }

  /// Recupere une action de moderation par son ID
  Future<ModerationActionModel?> getModerationAction(String actionId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'moderation_actions',
        documentId: actionId,
      );

      return ModerationActionModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw ReportException(
        e.message ?? 'Erreur lors de la recuperation de l\'action.',
        code: e.code,
      );
    }
  }

  /// Soumet un appel contre une action de moderation
  /// Conforme DSA: droit d'appel obligatoire
  Future<ModerationActionModel> submitAppeal({
    required String actionId,
    required String appealText,
  }) async {
    try {
      // Verifier que l'action existe et que l'appel est encore possible
      final action = await getModerationAction(actionId);
      if (action == null) {
        throw ReportException('Action de moderation introuvable.');
      }
      if (!action.canAppeal) {
        throw ReportException(
          'Le delai pour faire appel (72h) est depasse ou vous avez deja fait appel.',
        );
      }

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'moderation_actions',
        documentId: actionId,
        data: {
          'isAppealed': true,
          'appealText': appealText,
          'appealedAt': DateTime.now().toIso8601String(),
          'appealStatus': AppealStatus.pending.value,
        },
      );

      return ModerationActionModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw ReportException(
        e.message ?? 'Erreur lors de la soumission de l\'appel.',
        code: e.code,
      );
    }
  }

  // =============================================
  // Statistiques utilisateur
  // =============================================

  /// Compte le nombre de signalements en attente faits par l'utilisateur
  Future<int> getPendingReportsCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.reportsCollectionId,
        queries: [
          Query.equal('reporterId', userId),
          Query.equal('status', ReportStatus.pending.value),
          Query.limit(1),
        ],
      );

      return result.total;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error getting pending reports count: ${e.message}');
      }
      return 0;
    }
  }

  /// Compte le nombre d'appels en attente de l'utilisateur
  Future<int> getPendingAppealsCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'moderation_actions',
        queries: [
          Query.equal('targetUserId', userId),
          Query.equal('isAppealed', true),
          Query.equal('appealStatus', AppealStatus.pending.value),
          Query.limit(1),
        ],
      );

      return result.total;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error getting pending appeals count: ${e.message}');
      }
      return 0;
    }
  }
}
