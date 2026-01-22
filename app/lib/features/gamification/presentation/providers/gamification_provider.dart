import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/gamification_repository.dart';
import '../../domain/achievement_model.dart';
import '../../domain/leaderboard_entry_model.dart';

// Re-export UserAchievementsResult for screens
export '../../data/gamification_repository.dart' show UserAchievementsResult;

/// Provider pour le repository de gamification
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository();
});

/// Provider pour tous les badges disponibles
final achievementsProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getAchievements();
});

/// Provider pour les achievements d'un utilisateur specifique
final userAchievementsProvider = FutureProvider.autoDispose
    .family<UserAchievementsResult, String>((ref, userId) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserAchievements(userId);
});

/// Provider pour les achievements de l'utilisateur courant
final currentUserAchievementsProvider =
    FutureProvider.autoDispose<UserAchievementsResult?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getUserAchievements(user.$id);
});

/// Provider pour le leaderboard avec une periode specifique
final leaderboardProvider = FutureProvider.autoDispose
    .family<List<LeaderboardEntryModel>, LeaderboardPeriod>((ref, period) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getLeaderboard(period);
});

/// Provider pour la periode selectionnee du leaderboard
final selectedLeaderboardPeriodProvider =
    StateProvider<LeaderboardPeriod>((ref) => LeaderboardPeriod.weekly);

/// Provider pour le leaderboard avec la periode selectionnee
final currentLeaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntryModel>>((ref) async {
  final period = ref.watch(selectedLeaderboardPeriodProvider);
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getLeaderboard(period);
});

/// Provider pour verifier et mettre a jour les achievements de l'utilisateur courant
final checkAchievementsProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return;

  final repository = ref.watch(gamificationRepositoryProvider);
  await repository.checkAchievements(user.$id);

  // Invalidate les providers pour rafraichir les donnees
  ref.invalidate(currentUserAchievementsProvider);
});

/// Provider pour les badges debloques de l'utilisateur courant
final unlockedBadgesProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final result = await ref.watch(currentUserAchievementsProvider.future);
  return result?.earnedBadges ?? [];
});

/// Provider pour les badges non debloques de l'utilisateur courant
final lockedBadgesProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final result = await ref.watch(currentUserAchievementsProvider.future);
  return result?.availableBadges ?? [];
});

/// Provider pour le niveau et la progression de l'utilisateur courant
final userLevelProvider =
    FutureProvider.autoDispose<UserGamificationData?>((ref) async {
  final result = await ref.watch(currentUserAchievementsProvider.future);
  return result?.gamification;
});

/// Provider pour le rang de l'utilisateur courant dans le leaderboard
final currentUserRankProvider =
    FutureProvider.autoDispose<LeaderboardEntryModel?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;

  final leaderboard = await ref.watch(currentLeaderboardProvider.future);

  try {
    return leaderboard.firstWhere((entry) => entry.userId == user.$id);
  } catch (e) {
    // L'utilisateur n'est pas dans le leaderboard
    return null;
  }
});
