import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/achievement_model.dart';
import '../providers/gamification_provider.dart';
import '../widgets/achievement_card_widget.dart';
import '../widgets/level_badge_widget.dart';

/// Ecran des achievements/badges
class AchievementsScreen extends ConsumerStatefulWidget {
  /// ID de l'utilisateur (optionnel, par defaut utilisateur courant)
  final String? userId;

  const AchievementsScreen({super.key, this.userId});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final achievementsAsync = widget.userId != null
        ? ref.watch(userAchievementsProvider(widget.userId!))
        : ref.watch(currentUserAchievementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.achievements),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.unlocked),
            Tab(text: l10n.locked),
          ],
        ),
      ),
      body: achievementsAsync.when(
        data: (result) {
          if (result == null) {
            return _buildEmptyState(theme, l10n);
          }

          return Column(
            children: [
              // Carte de progression du niveau
              Padding(
                padding: const EdgeInsets.all(16),
                child: LevelProgressCard(gamification: result.gamification),
              ),
              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatsRow(theme, l10n, result),
              ),
              const SizedBox(height: 8),
              // Tabs avec les badges
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Badges debloques
                    _buildBadgesList(
                      theme,
                      l10n,
                      result.earnedBadges,
                      isUnlocked: true,
                    ),
                    // Badges a debloquer
                    _buildBadgesList(
                      theme,
                      l10n,
                      result.availableBadges,
                      isUnlocked: false,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, l10n, error),
      ),
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    AppLocalizations l10n,
    UserAchievementsResult result,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.emoji_events,
            '${result.totalEarned}',
            l10n.unlocked,
            theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.lock_open,
            '${result.totalAvailable - result.totalEarned}',
            l10n.locked,
            theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            theme,
            Icons.percent,
            '${((result.totalEarned / result.totalAvailable) * 100).round()}%',
            'Completion',
            theme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesList(
    ThemeData theme,
    AppLocalizations l10n,
    List<AchievementModel> badges,
    {required bool isUnlocked}
  ) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked
                  ? 'Aucun badge debloque'
                  : 'Tous les badges sont debloques!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isUnlocked) ...[
              const SizedBox(height: 8),
              Text(
                'Participez a des evenements pour debloquer des badges',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // Grouper par categorie
    final groupedBadges = <AchievementCategory, List<AchievementModel>>{};
    for (final badge in badges) {
      groupedBadges.putIfAbsent(badge.category, () => []).add(badge);
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.userId != null) {
          ref.invalidate(userAchievementsProvider(widget.userId!));
        } else {
          ref.invalidate(currentUserAchievementsProvider);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final category in groupedBadges.keys) ...[
            _buildCategoryHeader(theme, category),
            const SizedBox(height: 8),
            ...groupedBadges[category]!.map(
              (badge) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AchievementCard(
                  achievement: badge,
                  onTap: () => _showBadgeDetails(badge),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(ThemeData theme, AchievementCategory category) {
    final categoryNames = {
      AchievementCategory.participation: 'Participation',
      AchievementCategory.creation: 'Creation',
      AchievementCategory.social: 'Social',
      AchievementCategory.level: 'Niveau',
      AchievementCategory.special: 'Special',
    };

    final categoryIcons = {
      AchievementCategory.participation: Icons.people,
      AchievementCategory.creation: Icons.add_circle,
      AchievementCategory.social: Icons.favorite,
      AchievementCategory.level: Icons.trending_up,
      AchievementCategory.special: Icons.star,
    };

    return Row(
      children: [
        Icon(
          categoryIcons[category] ?? Icons.emoji_events,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          categoryNames[category] ?? 'Autre',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showBadgeDetails(AchievementModel badge) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Badge icon
            AchievementCard(
              achievement: badge,
            ),
            const SizedBox(height: 16),
            // Status
            if (badge.isUnlocked && badge.unlockedAt != null)
              Text(
                'Debloque le ${_formatDate(badge.unlockedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnee disponible',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour voir vos badges',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    AppLocalizations l10n,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            l10n.unexpectedError,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (widget.userId != null) {
                ref.invalidate(userAchievementsProvider(widget.userId!));
              } else {
                ref.invalidate(currentUserAchievementsProvider);
              }
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
