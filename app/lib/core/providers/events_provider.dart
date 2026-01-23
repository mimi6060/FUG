import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/events/data/event_repository.dart';
import '../../features/events/domain/event_model.dart';

/// Provider pour le repository des evenements
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Parametres pour la recherche d'evenements a proximite
class NearbyEventsParams {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final String? locationType;

  const NearbyEventsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
    this.locationType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NearbyEventsParams &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          radiusKm == other.radiusKm &&
          locationType == other.locationType;

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      radiusKm.hashCode ^
      locationType.hashCode;
}

/// Provider pour les evenements a proximite
final nearbyEventsProvider =
    FutureProvider.family<List<EventModel>, NearbyEventsParams>((
  ref,
  params,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getNearbyEvents(
    latitude: params.latitude,
    longitude: params.longitude,
    radiusKm: params.radiusKm,
    locationType: params.locationType,
  );
});

/// Provider pour le detail d'un evenement
final eventDetailProvider =
    FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEvent(eventId);
});

/// Provider pour les evenements a venir
final upcomingEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getUpcomingEvents();
});

/// Provider pour les evenements d'un organisateur
final organizerEventsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, organizerId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventsByOrganizer(organizerId);
});

/// Provider pour les evenements filtres par categorie
final categoryEventsProvider =
    FutureProvider.family<List<EventModel>, String?>((ref, locationType) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.listEvents(locationType: locationType);
});

/// Provider pour la recherche d'evenements
final searchEventsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(eventRepositoryProvider);
  return repository.searchEvents(query: query);
});

/// Provider pour les evenements mis en avant
final featuredEventsProvider =
    FutureProvider.autoDispose<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.listEvents(isFeatured: true, limit: 10);
});

/// Etat de creation d'evenement
class CreateEventState {
  final bool isLoading;
  final String? error;
  final EventModel? createdEvent;

  const CreateEventState({
    this.isLoading = false,
    this.error,
    this.createdEvent,
  });

  CreateEventState copyWith({
    bool? isLoading,
    String? error,
    EventModel? createdEvent,
  }) {
    return CreateEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdEvent: createdEvent ?? this.createdEvent,
    );
  }
}

/// Provider pour l'etat de creation d'evenement
final createEventProvider =
    StateNotifierProvider<CreateEventNotifier, CreateEventState>((ref) {
  return CreateEventNotifier(ref);
});

/// Notifier pour la creation d'evenement
class CreateEventNotifier extends StateNotifier<CreateEventState> {
  final Ref _ref;

  CreateEventNotifier(this._ref) : super(const CreateEventState());

  EventRepository get _repository => _ref.read(eventRepositoryProvider);

  Future<EventModel?> create({
    required String title,
    required String description,
    required String organizerId,
    required String organizerName,
    String? locationType,
    String? imageUrl,
    required String address,
    required double latitude,
    required double longitude,
    String? venueName,
    required DateTime startDate,
    required DateTime endDate,
    int? maxParticipants,
    List<String>? tags,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final event = await _repository.createEvent(
        title: title,
        description: description,
        organizerId: organizerId,
        organizerName: organizerName,
        locationType: locationType,
        imageUrl: imageUrl,
        address: address,
        latitude: latitude,
        longitude: longitude,
        venueName: venueName,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        tags: tags,
      );

      state = state.copyWith(isLoading: false, createdEvent: event);
      return event;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = const CreateEventState();
  }
}

/// Provider pour le statut de participation a un evenement
final participationStatusProvider =
    FutureProvider.family<bool, ({String eventId, String userId})>((
  ref,
  params,
) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.isUserParticipating(
    userId: params.userId,
    eventId: params.eventId,
  );
});

/// Provider pour les evenements auxquels l'utilisateur participe
final myParticipationsProvider =
    FutureProvider.family<List<EventModel>, String>((ref, userId) async {
  // TODO: Implementer la recuperation des participations
  return [];
});

// ============================================
// Annulation
// ============================================

/// Etat d'annulation de participation
class CancelParticipationState {
  final bool isLoading;
  final String? error;
  final bool success;

  const CancelParticipationState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  CancelParticipationState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return CancelParticipationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Provider pour l'annulation de participation
final cancelParticipationProvider =
    StateNotifierProvider<CancelParticipationNotifier, CancelParticipationState>(
        (ref) {
  return CancelParticipationNotifier(ref);
});

/// Notifier pour l'annulation de participation
class CancelParticipationNotifier
    extends StateNotifier<CancelParticipationState> {
  final Ref _ref;

  CancelParticipationNotifier(this._ref)
      : super(const CancelParticipationState());

  EventRepository get _repository => _ref.read(eventRepositoryProvider);

  /// Annule la participation a un evenement
  Future<bool> cancel({
    required String userId,
    required String eventId,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    try {
      await _repository.cancelParticipation(
        userId: userId,
        eventId: eventId,
      );

      state = state.copyWith(isLoading: false, success: true);

      // Invalider les providers lies
      _ref.invalidate(eventDetailProvider(eventId));
      _ref.invalidate(
          participationStatusProvider((eventId: eventId, userId: userId)));

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const CancelParticipationState();
  }
}

/// Etat d'annulation d'evenement
class CancelEventState {
  final bool isLoading;
  final String? error;
  final bool success;

  const CancelEventState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  CancelEventState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return CancelEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Provider pour l'annulation d'evenement
final cancelEventProvider =
    StateNotifierProvider<CancelEventNotifier, CancelEventState>((ref) {
  return CancelEventNotifier(ref);
});

/// Notifier pour l'annulation d'evenement
class CancelEventNotifier extends StateNotifier<CancelEventState> {
  final Ref _ref;

  CancelEventNotifier(this._ref) : super(const CancelEventState());

  EventRepository get _repository => _ref.read(eventRepositoryProvider);

  /// Annule un evenement (organisateur uniquement)
  Future<bool> cancel({
    required String eventId,
    required String organizerId,
    String? reason,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    try {
      await _repository.cancelEvent(
        eventId: eventId,
        organizerId: organizerId,
        reason: reason,
      );

      state = state.copyWith(isLoading: false, success: true);

      // Invalider les providers lies
      _ref.invalidate(eventDetailProvider(eventId));
      _ref.invalidate(upcomingEventsProvider);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const CancelEventState();
  }
}
