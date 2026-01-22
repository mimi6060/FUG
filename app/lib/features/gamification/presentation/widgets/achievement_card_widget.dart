import 'package:flutter/material.dart';

import '../../domain/achievement_model.dart';

/// Widget affichant une carte d'achievement/badge
class AchievementCard extends StatelessWidget {
  /// L'achievement a afficher
  final AchievementModel achievement;

  /// Callback au clic sur la carte
  final VoidCallback? onTap;

  /// Taille de la carte (compact ou normal)
  final bool compact;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactCard(theme);
    }

    return _buildNormalCard(theme);
  }

  Widget _buildCompactCard(ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? _getTierColor(theme).withAlpha(25)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          border: achievement.isUnlocked
              ? Border.all(color: _getTierColor(theme), width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme, size: 40),
            const SizedBox(height: 4),
            Text(
              achievement.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: achievement.isUnlocked
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalCard(ThemeData theme) {
    return Card(
      elevation: achievement.isUnlocked ? 2 : 0,
      color: achievement.isUnlocked
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerHighest.withAlpha(128),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(theme, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: achievement.isUnlocked
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          achievement.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: achievement.isUnlocked
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant.withAlpha(128),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (achievement.isUnlocked)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                ],
              ),
              if (!achievement.isUnlocked && achievement.progress != null) ...[
                const SizedBox(height: 12),
                _buildProgressBar(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, {required double size}) {
    final isUnlocked = achievement.isUnlocked;
    final color = isUnlocked ? _getTierColor(theme) : Colors.grey;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(isUnlocked ? 51 : 25),
            border: Border.all(
              color: color.withAlpha(isUnlocked ? 128 : 51),
              width: 2,
            ),
          ),
          child: Icon(
            _getIconData(),
            size: size * 0.5,
            color: color,
          ),
        ),
        if (!isUnlocked)
          Icon(
            Icons.lock,
            size: size * 0.3,
            color: Colors.grey.shade600,
          ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progress = achievement.progress!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${progress.current}/${progress.target}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.percentage / 100,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.colorScheme.primary.withAlpha(179),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Color _getTierColor(ThemeData theme) {
    switch (achievement.tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0); // Silver
      case AchievementTier.gold:
        return const Color(0xFFFFD700); // Gold
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2); // Platinum
    }
  }

  IconData _getIconData() {
    // Map les noms d'icones du backend vers des IconData Flutter
    final iconMap = <String, IconData>{
      'badge-first-event': Icons.celebration,
      'badge-enthusiast': Icons.local_fire_department,
      'badge-veteran': Icons.military_tech,
      'badge-creator': Icons.add_circle,
      'badge-master': Icons.workspace_premium,
      'badge-legend': Icons.emoji_events,
      'badge-social': Icons.people,
      'badge-influencer': Icons.trending_up,
      'badge-star': Icons.star,
      'badge-level-5': Icons.looks_5,
      'badge-level-10': Icons.looks,
      'badge-level-25': Icons.diamond,
      'badge-early-adopter': Icons.rocket_launch,
      'badge-helper': Icons.volunteer_activism,
    };

    return iconMap[achievement.icon] ?? Icons.emoji_events;
  }
}

/// Widget affichant une grille d'achievements
class AchievementsGrid extends StatelessWidget {
  /// Liste des achievements a afficher
  final List<AchievementModel> achievements;

  /// Callback au clic sur un achievement
  final Function(AchievementModel)? onAchievementTap;

  /// Si true, affiche en mode compact
  final bool compact;

  const AchievementsGrid({
    super.key,
    required this.achievements,
    this.onAchievementTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: achievements
            .map((achievement) => AchievementCard(
                  achievement: achievement,
                  compact: true,
                  onTap: onAchievementTap != null
                      ? () => onAchievementTap!(achievement)
                      : null,
                ))
            .toList(),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: achievements.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementCard(
          achievement: achievement,
          onTap: onAchievementTap != null
              ? () => onAchievementTap!(achievement)
              : null,
        );
      },
    );
  }
}
