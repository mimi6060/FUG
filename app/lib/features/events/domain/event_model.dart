import 'package:equatable/equatable.dart';

/// Statut d'un événement
enum EventStatus {
  draft,      // Brouillon
  published,  // Publié et visible
  cancelled,  // Annulé
  completed,  // Terminé
}

/// Extension pour convertir le statut en string et vice-versa
extension EventStatusExtension on EventStatus {
  String get value {
    switch (this) {
      case EventStatus.draft:
        return 'draft';
      case EventStatus.published:
        return 'published';
      case EventStatus.cancelled:
        return 'cancelled';
      case EventStatus.completed:
        return 'completed';
    }
  }

  static EventStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return EventStatus.draft;
      case 'published':
        return EventStatus.published;
      case 'cancelled':
        return EventStatus.cancelled;
      case 'completed':
        return EventStatus.completed;
      default:
        return EventStatus.draft;
    }
  }
}

/// Modèle représentant un événement dans l'application FUG
///
/// Contient toutes les informations d'un événement
/// stocké dans la collection 'events' d'Appwrite.
class EventModel extends Equatable {
  /// ID unique de l'événement
  final String id;

  /// Titre de l'événement
  final String title;

  /// Description détaillée
  final String description;

  /// ID de l'organisateur (référence à users)
  final String organizerId;

  /// Nom de l'organisateur (dénormalisé pour l'affichage)
  final String organizerName;

  /// ID de la catégorie
  final String categoryId;

  /// Nom de la catégorie (dénormalisé)
  final String? categoryName;

  /// URL de l'image principale
  final String? imageUrl;

  /// Liste des URLs d'images additionnelles
  final List<String> additionalImages;

  /// Adresse textuelle du lieu
  final String address;

  /// Latitude du lieu
  final double latitude;

  /// Longitude du lieu
  final double longitude;

  /// Nom du lieu (ex: "Parc de la Villette")
  final String? venueName;

  /// Date et heure de début
  final DateTime startDate;

  /// Date et heure de fin
  final DateTime endDate;

  /// Nombre maximum de participants (null = illimité)
  final int? maxParticipants;

  /// Nombre actuel de participants
  final int currentParticipants;

  /// Prix en centimes (0 = gratuit)
  final int price;

  /// Devise (EUR, USD, etc.)
  final String currency;

  /// Tags/mots-clés
  final List<String> tags;

  /// Statut de l'événement
  final EventStatus status;

  /// Indique si l'événement est mis en avant
  final bool isFeatured;

  /// Note moyenne (0-5)
  final double rating;

  /// Nombre d'avis
  final int reviewCount;

  /// Date de création
  final DateTime createdAt;

  /// Date de dernière modification
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.organizerName,
    required this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.additionalImages = const [],
    required this.address,
    required this.latitude,
    required this.longitude,
    this.venueName,
    required this.startDate,
    required this.endDate,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.price = 0,
    this.currency = 'EUR',
    this.tags = const [],
    this.status = EventStatus.published,
    this.isFeatured = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un EventModel à partir d'un Map JSON (document Appwrite)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['\$id'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      organizerId: json['organizerId'] as String,
      organizerName: json['organizerName'] as String,
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      additionalImages: List<String>.from(json['additionalImages'] ?? []),
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      venueName: json['venueName'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      maxParticipants: json['maxParticipants'] as int?,
      currentParticipants: json['currentParticipants'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      tags: List<String>.from(json['tags'] ?? []),
      status: EventStatusExtension.fromString(json['status'] as String? ?? 'published'),
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convertit le EventModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'additionalImages': additionalImages,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'venueName': venueName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'price': price,
      'currency': currency,
      'tags': tags,
      'status': status.value,
      'isFeatured': isFeatured,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une copie avec des valeurs modifiées
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? organizerId,
    String? organizerName,
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
    int? currentParticipants,
    int? price,
    String? currency,
    List<String>? tags,
    EventStatus? status,
    bool? isFeatured,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalImages: additionalImages ?? this.additionalImages,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      venueName: venueName ?? this.venueName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================
  // Propriétés calculées
  // ============================================

  /// Indique si l'événement est gratuit
  bool get isFree => price == 0;

  /// Retourne le prix formaté
  String get formattedPrice {
    if (isFree) return 'Gratuit';
    final amount = price / 100;
    return '$amount $currency';
  }

  /// Indique si l'événement est complet
  bool get isFull =>
      maxParticipants != null && currentParticipants >= maxParticipants!;

  /// Nombre de places restantes
  int? get remainingSpots =>
      maxParticipants != null ? maxParticipants! - currentParticipants : null;

  /// Indique si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Indique si l'événement est passé
  bool get isPast => DateTime.now().isAfter(endDate);

  /// Indique si l'événement est à venir
  bool get isUpcoming => DateTime.now().isBefore(startDate);

  /// Durée de l'événement
  Duration get duration => endDate.difference(startDate);

  /// Durée formatée
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        organizerId,
        organizerName,
        categoryId,
        categoryName,
        imageUrl,
        additionalImages,
        address,
        latitude,
        longitude,
        venueName,
        startDate,
        endDate,
        maxParticipants,
        currentParticipants,
        price,
        currency,
        tags,
        status,
        isFeatured,
        rating,
        reviewCount,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'EventModel(id: $id, title: $title, startDate: $startDate)';
}
