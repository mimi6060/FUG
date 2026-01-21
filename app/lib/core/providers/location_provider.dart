import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Exception pour les erreurs de localisation
class LocationException implements Exception {
  final String message;
  final String? code;

  LocationException(this.message, {this.code});

  @override
  String toString() => 'LocationException: $message';
}

/// Service de gestion de la localisation
class LocationService {
  /// Verifie si les services de localisation sont actives
  Future<bool> isLocationServiceEnabled() async {
    // On web, isLocationServiceEnabled always returns true since the browser
    // handles location services differently. The actual availability is
    // determined when requesting permission or getting position.
    if (kIsWeb) {
      return true;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Demande les permissions de localisation
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Verifie si les permissions sont accordees
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Obtient la position actuelle
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Les services de localisation sont desactives.',
        code: 'SERVICE_DISABLED',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException(
          'Permission de localisation refusee.',
          code: 'PERMISSION_DENIED',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permission de localisation refusee definitivement. '
        'Veuillez l\'activer dans les parametres.',
        code: 'PERMISSION_DENIED_FOREVER',
      );
    }

    // On web, we need longer timeout since the browser
    // handles location services differently
    if (kIsWeb) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    }

    // On mobile platforms, use standard settings
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Obtient la derniere position connue (plus rapide)
  /// Note: Cette methode n'est pas supportee sur le web et retourne null
  Future<Position?> getLastKnownPosition() async {
    // getLastKnownPosition is not supported on the web platform
    if (kIsWeb) {
      return null;
    }
    return await Geolocator.getLastKnownPosition();
  }

  /// Stream des changements de position
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calcule la distance entre deux points en metres
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calcule le bearing entre deux points
  double calculateBearing({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Ouvre les parametres de localisation de l'appareil
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Ouvre les parametres de l'application
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Provider pour le service de localisation
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider pour la position actuelle
final currentPositionProvider = FutureProvider<Position?>((ref) async {
  final service = ref.watch(locationServiceProvider);

  try {
    // Sur le web, getLastKnownPosition n'est pas supporte
    // On utilise directement getCurrentPosition
    if (kIsWeb) {
      if (kDebugMode) {
        print('Web platform detected - calling getCurrentPosition directly');
      }
      final position = await service.getCurrentPosition();
      if (kDebugMode) {
        print('Web position obtained: ${position.latitude}, ${position.longitude}');
      }
      return position;
    }

    // Sur mobile, essayer d'abord la derniere position connue (plus rapide)
    try {
      final lastPosition = await service.getLastKnownPosition();
      if (lastPosition != null) {
        // Retourner la derniere position et rafraichir en arriere-plan
        _refreshPositionInBackground(ref);
        return lastPosition;
      }
    } catch (e) {
      // getLastKnownPosition peut echouer, continuer avec getCurrentPosition
      if (kDebugMode) {
        print('getLastKnownPosition failed: $e');
      }
    }

    // Obtenir la position actuelle
    return await service.getCurrentPosition();
  } on LocationException catch (e) {
    // Re-throw LocationException so the UI can handle it properly
    if (kDebugMode) {
      print('LocationException: ${e.message} (code: ${e.code})');
    }
    rethrow;
  } catch (e) {
    if (kDebugMode) {
      print('Error getting current position: $e');
    }
    // Re-throw so the UI layer can display the error
    rethrow;
  }
});

/// Rafraichit la position en arriere-plan
Future<void> _refreshPositionInBackground(FutureProviderRef<Position?> ref) async {
  try {
    final service = ref.read(locationServiceProvider);
    await service.getCurrentPosition();
    // La prochaine lecture du provider aura la position a jour
  } catch (e) {
    // Ignorer les erreurs en arriere-plan
  }
}

/// Provider pour le stream de position
final positionStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getPositionStream();
});

/// Provider pour le statut des permissions de localisation
final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  return await Geolocator.checkPermission();
});

/// Provider pour savoir si la localisation est disponible
final isLocationAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(locationServiceProvider);

  final serviceEnabled = await service.isLocationServiceEnabled();
  if (!serviceEnabled) return false;

  final hasPermission = await service.hasPermission();
  return hasPermission;
});

/// Etat de la localisation utilisateur
class LocationState {
  final Position? position;
  final bool isLoading;
  final String? error;
  final bool permissionDenied;

  const LocationState({
    this.position,
    this.isLoading = false,
    this.error,
    this.permissionDenied = false,
  });

  LocationState copyWith({
    Position? position,
    bool? isLoading,
    String? error,
    bool? permissionDenied,
  }) {
    return LocationState(
      position: position ?? this.position,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

/// Provider pour l'etat de la localisation avec gestion des erreurs
final locationStateProvider =
    StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  return LocationStateNotifier(ref);
});

/// Notifier pour l'etat de la localisation
class LocationStateNotifier extends StateNotifier<LocationState> {
  final Ref _ref;

  LocationStateNotifier(this._ref) : super(const LocationState());

  LocationService get _service => _ref.read(locationServiceProvider);

  /// Initialise la localisation
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _service.getCurrentPosition();
      state = state.copyWith(
        position: position,
        isLoading: false,
        permissionDenied: false,
      );
    } on LocationException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        permissionDenied: e.code == 'PERMISSION_DENIED' ||
            e.code == 'PERMISSION_DENIED_FOREVER',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la recuperation de la position.',
      );
    }
  }

  /// Rafraichit la position
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    try {
      final position = await _service.getCurrentPosition();
      state = state.copyWith(
        position: position,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Impossible de mettre a jour la position.',
      );
    }
  }

  /// Demande les permissions
  Future<bool> requestPermission() async {
    try {
      final permission = await _service.requestPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (granted) {
        await initialize();
      } else {
        state = state.copyWith(
          permissionDenied: true,
          error: 'Permission de localisation refusee.',
        );
      }

      return granted;
    } catch (e) {
      state = state.copyWith(error: 'Erreur lors de la demande de permission.');
      return false;
    }
  }

  /// Ouvre les parametres de l'application
  Future<void> openSettings() async {
    await _service.openAppSettings();
  }
}
