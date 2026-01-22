import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../auth/domain/user_model.dart';
import '../data/social_repository.dart';
import 'user_search_screen.dart';

/// Provider pour les followers d'un utilisateur
final followersProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getFollowers(userId: userId);
});

/// Provider pour les utilisateurs suivis
final followingProvider =
    FutureProvider.family<List<UserModel>, String>((ref, userId) async {
  final repository = ref.watch(socialRepositoryProvider);
  return repository.getFollowing(userId: userId);
});

/// Ecran affichant la liste des followers ou des suivis
class FollowersListScreen extends ConsumerWidget {
  /// ID de l'utilisateur dont on affiche les followers/following
  final String userId;

  /// true = followers, false = following
  final bool isFollowers;

  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.isFollowers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final listAsync = isFollowers
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isFollowers ? l10n.followers : l10n.following),
      ),
      body: listAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFollowers ? Icons.people_outline : Icons.person_add_disabled,
                    size: 80,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isFollowers
                        ? l10n.noFollowersYet
                        : l10n.notFollowingAnyone,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!isFollowers)
                    FilledButton.icon(
                      onPressed: () => context.push('/search'),
                      icon: const Icon(Icons.search),
                      label: Text(l10n.findUsers),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (isFollowers) {
                ref.invalidate(followersProvider(userId));
              } else {
                ref.invalidate(followingProvider(userId));
              }
            },
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _FollowerTile(
                  user: users[index],
                  showFollowButton: true,
                );
              },
            ),
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
                  if (isFollowers) {
                    ref.invalidate(followersProvider(userId));
                  } else {
                    ref.invalidate(followingProvider(userId));
                  }
                },
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tuile affichant un follower/following
class _FollowerTile extends ConsumerStatefulWidget {
  final UserModel user;
  final bool showFollowButton;

  const _FollowerTile({
    required this.user,
    this.showFollowButton = true,
  });

  @override
  ConsumerState<_FollowerTile> createState() => _FollowerTileState();
}

class _FollowerTileState extends ConsumerState<_FollowerTile> {
  bool _isFollowing = false;
  bool _isLoading = false;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

    // Verifier si c'est l'utilisateur actuel
    if (currentUser.$id == widget.user.id) {
      if (mounted) {
        setState(() {
          _isCurrentUser = true;
        });
      }
      return;
    }

    // Verifier le statut de suivi
    final repository = ref.read(socialRepositoryProvider);
    final isFollowing = await repository.isFollowing(
      followerId: currentUser.$id,
      followingId: widget.user.id,
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
        followingId: widget.user.id,
      );

      if (mounted) {
        setState(() {
          _isFollowing = nowFollowing;
        });
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
    final theme = Theme.of(context);
    final user = widget.user;

    return ListTile(
      leading: GestureDetector(
        onTap: () => context.push('/users/${user.id}'),
        child: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          backgroundImage:
              user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.initials,
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                )
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: () => context.push('/users/${user.id}'),
        child: Row(
          children: [
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                size: 16,
                color: Colors.blue,
              ),
            ],
            if (_isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.you,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      subtitle: user.bio != null && user.bio!.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : user.location != null
              ? Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      user.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : null,
      trailing: widget.showFollowButton && !_isCurrentUser
          ? SizedBox(
              width: 100,
              child: _isFollowing
                  ? OutlinedButton(
                      onPressed: _isLoading ? null : _toggleFollow,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.followingStatus),
                    )
                  : FilledButton(
                      onPressed: _isLoading ? null : _toggleFollow,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.follow),
                    ),
            )
          : null,
      onTap: () => context.push('/users/${user.id}'),
    );
  }
}

/// Widget pour afficher les followers avec un compteur
class FollowersCountWidget extends ConsumerWidget {
  final String userId;
  final VoidCallback? onTap;

  const FollowersCountWidget({
    super.key,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final followersAsync = ref.watch(followersProvider(userId));
    final followingAsync = ref.watch(followingProvider(userId));
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Followers
        GestureDetector(
          onTap: () => context.push('/users/$userId/followers'),
          child: Column(
            children: [
              followersAsync.when(
                data: (followers) => Text(
                  followers.length.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('-'),
              ),
              Text(
                l10n.followers,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Divider vertical
        Container(
          width: 1,
          height: 40,
          color: theme.colorScheme.outlineVariant,
        ),

        // Following
        GestureDetector(
          onTap: () => context.push('/users/$userId/following'),
          child: Column(
            children: [
              followingAsync.when(
                data: (following) => Text(
                  following.length.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('-'),
              ),
              Text(
                l10n.following,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
