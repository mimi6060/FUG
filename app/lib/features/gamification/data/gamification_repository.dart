import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/appwrite_service.dart';
import '../domain/achievement_model.dart';
import '../domain/leaderboard_entry_model.dart';

/// Exception personnalisee pour les operations de gamification
class GamificationException implements Exception {
  final String message;
  final int? code;

  GamificationException(this.message, {this.code});

  @override
  String toString() => 'GamificationException: $message';
}

/// Statistiques utilisateur
class UserStats {
  final int eventsJoined;
  final int eventsCreated;
  final int followersCount;
  final int followingCount;
  final int level;

  const UserStats({
    required this.eventsJoined,
    required this.eventsCreated,
    required this.followersCount,
    required this.followingCount,
    required this.level,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      eventsJoined: json['eventsJoined'] as int? ?? 0,
      eventsCreated: json['eventsCreated'] as int? ?? 0,
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
    );
  }
}

/// Donnees de gamification utilisateur
class UserGamificationData {
  final int totalPoints;
  final int level;
  final int progressToNextLevel;
  final int pointsNeeded;
  final int progressPercentage;

  const UserGamificationData({
    required this.totalPoints,
    required this.level,
    required this.progressToNextLevel,
    required this.pointsNeeded,
    required this.progressPercentage,
  });

  factory UserGamificationData.fromJson(Map<String, dynamic> json) {
    return UserGamificationData(
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      progressToNextLevel: json['progressToNextLevel'] as int? ?? 0,
      pointsNeeded: json['pointsNeeded'] as int? ?? 100,
      progressPercentage: json['progressPercentage'] as int? ?? 0,
    );
  }
}

/// Resultats des stats utilisateur
class UserAchievementsResult {
  final UserStats stats;
  final UserGamificationData gamification;
  final List<AchievementModel> earnedBadges;
  final List<AchievementModel> availableBadges;
  final int totalEarned;
  final int totalAvailable;

  const UserAchievementsResult({
    required this.stats,
    required this.gamification,
    required this.earnedBadges,
    required this.availableBadges,
    required this.totalEarned,
    required this.totalAvailable,
  });
}

/// Repository pour la gestion de la gamification
///
/// Gere toutes les operations liees a la gamification:
/// - Recuperation des badges
/// - Statistiques utilisateur
/// - Leaderboard
class GamificationRepository {
  final AppwriteService _appwrite;

  /// ID de la fonction gamification
  static const String _gamificationFunctionId = 'gamification';

  GamificationRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Functions get _functions => _appwrite.functions;

  // ===========================================
  // Recuperation des badges
  // ===========================================

  /// Recupere la liste de tous les badges disponibles
  Future<List<AchievementModel>> getAchievements() async {
    try {
      final execution = await _functions.createExecution(
        functionId: _gamificationFunctionId,
        body: jsonEncode({'action': 'get_badges'}),
      );

      final response = _parseResponse(execution.responseBody);

      if (response['success'] != true) {
        throw GamificationException(
          response['error'] as String? ?? 'Erreur lors de la recuperation des badges.',
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      final badgesList = data['badges'] as List<dynamic>;

      return badgesList
          .map((json) => AchievementModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on AppwriteException catch (e) {
      throw GamificationException(
        e.message ?? 'Erreur lors de la recuperation des badges.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Statistiques utilisateur
  // ===========================================

  /// Recupere les statistiques et badges d'un utilisateur
  Future<UserAchievementsResult> getUserAchievements(String userId) async {
    try {
      final execution = await _functions.createExecution(
        functionId: _gamificationFunctionId,
        body: jsonEncode({
          'action': 'get_user_stats',
          'userId': userId,
        }),
      );

      final response = _parseResponse(execution.responseBody);

      if (response['success'] != true) {
        throw GamificationException(
          response['error'] as String? ?? 'Erreur lors de la recuperation des stats.',
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      final statsJson = data['stats'] as Map<String, dynamic>;
      final gamificationJson = data['gamification'] as Map<String, dynamic>;
      final badgesJson = data['badges'] as Map<String, dynamic>;

      final stats = UserStats.fromJson(statsJson);
      final gamification = UserGamificationData.fromJson(gamificationJson);

      final earnedList = badgesJson['earned'] as List<dynamic>? ?? [];
      final availableList = badgesJson['available'] as List<dynamic>? ?? [];

      final earnedBadges = earnedList
          .map((json) => AchievementModel.fromJson({
                ...json as Map<String, dynamic>,
                'isUnlocked': true,
              }))
          .toList();

      final availableBadges = availableList
          .map((json) => AchievementModel.fromJson({
                ...json as Map<String, dynamic>,
                'isUnlocked': false,
              }))
          .toList();

      return UserAchievementsResult(
        stats: stats,
        gamification: gamification,
        earnedBadges: earnedBadges,
        availableBadges: availableBadges,
        totalEarned: badgesJson['totalEarned'] as int? ?? earnedBadges.length,
        totalAvailable: badgesJson['totalAvailable'] as int? ?? 13,
      );
    } on AppwriteException catch (e) {
      throw GamificationException(
        e.message ?? 'Erreur lors de la recuperation des stats.',
        code: e.code,
      );
    }
  }

  /// Verifie et attribue les achievements pour un utilisateur
  Future<void> checkAchievements(String userId) async {
    try {
      final execution = await _functions.createExecution(
        functionId: _gamificationFunctionId,
        body: jsonEncode({
          'action': 'check_achievements',
          'userId': userId,
        }),
      );

      final response = _parseResponse(execution.responseBody);

      if (response['success'] != true) {
        throw GamificationException(
          response['error'] as String? ?? 'Erreur lors de la verification des achievements.',
        );
      }
    } on AppwriteException catch (e) {
      throw GamificationException(
        e.message ?? 'Erreur lors de la verification des achievements.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Leaderboard
  // ===========================================

  /// Recupere le leaderboard pour une periode donnee
  Future<List<LeaderboardEntryModel>> getLeaderboard(LeaderboardPeriod period) async {
    try {
      final execution = await _functions.createExecution(
        functionId: _gamificationFunctionId,
        body: jsonEncode({
          'action': 'calculate_leaderboard',
          'period': period.value,
        }),
      );

      final response = _parseResponse(execution.responseBody);

      if (response['success'] != true) {
        throw GamificationException(
          response['error'] as String? ?? 'Erreur lors de la recuperation du leaderboard.',
        );
      }

      final data = response['data'] as Map<String, dynamic>;
      final leaderboardList = data['leaderboard'] as List<dynamic>;

      return leaderboardList
          .map((json) => LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on AppwriteException catch (e) {
      throw GamificationException(
        e.message ?? 'Erreur lors de la recuperation du leaderboard.',
        code: e.code,
      );
    }
  }

  // ===========================================
  // Utilitaires
  // ===========================================

  /// Parse la reponse JSON de la fonction
  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing response: $e');
        print('Response body: $responseBody');
      }
      throw GamificationException('Erreur lors du parsing de la reponse.');
    }
  }
}
