import 'package:flutter/material.dart';

import '../../data/gamification_repository.dart';

/// Widget affichant le badge de niveau utilisateur
class LevelBadge extends StatelessWidget {
  /// Niveau a afficher
  final int level;

  /// Taille du badge
  final double size;

  /// Si true, affiche une version simplifiee
  final bool simple;

  const LevelBadge({
    super.key,
    required this.level,
    this.size = 48,
    this.simple = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getLevelColor();

    if (simple) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              'Lvl $level',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(179),
            color,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decoration
          Icon(
            Icons.hexagon_outlined,
            size: size * 0.9,
            color: Colors.white.withAlpha(51),
          ),
          // Niveau
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$level',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'LVL',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontSize: size * 0.15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    if (level >= 25) {
      return const Color(0xFFFFD700); // Gold
    } else if (level >= 10) {
      return const Color(0xFF9C27B0); // Purple
    } else if (level >= 5) {
      return const Color(0xFF2196F3); // Blue
    } else {
      return const Color(0xFF4CAF50); // Green
    }
  }
}

/// Widget affichant la progression vers le prochain niveau
class LevelProgressCard extends StatelessWidget {
  /// Donnees de gamification
  final UserGamificationData gamification;

  const LevelProgressCard({
    super.key,
    required this.gamification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LevelBadge(level: gamification.level, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLevelTitle(gamification.level),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${gamification.totalPoints} points',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochain niveau',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${gamification.progressToNextLevel}/${gamification.pointsNeeded}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: gamification.progressPercentage / 100,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${gamification.progressPercentage}% vers le niveau ${gamification.level + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level >= 25) {
      return 'Maitre FUG';
    } else if (level >= 10) {
      return 'Expert';
    } else if (level >= 5) {
      return 'Apprenti';
    } else {
      return 'Debutant';
    }
  }
}
