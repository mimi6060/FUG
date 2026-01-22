import 'package:equatable/equatable.dart';

/// Modele representant une entree du leaderboard
class LeaderboardEntryModel extends Equatable {
  /// Rang dans le classement
  final int rank;

  /// ID de l'utilisateur
  final String userId;

  /// Nom d'utilisateur
  final String username;

  /// Nom d'affichage
  final String? displayName;

  /// URL de l'avatar
  final String? avatarUrl;

  /// Total des points
  final int totalPoints;

  /// Niveau actuel
  final int level;

  /// Nombre de badges
  final int badgeCount;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.level,
    required this.badgeCount,
  });

  /// Cree un LeaderboardEntryModel a partir d'un Map JSON
  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userId'] as String,
      username: json['username'] as String? ?? 'Unknown',
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: json['totalPoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      badgeCount: json['badgeCount'] as int? ?? 0,
    );
  }

  /// Convertit le LeaderboardEntryModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'level': level,
      'badgeCount': badgeCount,
    };
  }

  /// Cree une copie avec des valeurs modifiees
  LeaderboardEntryModel copyWith({
    int? rank,
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? totalPoints,
    int? level,
    int? badgeCount,
  }) {
    return LeaderboardEntryModel(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      badgeCount: badgeCount ?? this.badgeCount,
    );
  }

  /// Retourne le nom a afficher
  String get nameToDisplay => displayName ?? username;

  /// Verifie si c'est un podium (top 3)
  bool get isPodium => rank >= 1 && rank <= 3;

  /// Retourne l'emoji du rang pour le podium
  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [
        rank,
        userId,
        username,
        displayName,
        avatarUrl,
        totalPoints,
        level,
        badgeCount,
      ];

  @override
  String toString() =>
      'LeaderboardEntryModel(rank: $rank, username: $username, points: $totalPoints)';
}

/// Periode pour le leaderboard
enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime,
}

/// Extension pour la periode
extension LeaderboardPeriodExtension on LeaderboardPeriod {
  String get value {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'weekly';
      case LeaderboardPeriod.monthly:
        return 'monthly';
      case LeaderboardPeriod.allTime:
        return 'all_time';
    }
  }

  static LeaderboardPeriod fromString(String value) {
    switch (value) {
      case 'weekly':
        return LeaderboardPeriod.weekly;
      case 'monthly':
        return LeaderboardPeriod.monthly;
      case 'all_time':
        return LeaderboardPeriod.allTime;
      default:
        return LeaderboardPeriod.weekly;
    }
  }
}
