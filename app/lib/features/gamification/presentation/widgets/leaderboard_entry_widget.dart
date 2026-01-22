import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/leaderboard_entry_model.dart';
import 'level_badge_widget.dart';

/// Widget affichant une entree du leaderboard
class LeaderboardEntryWidget extends StatelessWidget {
  /// L'entree du leaderboard
  final LeaderboardEntryModel entry;

  /// Si c'est l'utilisateur courant
  final bool isCurrentUser;

  /// Callback au clic
  final VoidCallback? onTap;

  const LeaderboardEntryWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isCurrentUser ? 4 : 1,
      color: isCurrentUser
          ? theme.colorScheme.primaryContainer.withAlpha(77)
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rang
              _buildRank(theme),
              const SizedBox(width: 12),
              // Avatar
              _buildAvatar(theme),
              const SizedBox(width: 12),
              // Infos utilisateur
              Expanded(
                child: _buildUserInfo(theme),
              ),
              // Points et niveau
              _buildStats(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRank(ThemeData theme) {
    if (entry.isPodium) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPodiumColor().withAlpha(25),
        ),
        child: Center(
          child: Text(
            entry.rankEmoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Text(
          '${entry.rank}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          backgroundImage: entry.avatarUrl != null
              ? CachedNetworkImageProvider(entry.avatarUrl!)
              : null,
          child: entry.avatarUrl == null
              ? Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        if (isCurrentUser)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              child: const Icon(
                Icons.star,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                entry.nameToDisplay,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Vous',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${entry.badgeCount} badges',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${entry.totalPoints}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: entry.isPodium ? _getPodiumColor() : theme.colorScheme.primary,
          ),
        ),
        Text(
          'pts',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        LevelBadge(level: entry.level, simple: true),
      ],
    );
  }

  Color _getPodiumColor() {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}

/// Widget affichant le podium (top 3)
class LeaderboardPodium extends StatelessWidget {
  /// Les 3 premieres entrees
  final List<LeaderboardEntryModel> topThree;

  /// ID de l'utilisateur courant
  final String? currentUserId;

  /// Callback au clic sur une entree
  final Function(LeaderboardEntryModel)? onEntryTap;

  const LeaderboardPodium({
    super.key,
    required this.topThree,
    this.currentUserId,
    this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    // Reorganiser pour avoir 2-1-3
    final positions = <LeaderboardEntryModel?>[
      topThree.length > 1 ? topThree[1] : null, // 2eme
      topThree.isNotEmpty ? topThree[0] : null, // 1er
      topThree.length > 2 ? topThree[2] : null, // 3eme
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (positions[0] != null)
            Expanded(
              child: _buildPodiumItem(context, positions[0]!, 80),
            ),
          if (positions[1] != null)
            Expanded(
              child: _buildPodiumItem(context, positions[1]!, 100),
            ),
          if (positions[2] != null)
            Expanded(
              child: _buildPodiumItem(context, positions[2]!, 60),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    BuildContext context,
    LeaderboardEntryModel entry,
    double height,
  ) {
    final theme = Theme.of(context);
    final isCurrentUser = entry.userId == currentUserId;
    final color = _getPodiumColor(entry.rank);

    return GestureDetector(
      onTap: onEntryTap != null ? () => onEntryTap!(entry) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: entry.rank == 1 ? 40 : 32,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: entry.avatarUrl != null
                      ? CachedNetworkImageProvider(entry.avatarUrl!)
                      : null,
                  child: entry.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: entry.rank == 1 ? 40 : 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: Text(
                    entry.rankEmoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nom
          Text(
            entry.nameToDisplay,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? theme.colorScheme.primary : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Points
          Text(
            '${entry.totalPoints} pts',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Piedestal
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withAlpha(179),
                  color,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPodiumColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}
