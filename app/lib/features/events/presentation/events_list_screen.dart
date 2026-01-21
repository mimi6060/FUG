import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/events_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../domain/event_model.dart';

/// Ecran affichant la liste des evenements
class EventsListScreen extends ConsumerStatefulWidget {
  const EventsListScreen({super.key});

  @override
  ConsumerState<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends ConsumerState<EventsListScreen> {
  bool _isLoading = true;
  String? _error;
  List<EventModel> _events = [];
  double _searchRadius = 10.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final position = await ref.read(currentPositionProvider.future);
      if (position != null && mounted) {
        final events = await ref.read(nearbyEventsProvider(
          NearbyEventsParams(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusKm: _searchRadius,
          ),
        ).future);

        if (mounted) {
          setState(() {
            _events = events;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _error = 'Impossible d\'obtenir votre position';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evenements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/events/search'),
            tooltip: 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
            tooltip: 'Filtres',
          ),
        ],
      ),
      body: _buildBody(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/events/create'),
        icon: const Icon(Icons.add),
        label: const Text('Creer un FUG'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              // Deja sur la liste
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Evenements',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun evenement a proximite',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier a creer un FUG!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/events/create'),
              icon: const Icon(Icons.add),
              label: const Text('Creer un FUG'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return _EventCard(
            event: event,
            onTap: () => context.push('/events/${event.id}'),
          );
        },
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FiltersSheet(
        currentRadius: _searchRadius,
        onRadiusChanged: (radius) {
          setState(() {
            _searchRadius = radius;
          });
          _loadEvents();
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// Carte d'un evenement dans la liste
class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de l'evenement
            if (event.imageUrl != null)
              Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et badges
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPriceBadge(theme),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.startDate),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Lieu
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venueName ?? event.address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Participants
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.maxParticipants != null
                            ? '${event.currentParticipants}/${event.maxParticipants}'
                            : '${event.currentParticipants} participants',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (event.isFull) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Complet',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (event.isFeatured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: event.isFree
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        event.formattedPrice,
        style: TextStyle(
          color: event.isFree ? Colors.green : theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui a ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Demain a ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month} a ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Bottom sheet des filtres
class _FiltersSheet extends StatefulWidget {
  final double currentRadius;
  final Function(double) onRadiusChanged;

  const _FiltersSheet({
    required this.currentRadius,
    required this.onRadiusChanged,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late double _radius;
  bool _showFreeOnly = false;
  bool _showAvailableOnly = false;

  @override
  void initState() {
    super.initState();
    _radius = widget.currentRadius;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          // Rayon de recherche
          Text(
            'Rayon de recherche: ${_radius.toInt()} km',
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _radius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_radius.toInt()} km',
            onChanged: (value) {
              setState(() {
                _radius = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Filtres supplementaires
          SwitchListTile(
            title: const Text('Evenements gratuits uniquement'),
            value: _showFreeOnly,
            onChanged: (value) {
              setState(() {
                _showFreeOnly = value;
              });
            },
          ),

          SwitchListTile(
            title: const Text('Places disponibles uniquement'),
            value: _showAvailableOnly,
            onChanged: (value) {
              setState(() {
                _showAvailableOnly = value;
              });
            },
          ),

          const SizedBox(height: 24),

          // Bouton appliquer
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onRadiusChanged(_radius),
              child: const Text('Appliquer'),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
