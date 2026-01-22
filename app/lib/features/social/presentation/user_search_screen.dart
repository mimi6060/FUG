import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../../auth/domain/user_model.dart';
import '../data/social_repository.dart';

/// Provider pour le repository social
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository();
});

/// Provider pour la recherche d'utilisateurs
final userSearchProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.length < 2) return [];

  final repository = ref.watch(socialRepositoryProvider);
  final currentUser = await ref.watch(currentUserProvider.future);

  return repository.searchUsers(
    query: query,
    excludeUserId: currentUser?.$id,
  );
});

/// Provider pour les utilisateurs suggeres
final suggestedUsersProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final currentUser = await ref.watch(currentUserProfileProvider.future);
  if (currentUser == null) return [];

  final repository = ref.watch(socialRepositoryProvider);
  return repository.getSuggestedUsers(
    userId: currentUser.id,
    interests: currentUser.interests,
  );
});

/// Ecran de recherche d'utilisateurs
class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value.trim();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.searchUsers,
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          style: theme.textTheme.bodyLarge,
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: _searchQuery.length >= 2
          ? _SearchResults(query: _searchQuery)
          : _SuggestedUsers(),
    );
  }
}

/// Widget affichant les resultats de recherche
class _SearchResults extends ConsumerWidget {
  final String query;

  const _SearchResults({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final searchAsync = ref.watch(userSearchProvider(query));
    final theme = Theme.of(context);

    return searchAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.noUserFound,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tryAnotherSearchTerm,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _UserTile(user: users[index]);
          },
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
          ],
        ),
      ),
    );
  }
}

/// Widget affichant les utilisateurs suggeres
class _SuggestedUsers extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final suggestedAsync = ref.watch(suggestedUsersProvider);
    final theme = Theme.of(context);

    return suggestedAsync.when(
      data: (users) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.suggestions,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.usersWithSimilarInterests,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (users.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noSuggestionsYet,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.completeProfileWithInterests,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _UserTile(user: users[index]),
                  childCount: users.length,
                ),
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('${l10n.loadingError}: $error'),
      ),
    );
  }
}

/// Tuile affichant un utilisateur
class _UserTile extends ConsumerStatefulWidget {
  final UserModel user;

  const _UserTile({required this.user});

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = await ref.read(currentUserProvider.future);
    if (currentUser == null) return;

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
      leading: CircleAvatar(
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
      title: Row(
        children: [
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              size: 16,
              color: Colors.blue,
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.bio != null && user.bio!.isNotEmpty)
            Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (user.location != null)
            Row(
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
            ),
        ],
      ),
      trailing: SizedBox(
        width: 100,
        child: _isFollowing
            ? OutlinedButton(
                onPressed: _isLoading ? null : _toggleFollow,
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
      ),
      onTap: () => context.push('/users/${user.id}'),
    );
  }
}
