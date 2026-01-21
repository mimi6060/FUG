import 'dart:async';
import 'package:flutter/foundation.dart';
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

  bool _locationInitialized = false;

  // Track if map controller is ready
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    // Delay initialization to ensure the map is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  Future<void> _initializeLocation() async {
    if (kDebugMode) {
      print('_initializeLocation started');
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (kDebugMode) {
        print('Calling currentPositionProvider...');
      }
      final position = await ref.read(currentPositionProvider.future);
      if (kDebugMode) {
        print('Position received: $position');
      }
      if (position != null && mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        if (kDebugMode) {
          print('Moving map to: $newPosition');
        }
        setState(() {
          _currentPosition = newPosition;
          _locationInitialized = true;
        });
        // Move the map to the user's position
        _mapController.move(newPosition, 13);
      } else if (mounted) {
        if (kDebugMode) {
          print('Position is null - using default position');
        }
        // Position is null, show a message but continue with default position
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position non disponible. Affichage de la position par defaut.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on LocationException catch (e) {
      if (kDebugMode) {
        print('LocationException in _initializeLocation: ${e.message} (code: ${e.code})');
      }
      if (mounted) {
        String message = e.message;
        // Provide additional guidance for permission issues on web
        if (kIsWeb) {
          if (e.code == 'PERMISSION_DENIED') {
            message = 'Permission de localisation refusee. Cliquez sur l\'icone cadenas dans la barre d\'adresse pour autoriser la localisation.';
          } else if (e.code == 'PERMISSION_DENIED_FOREVER') {
            message = 'Permission de localisation bloquee. Modifiez les parametres de votre navigateur pour autoriser la localisation pour ce site.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reessayer',
              onPressed: () {
                ref.invalidate(currentPositionProvider);
                _initializeLocation();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _initializeLocation: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Reessayer',
              onPressed: () {
                ref.invalidate(currentPositionProvider);
                _initializeLocation();
              },
            ),
          ),
        );
      }
    }

    // Always load nearby events, even if location failed (use default position)
    if (mounted) {
      await _loadNearbyEvents();
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

  bool _isCentering = false;

  Future<void> _centerOnUser() async {
    if (_isCentering) return;

    setState(() {
      _isCentering = true;
    });

    try {
      // Invalidate the provider to get fresh position
      ref.invalidate(currentPositionProvider);
      final position = await ref.read(currentPositionProvider.future);

      if (position != null && mounted) {
        final newPosition = LatLng(position.latitude, position.longitude);
        _mapController.move(newPosition, 14);
        setState(() {
          _currentPosition = newPosition;
          _isCentering = false;
        });
        await _loadNearbyEvents();
      } else if (mounted) {
        setState(() {
          _isCentering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'obtenir votre position. Verifiez vos permissions de localisation.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on LocationException catch (e) {
      if (mounted) {
        setState(() {
          _isCentering = false;
        });
        String message = e.message;
        // Provide additional guidance for permission issues on web
        if (e.code == 'PERMISSION_DENIED') {
          message = 'Permission de localisation refusee. Cliquez sur l\'icone cadenas dans la barre d\'adresse pour autoriser.';
        } else if (e.code == 'PERMISSION_DENIED_FOREVER') {
          message = 'Permission de localisation bloquee. Modifiez les parametres de votre navigateur pour autoriser la localisation.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 5),
            action: e.code == 'PERMISSION_DENIED_FOREVER'
                ? SnackBarAction(
                    label: 'Parametres',
                    onPressed: () {
                      ref.read(locationServiceProvider).openAppSettings();
                    },
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCentering = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de localisation: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _zoomIn() {
    if (kDebugMode) {
      print('_zoomIn called, mapReady: $_mapReady');
    }
    if (!_mapReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte en cours de chargement...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    try {
      final camera = _mapController.camera;
      final currentZoom = camera.zoom;
      final newZoom = (currentZoom + 1).clamp(1.0, 18.0);
      if (kDebugMode) {
        print('Current zoom: $currentZoom, new zoom: $newZoom');
      }
      _mapController.move(camera.center, newZoom);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zoom: ${newZoom.toStringAsFixed(1)}x'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 150, left: 16, right: 16),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Zoom in failed: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de zoom: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _zoomOut() {
    if (kDebugMode) {
      print('_zoomOut called, mapReady: $_mapReady');
    }
    if (!_mapReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carte en cours de chargement...'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    try {
      final camera = _mapController.camera;
      final currentZoom = camera.zoom;
      final newZoom = (currentZoom - 1).clamp(1.0, 18.0);
      if (kDebugMode) {
        print('Current zoom: $currentZoom, new zoom: $newZoom');
      }
      _mapController.move(camera.center, newZoom);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zoom: ${newZoom.toStringAsFixed(1)}x'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 150, left: 16, right: 16),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Zoom out failed: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de zoom: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
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
              onMapReady: () {
                setState(() {
                  _mapReady = true;
                });
                if (kDebugMode) {
                  print('Map is ready');
                }
              },
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_searchRadius.toInt()} km',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  RotatedBox(
                    quarterTurns: 3,
                    child: SizedBox(
                      width: 150, // Fixed width for slider track length
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                        ),
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
          // Boutons de zoom
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: _zoomIn,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            onPressed: _zoomOut,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          // Bouton de centrage sur l'utilisateur
          FloatingActionButton.small(
            heroTag: 'center',
            onPressed: _isCentering ? null : _centerOnUser,
            child: _isCentering
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
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
              context.go('/events');
              break;
            case 2:
              context.go('/notifications');
              break;
            case 3:
              context.go('/profile');
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
