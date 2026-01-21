import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/location_provider.dart';
import '../../../core/providers/events_provider.dart';
import '../domain/event_model.dart';

/// Ecran principal avec la carte OpenStreetMap affichant les evenements
class EventsMapScreen extends ConsumerStatefulWidget {
  const EventsMapScreen({super.key});

  @override
  ConsumerState<EventsMapScreen> createState() => _EventsMapScreenState();
}

class _EventsMapScreenState extends ConsumerState<EventsMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _error;

  // Position par defaut (Paris)
  static const LatLng _defaultPosition = LatLng(48.8566, 2.3522);
  LatLng _currentPosition = _defaultPosition;

  // Rayon de recherche en km
  double _searchRadius = 10.0;

  // Evenement selectionne pour la bottom sheet
  EventModel? _selectedEvent;

  // Liste des evenements pour reference
  List<EventModel> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await ref.read(currentPositionProvider.future);
      if (position != null) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
      await _loadNearbyEvents();
    } catch (e) {
      setState(() {
        _error = 'Erreur de localisation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final events = await ref.read(nearbyEventsProvider(
        NearbyEventsParams(
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
          radiusKm: _searchRadius,
        ),
      ).future);

      _events = events;
      _updateMarkers(events);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _updateMarkers(List<EventModel> events) {
    final newMarkers = <Marker>[];

    for (final event in events) {
      newMarkers.add(
        Marker(
          point: LatLng(event.latitude, event.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(event),
            child: Container(
              decoration: BoxDecoration(
                color: _getMarkerColor(event),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_bar,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  Color _getMarkerColor(EventModel event) {
    if (event.isFeatured) return Colors.amber;
    if (event.isFree) return Colors.green;
    if (event.isFull) return Colors.red;
    return Colors.deepPurple;
  }

  void _onMarkerTapped(EventModel event) {
    setState(() {
      _selectedEvent = event;
    });
    _showEventBottomSheet(event);
  }

  void _showEventBottomSheet(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventPreviewSheet(
        event: event,
        onViewDetails: () {
          Navigator.pop(context);
          context.push('/events/${event.id}');
        },
      ),
    );
  }

  Future<void> _centerOnUser() async {
    final position = await ref.read(currentPositionProvider.future);
    if (position != null) {
      final newPosition = LatLng(position.latitude, position.longitude);
      _mapController.move(newPosition, 14);
      setState(() {
        _currentPosition = newPosition;
      });
      await _loadNearbyEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FUG'),
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
      body: Stack(
        children: [
          // Carte OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentPosition = position.center!;
                  });
                }
              },
              onMapEvent: (event) {
                // Recharger les evenements quand l'utilisateur arrete de bouger la carte
                if (event is MapEventMoveEnd) {
                  _loadNearbyEvents();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: isDarkMode
                    ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fug.app',
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),

          // Indicateur de chargement
          if (_isLoading)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Chargement...'),
                    ],
                  ),
                ),
              ),
            ),

          // Message d'erreur
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!)),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadNearbyEvents,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Indicateur du nombre d'evenements
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '${_markers.length} FUG${_markers.length > 1 ? 's' : ''} a proximite',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Slider de rayon
          Positioned(
            bottom: 100,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${_searchRadius.toInt()} km',
                    style: theme.textTheme.bodySmall,
                  ),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: _searchRadius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _loadNearbyEvents();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton de centrage sur l'utilisateur
          FloatingActionButton.small(
            heroTag: 'center',
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          // Bouton de creation d'evenement
          FloatingActionButton.extended(
            heroTag: 'create',
            onPressed: () => context.push('/events/create'),
            icon: const Icon(Icons.add),
            label: const Text('Creer un FUG'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              // Deja sur la carte
              break;
            case 1:
              context.push('/events');
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

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FiltersSheet(
        currentRadius: _searchRadius,
        onRadiusChanged: (radius) {
          setState(() {
            _searchRadius = radius;
          });
          _loadNearbyEvents();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

/// Bottom sheet de previsualisation d'un evenement
class _EventPreviewSheet extends StatelessWidget {
  final EventModel event;
  final VoidCallback onViewDetails;

  const _EventPreviewSheet({
    required this.event,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image de l'evenement
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et prix
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event.isFree
                            ? Colors.green.withOpacity(0.1)
                            : theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.formattedPrice,
                        style: TextStyle(
                          color: event.isFree
                              ? Colors.green
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Date et lieu
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
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 4),

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
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

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
                          ? '${event.currentParticipants}/${event.maxParticipants} participants'
                          : '${event.currentParticipants} participants',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (event.isFull)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
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
                ),

                const SizedBox(height: 16),

                // Bouton voir les details
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onViewDetails,
                    child: const Text('Voir les details'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
