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
    required String categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? additionalImages,
    required String address,
    required double latitude,
    required double longitude,
    String? venueName,
    required DateTime startDate,
    required DateTime endDate,
    int? maxParticipants,
    int price = 0,
    String currency = 'EUR',
    List<String>? tags,
  }) async {
    try {
      final now = DateTime.now();
      final data = {
        'title': title,
        'description': description,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'additionalImages': additionalImages ?? [],
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'venueName': venueName,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'maxParticipants': maxParticipants,
        'currentParticipants': 0,
        'price': price,
        'currency': currency,
        'tags': tags ?? [],
        'status': EventStatus.published.value,
        'isFeatured': false,
        'rating': 0.0,
        'reviewCount': 0,
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
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? additionalImages,
    String? address,
    double? latitude,
    double? longitude,
    String? venueName,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? price,
    String? currency,
    List<String>? tags,
    EventStatus? status,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (categoryId != null) data['categoryId'] = categoryId;
      if (categoryName != null) data['categoryName'] = categoryName;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      if (additionalImages != null) data['additionalImages'] = additionalImages;
      if (address != null) data['address'] = address;
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (venueName != null) data['venueName'] = venueName;
      if (startDate != null) data['startDate'] = startDate.toIso8601String();
      if (endDate != null) data['endDate'] = endDate.toIso8601String();
      if (maxParticipants != null) data['maxParticipants'] = maxParticipants;
      if (price != null) data['price'] = price;
      if (currency != null) data['currency'] = currency;
      if (tags != null) data['tags'] = tags;
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
    String? categoryId,
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

      if (categoryId != null) {
        queries.add(Query.equal('categoryId', categoryId));
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
    String? categoryId,
  }) async {
    try {
      final queries = <String>[
        Query.limit(limit),
        Query.equal('status', EventStatus.published.value),
        Query.greaterThan('startDate', DateTime.now().toIso8601String()),
        Query.orderAsc('startDate'),
      ];

      if (categoryId != null) {
        queries.add(Query.equal('categoryId', categoryId));
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
          Query.equal('organizerId', organizerId),
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
    String? categoryId,
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
        Query.greaterThanEqual('latitude', bounds['minLat']!),
        Query.lessThanEqual('latitude', bounds['maxLat']!),
        Query.greaterThanEqual('longitude', bounds['minLon']!),
        Query.lessThanEqual('longitude', bounds['maxLon']!),
        Query.limit(limit * 2), // Marge pour le filtrage par distance
      ];

      if (categoryId != null) {
        queries.add(Query.equal('categoryId', categoryId));
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
    String? categoryId,
  }) async {
    try {
      final queries = <String>[
        Query.equal('status', EventStatus.published.value),
        Query.search('title', query),
        Query.limit(limit),
      ];

      if (categoryId != null) {
        queries.add(Query.equal('categoryId', categoryId));
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
          'currentParticipants': event.currentParticipants + 1,
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

  /// Décrémente le nombre de participants
  Future<void> decrementParticipants(String eventId) async {
    try {
      final event = await getEvent(eventId);
      if (event == null) {
        throw EventException('Événement non trouvé.', code: 404);
      }

      if (event.currentParticipants <= 0) return;

      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.eventsCollectionId,
        documentId: eventId,
        data: {
          'currentParticipants': event.currentParticipants - 1,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw EventException(
        e.message ?? 'Erreur lors de la désinscription.',
        code: e.code,
      );
    }
  }

  // ============================================
  // Realtime
  // ============================================

  /// S'abonne aux changements d'un événement spécifique
  RealtimeSubscription subscribeToEvent({
    required String eventId,
    required Function(EventModel) onUpdate,
    Function()? onDelete,
  }) {
    final channel =
        'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.eventsCollectionId}.documents.$eventId';

    return _appwrite.realtime.subscribe([channel]).stream.listen((response) {
      if (kDebugMode) {
        print('Realtime event: ${response.events}');
      }

      if (response.events.any((e) => e.contains('.delete'))) {
        onDelete?.call();
      } else {
        final event = EventModel.fromJson(response.payload);
        onUpdate(event);
      }
    }) as RealtimeSubscription;
  }

  /// S'abonne aux nouveaux événements dans une zone
  RealtimeSubscription subscribeToNearbyEvents({
    required Function(EventModel) onNewEvent,
  }) {
    final channel = AppwriteConfig.eventsChannel;

    return _appwrite.realtime.subscribe([channel]).stream.listen((response) {
      if (response.events.any((e) => e.contains('.create'))) {
        final event = EventModel.fromJson(response.payload);
        onNewEvent(event);
      }
    }) as RealtimeSubscription;
  }
}
