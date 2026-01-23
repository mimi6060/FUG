import 'dart:async';
import 'dart:math' as math;

import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/appwrite_service.dart';
import '../../../core/config/appwrite_config.dart';
import '../domain/event_model.dart';

/// Exception personnalisée pour les événements
class EventException implements Exception {
  final String message;
  final int? code;

  EventException(this.message, {this.code});

  @override
  String toString() => 'EventException: $message';
}

/// Repository pour la gestion des événements
///
/// Gère toutes les opérations CRUD sur les événements
/// ainsi que les requêtes géolocalisées.
class EventRepository {
  final AppwriteService _appwrite;

  EventRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Databases get _databases => _appwrite.databases;

  // ============================================
  // Opérations CRUD
  // ============================================

  /// Crée un nouvel événement
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required String organizerId,
    required String organizerName,
    String? locationType,
    String? imageUrl,
    List<String>? additionalImages,
    required String address,
    required double latitude,
    required double longitude,
    String? venueName,
    required DateTime startDate,
    required DateTime endDate,
    int? maxParticipants,
    List<String>? tags,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'creatorId': organizerId,
        'title': title,
        'description': description,
        'status': EventStatus.published.value,
        if (locationType != null) 'category': locationType, // Location type (optional)
        'maxParticipants': maxParticipants ?? 0,
        'participantCount': 0,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'imageUrl': imageUrl,
        'locationLat': latitude,
        'locationLng': longitude,
        'locationName': venueName ?? address,
        'locationAddress': address,
        'isOnline': false,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: ID.unique(),
        data: data,
        permissions: [
          Permission.read(Role.any()),
          Permission.update(Role.user(organizerId)),
          Permission.delete(Role.user(organizerId)),
        ],
      );

      return EventModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la création de l\'événement.',
        code: e.code,
      );
    }
  }

  /// Récupère un événement par son ID
  Future<EventModel?> getEvent(String eventId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
      );
      return EventModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw EventException(
        e.message ?? 'Erreur lors de la récupération de l\'événement.',
        code: e.code,
      );
    }
  }

  /// Met à jour un événement
  Future<EventModel> updateEvent({
    required String eventId,
    String? title,
    String? description,
    String? locationType,
    String? imageUrl,
    List<String>? additionalImages,
    String? address,
    double? latitude,
    double? longitude,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    List<String>? tags,
    EventStatus? status,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (locationType != null) data['category'] = locationType;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (address != null) data['locationAddress'] = address;
      if (latitude != null) data['locationLat'] = latitude;
      if (longitude != null) data['locationLng'] = longitude;
      if (venueName != null) data['locationName'] = venueName;
      if (startDate != null) data['startDate'] = startDate.toIso8601String();
      if (endDate != null) data['endDate'] = endDate.toIso8601String();
      if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
      if (status != null) data['status'] = status.value;

      final doc = await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
        data: data,
      );

      return EventModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la mise à jour de l\'événement.',
        code: e.code,
      );
    }
  }

  /// Supprime un événement
  Future<void> deleteEvent(String eventId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la suppression de l\'événement.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Requêtes de liste
  // ============================================

  /// Liste tous les événements avec pagination
  Future<List<EventModel>> listEvents({
    int limit = 25,
    int offset = 0,
    String? locationType,
    EventStatus? status,
    bool? isFeatured,
    String? orderBy,
    bool descending = true,
  }) async {
    try {
      final queries = <String>[
        Query.limit(limit),
        Query.offset(offset),
      ];

      if (locationType != null) {
        queries.add(Query.equal('category', locationType));
      }

      if (status != null) {
        queries.add(Query.equal('status', status.value));
      } else {
        // Par défaut, ne montrer que les événements publiés
        queries.add(Query.equal('status', EventStatus.published.value));
      }

      if (isFeatured != null) {
        queries.add(Query.equal('isFeatured', isFeatured));
      }

      // Tri
      if (orderBy != null) {
        queries.add(
          descending ? Query.orderDesc(orderBy) : Query.orderAsc(orderBy),
        );
      } else {
        queries.add(Query.orderAsc('startDate'));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        queries: queries,
      );

      return result.documents
          .map((doc) => EventModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la récupération des événements.',
        code: e.code,
      );
    }
  }

  /// Liste les événements à venir
  Future<List<EventModel>> getUpcomingEvents({
    int limit = 25,
    String? locationType,
  }) async {
    try {
      final queries = <String>[
        Query.limit(limit),
        Query.equal('status', EventStatus.published.value),
        Query.greaterThan('startDate', DateTime.now().toIso8601String()),
        Query.orderAsc('startDate'),
      ];

      if (locationType != null) {
        queries.add(Query.equal('category', locationType));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        queries: queries,
      );

      return result.documents
          .map((doc) => EventModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la récupération des événements.',
        code: e.code,
      );
    }
  }

  /// Liste les événements d'un organisateur
  Future<List<EventModel>> getEventsByOrganizer(
    String organizerId, {
    int limit = 25,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        queries: [
          Query.equal('creatorId', organizerId),
          Query.limit(limit),
          Query.orderDesc('createdAt'),
        ],
      );

      return result.documents
          .map((doc) => EventModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la récupération des événements.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Requêtes géolocalisées
  // ============================================

  /// Calcule les bornes d'une zone rectangulaire autour d'un point
  /// pour un rayon donné en kilomètres
  Map<String, double> _calculateBoundingBox({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    // Approximation: 1 degré de latitude = 111 km
    // 1 degré de longitude = 111 km * cos(latitude)
    const double kmPerDegreeLat = 111.0;
    final double kmPerDegreeLon = 111.0 * math.cos(latitude * math.pi / 180);

    final double latDelta = radiusKm / kmPerDegreeLat;
    final double lonDelta = radiusKm / kmPerDegreeLon;

    return {
      'minLat': latitude - latDelta,
      'maxLat': latitude + latDelta,
      'minLon': longitude - lonDelta,
      'maxLon': longitude + lonDelta,
    };
  }

  /// Calcule la distance entre deux points en kilomètres (formule Haversine)
  double _calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadius = 6371; // km

    final double dLat = (lat2 - lat1) * math.pi / 180;
    final double dLon = (lon2 - lon1) * math.pi / 180;

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Recherche les événements dans un rayon autour d'une position
  ///
  /// Utilise une approche en deux étapes:
  /// 1. Filtrage par bounding box dans Appwrite
  /// 2. Filtrage précis par distance en mémoire
  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 50,
    String? locationType,
    DateTime? afterDate,
  }) async {
    try {
      // Calculer la bounding box
      final bounds = _calculateBoundingBox(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      // Construire les requêtes
      final queries = <String>[
        Query.equal('status', EventStatus.published.value),
        Query.greaterThanEqual('locationLat', bounds['minLat']!),
        Query.lessThanEqual('locationLat', bounds['maxLat']!),
        Query.greaterThanEqual('locationLng', bounds['minLon']!),
        Query.lessThanEqual('locationLng', bounds['maxLon']!),
        Query.limit(limit * 2), // Marge pour le filtrage par distance
      ];

      if (locationType != null) {
        queries.add(Query.equal('category', locationType));
      }

      if (afterDate != null) {
        queries.add(Query.greaterThan('startDate', afterDate.toIso8601String()));
      } else {
        queries.add(Query.greaterThan('startDate', DateTime.now().toIso8601String()));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        queries: queries,
      );

      // Filtrer par distance exacte et trier
      final events = result.documents
          .map((doc) => EventModel.fromJson(doc.data))
          .where((event) {
            final distance = _calculateDistance(
              lat1: latitude,
              lon1: longitude,
              lat2: event.latitude,
              lon2: event.longitude,
            );
            return distance <= radiusKm;
          })
          .toList();

      // Trier par distance
      events.sort((a, b) {
        final distA = _calculateDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: a.latitude,
          lon2: a.longitude,
        );
        final distB = _calculateDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: b.latitude,
          lon2: b.longitude,
        );
        return distA.compareTo(distB);
      });

      return events.take(limit).toList();
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la recherche géolocalisée.',
        code: e.code,
      );
    }
  }

  /// Recherche les événements par texte
  Future<List<EventModel>> searchEvents({
    required String query,
    int limit = 25,
    String? locationType,
  }) async {
    try {
      final queries = <String>[
        Query.equal('status', EventStatus.published.value),
        Query.search('title', query),
        Query.limit(limit),
      ];

      if (locationType != null) {
        queries.add(Query.equal('category', locationType));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        queries: queries,
      );

      return result.documents
          .map((doc) => EventModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la recherche.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Gestion des participants
  // ============================================

  /// Incrémente le nombre de participants
  Future<void> incrementParticipants(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventException('Événement non trouvé.', code: 404);
      }

      if (event.isFull) {
        throw EventException('Cet événement est complet.', code: 400);
      }

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
        data: {
          'participantCount': event.currentParticipants + 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de l\'inscription.',
        code: e.code,
      );
    }
  }

  /// Decremente le nombre de participants
  Future<void> decrementParticipants(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventException('Evenement non trouve.', code: 404);
      }

      if (event.currentParticipants <= 0) return;

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
        data: {
          'participantCount': event.currentParticipants - 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la desinscription.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Annulation
  // ============================================

  /// Annule la participation d'un utilisateur a un evenement
  ///
  /// Appelle la fonction Appwrite cancel-participation qui:
  /// - Met a jour le statut de participation a 'cancelled'
  /// - Decremente le compteur de participants
  /// - Notifie l'organisateur
  Future<void> cancelParticipation({
    required String userId,
    required String eventId,
  }) async {
    try {
      await _appwrite.functions.createExecution(
        functionId: 'cancel-participation',
        body: '{"userId": "$userId", "eventId": "$eventId"}',
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de l\'annulation de la participation.',
        code: e.code,
      );
    }
  }

  /// Annule un evenement (organisateur uniquement)
  ///
  /// Appelle la fonction Appwrite cancel-event qui:
  /// - Met a jour le statut de l'evenement a 'cancelled'
  /// - Met a jour tous les participants a 'cancelled'
  /// - Notifie tous les participants
  Future<void> cancelEvent({
    required String eventId,
    required String organizerId,
    String? reason,
  }) async {
    try {
      final body = reason != null
          ? '{"eventId": "$eventId", "organizerId": "$organizerId", "reason": "$reason"}'
          : '{"eventId": "$eventId", "organizerId": "$organizerId"}';

      await _appwrite.functions.createExecution(
        functionId: 'cancel-event',
        body: body,
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de l\'annulation de l\'evenement.',
        code: e.code,
      );
    }
  }

  /// Verifie si un utilisateur participe a un evenement
  Future<bool> isUserParticipating({
    required String userId,
    required String eventId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'event_participants',
        queries: [
          Query.equal('userId', userId),
          Query.equal('eventId', eventId),
          Query.equal('status', 'confirmed'),
        ],
      );
      return result.documents.isNotEmpty;
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la verification de participation.',
        code: e.code,
      );
    }
  }

  /// Recupere le statut de participation d'un utilisateur
  Future<String?> getParticipationStatus({
    required String userId,
    required String eventId,
  }) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: 'event_participants',
        queries: [
          Query.equal('userId', userId),
          Query.equal('eventId', eventId),
          Query.limit(1),
        ],
      );
      if (result.documents.isEmpty) return null;
      return result.documents.first.data['status'] as String?;
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la recuperation du statut.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Realtime
  // ============================================

  /// S'abonne aux changements d'un événement spécifique
  /// Returns a record containing both the RealtimeSubscription (for closing)
  /// and the StreamSubscription (for canceling the listener)
  ({RealtimeSubscription subscription, StreamSubscription<RealtimeMessage> listener}) subscribeToEvent({
    required String eventId,
    required Function(EventModel) onUpdate,
    Function()? onDelete,
  }) {
    final channel =
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.eventsCollectionId}.documents.$eventId';

    final subscription = _appwrite.realtime.subscribe([channel]);
    final listener = subscription.stream.listen((response) {
      if (kDebugMode) {
        print('Realtime event: ${response.events}');
      }

      if (response.events.any((e) => e.contains('.delete'))) {
        onDelete?.call();
      } else {
        final event = EventModel.fromJson(response.payload);
        onUpdate(event);
      }
    });

    return (subscription: subscription, listener: listener);
  }

  /// S'abonne aux nouveaux événements dans une zone
  /// Returns a record containing both the RealtimeSubscription (for closing)
  /// and the StreamSubscription (for canceling the listener)
  ({RealtimeSubscription subscription, StreamSubscription<RealtimeMessage> listener}) subscribeToNearbyEvents({
    required Function(EventModel) onNewEvent,
  }) {
    final channel = AppwriteConfig.eventsChannel;

    final subscription = _appwrite.realtime.subscribe([channel]);
    final listener = subscription.stream.listen((response) {
      if (response.events.any((e) => e.contains('.create'))) {
        final event = EventModel.fromJson(response.payload);
        onNewEvent(event);
      }
    });

    return (subscription: subscription, listener: listener);
  }
}
