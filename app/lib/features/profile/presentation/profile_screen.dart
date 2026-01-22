import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../social/data/social_repository.dart';
import '../../social/presentation/user_search_screen.dart';
import '../domain/profile_model.dart';
import '../data/profile_repository.dart';

/// Provider pour le repository de profil
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Provider pour le profil de l'utilisateur connecte
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getCurrentProfile();
});

/// Provider pour un profil specifique
final profileProvider = FutureProvider.family<ProfileModel?, String>((ref, userId) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getProfile(userId);
});

/// Ecran d'affichage du profil utilisateur
class ProfileScreen extends ConsumerWidget {
  /// ID de l'utilisateur a afficher (null = profil connecte)
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // Utiliser le profil specifique ou le profil connecte
    final profileAsync = userId != null
        ? ref.watch(profileProvider(userId!))
        : ref.watch(currentProfileProvider);

    final currentUser = ref.watch(currentUserProvider);
    final isOwnProfile = userId == null || userId == currentUser.value?.$id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/profile/edit'),
              tooltip: l10n.editProfile,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(l10n.profileNotFound),
            );
          }
          return _ProfileContent(
            profile: profile,
            isOwnProfile: isOwnProfile,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('${l10n.loadingError}: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (userId != null) {
                    ref.invalidate(profileProvider(userId!));
                  } else {
                    ref.invalidate(currentProfileProvider);
                  }
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      // Afficher la barre de navigation uniquement sur son propre profil
      bottomNavigationBar: isOwnProfile
          ? NavigationBar(
              selectedIndex: 3,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/events');
                    break;
                  case 2:
                    context.go('/notifications');
                    break;
                  case 3:
                    // Deja sur le profil
                    break;
                }
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map),
                  label: l10n.map,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.event_outlined),
                  selectedIcon: const Icon(Icons.event),
                  label: l10n.events,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.notifications_outlined),
                  selectedIcon: const Icon(Icons.notifications),
                  label: l10n.notifs,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outlined),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.profile,
                ),
              ],
            )
          : null,
    );
  }
}

/// Contenu principal du profil
class _ProfileContent extends StatelessWidget {
  final ProfileModel profile;
  final bool isOwnProfile;

  const _ProfileContent({
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        // Le refresh sera gere par le provider
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header avec avatar et stats
            _ProfileHeader(profile: profile),

            const SizedBox(height: 24),

            // Boutons d'action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: isOwnProfile
                  ? _OwnProfileActions()
                  : _OtherProfileActions(profile: profile),
            ),

            const SizedBox(height: 24),

            // Bio
            if (profile.bio != null && profile.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutMe,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(profile.bio!),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Interets
            if (profile.user.interests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.interests,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.user.interests.map((interest) {
                            return Chip(
                              label: Text(interest),
                              backgroundColor: theme.colorScheme.primaryContainer,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Statistiques detaillees
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatsCard(profile: profile),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Header du profil avec avatar et statistiques principales
class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primaryContainer.withAlpha(128),
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: profile.avatarUrl != null
                    ? CachedNetworkImageProvider(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null
                    ? Text(
                        profile.initials,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : null,
              ),
              if (profile.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Nom
          Text(
            profile.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          // Localisation
          if (profile.location != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    profile.location!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Note
          if (profile.rating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    profile.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Stats rapides (followers, following, events)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: profile.followersCount.toString(),
                label: l10n.followers,
                onTap: () => context.push('/users/${profile.id}/followers'),
              ),
              _StatItem(
                value: profile.followingCount.toString(),
                label: l10n.following,
                onTap: () => context.push('/users/${profile.id}/following'),
              ),
              _StatItem(
                value: profile.totalEventsCreated.toString(),
                label: l10n.events,
                onTap: () => context.push('/users/${profile.id}/events'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Item de statistique cliquable
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Actions pour son propre profil
class _OwnProfileActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/profile/edit'),
            icon: const Icon(Icons.edit),
            label: Text(l10n.modify),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/events/create'),
            icon: const Icon(Icons.add),
            label: Text(l10n.createFug),
          ),
        ),
      ],
    );
  }
}

/// Actions pour le profil d'un autre utilisateur
class _OtherProfileActions extends ConsumerStatefulWidget {
  final ProfileModel profile;

  const _OtherProfileActions({required this.profile});

  @override
  ConsumerState<_OtherProfileActions> createState() => _OtherProfileActionsState();
}

class _OtherProfileActionsState extends ConsumerState<_OtherProfileActions> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.profile.isFollowing;
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    final repository = ref.read(socialRepositoryProvider);
    final isFollowing = await repository.isFollowing(
      followerId: currentUser.$id,
      followingId: widget.profile.id,
    );

    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(socialRepositoryProvider);
      final nowFollowing = await repository.toggleFollow(
        followerId: currentUser.$id,
        followingId: widget.profile.id,
      );

      if (mounted) {
        setState(() {
          _isFollowing = nowFollowing;
        });
        // Rafraichir les donnees du profil
        ref.invalidate(profileProvider(widget.profile.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: _isFollowing
              ? OutlinedButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.followingStatus),
                )
              : FilledButton(
                  onPressed: _isLoading ? null : _toggleFollow,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.follow),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Envoyer un message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.messagingComingSoon)),
              );
            },
            icon: const Icon(Icons.message),
            label: Text(l10n.message),
          ),
        ),
      ],
    );
  }
}

/// Carte de statistiques detaillees
class _StatsCard extends StatelessWidget {
  final ProfileModel profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatRow(
              icon: Icons.event,
              label: l10n.eventsCreated,
              value: profile.totalEventsCreated.toString(),
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.check_circle,
              label: l10n.participations,
              value: profile.totalEventsAttended.toString(),
            ),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.star,
              label: l10n.averageRating,
              value: profile.rating > 0
                  ? '${profile.rating.toStringAsFixed(1)}/5'
                  : l10n.notRated,
            ),
            if (profile.points > 0) ...[
              const SizedBox(height: 12),
              _StatRow(
                icon: Icons.emoji_events,
                label: l10n.points,
                value: profile.points.toString(),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: profile.levelProgress / 100,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.level(profile.level)} - ${profile.levelProgress.toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ligne de statistique
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
