import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../domain/leaderboard_entry_model.dart';
import '../providers/gamification_provider.dart';
import '../widgets/leaderboard_entry_widget.dart';

/// Ecran du leaderboard
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final period = LeaderboardPeriod.values[_tabController.index];
      ref.read(selectedLeaderboardPeriodProvider.notifier).state = period;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final leaderboardAsync = ref.watch(currentLeaderboardProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboard),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.weeklyLeaderboard),
            Tab(text: l10n.monthlyLeaderboard),
            Tab(text: l10n.allTimeLeaderboard),
          ],
        ),
      ),
      body: leaderboardAsync.when(
        data: (leaderboard) {
          if (leaderboard.isEmpty) {
            return _buildEmptyState(theme, l10n);
          }

          final currentUserId = currentUserAsync.valueOrNull?.$id;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentLeaderboardProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Podium (top 3)
                SliverToBoxAdapter(
                  child: LeaderboardPodium(
                    topThree: leaderboard.take(3).toList(),
                    currentUserId: currentUserId,
                    onEntryTap: (entry) => _navigateToProfile(entry.userId),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // Separateur
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Classement complet',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Position de l'utilisateur courant si pas dans le top 10
                if (currentUserId != null)
                  _buildCurrentUserPosition(leaderboard, currentUserId, theme),
                // Liste des classements (a partir du 4eme)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Commencer a partir du 4eme (index 3)
                      final actualIndex = index + 3;
                      if (actualIndex >= leaderboard.length) {
                        return null;
                      }

                      final entry = leaderboard[actualIndex];
                      final isCurrentUser = entry.userId == currentUserId;

                      return LeaderboardEntryWidget(
                        entry: entry,
                        isCurrentUser: isCurrentUser,
                        onTap: () => _navigateToProfile(entry.userId),
                      );
                    },
                    childCount: (leaderboard.length - 3).clamp(0, 100),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(theme, l10n, error),
      ),
    );
  }

  Widget _buildCurrentUserPosition(
    List<LeaderboardEntryModel> leaderboard,
    String currentUserId,
    ThemeData theme,
  ) {
    // Chercher la position de l'utilisateur courant
    final userEntry = leaderboard.where((e) => e.userId == currentUserId).toList();

    if (userEntry.isEmpty) {
      // L'utilisateur n'est pas dans le classement
      return SliverToBoxAdapter(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Participez a des evenements pour apparaitre dans le classement!',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final entry = userEntry.first;

    // Si l'utilisateur est dans le top 10, ne pas afficher de bandeau special
    if (entry.rank <= 10) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // Afficher la position de l'utilisateur
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(77),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(77),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre position',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${entry.totalPoints} points',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_upward,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(String userId) {
    context.push('/users/$userId');
  }

  Widget _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 80,
            color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun classement disponible',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier a accumuler des points!',
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
              ref.invalidate(currentLeaderboardProvider);
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
