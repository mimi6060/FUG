import 'package:equatable/equatable.dart';

/// Modèle représentant un utilisateur de l'application FUG
///
/// Contient toutes les informations du profil utilisateur
/// stockées dans la collection 'users' d'Appwrite.
class UserModel extends Equatable {
  /// ID unique de l'utilisateur (correspond à l'ID Appwrite Auth)
  final String id;

  /// Adresse email
  final String email;

  /// Nom affiché
  final String name;

  /// URL de l'avatar (peut être null)
  final String? avatarUrl;

  /// Biographie de l'utilisateur
  final String? bio;

  /// Ville/localisation textuelle
  final String? location;

  /// Latitude de la position
  final double? latitude;

  /// Longitude de la position
  final double? longitude;

  /// Liste des centres d'intérêt (IDs des catégories)
  final List<String> interests;

  /// Nombre d'événements créés
  final int eventsCreated;

  /// Nombre d'événements auxquels l'utilisateur a participé
  final int eventsAttended;

  /// Note moyenne de l'utilisateur (0-5)
  final double rating;

  /// Indique si l'utilisateur est vérifié
  final bool isVerified;

  /// Date de création du compte
  final DateTime createdAt;

  /// Date de dernière mise à jour du profil
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    this.interests = const [],
    this.eventsCreated = 0,
    this.eventsAttended = 0,
    this.rating = 0.0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crée un UserModel à partir d'un Map JSON (document Appwrite)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['userId'] as String? ?? json['\$id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar'] as String?, // DB field is 'avatar'
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: (json['locationLat'] as num?)?.toDouble(), // DB field is 'locationLat'
      longitude: (json['locationLng'] as num?)?.toDouble(), // DB field is 'locationLng'
      interests: List<String>.from(json['interests'] ?? []),
      eventsCreated: json['eventsCreated'] as int? ?? 0,
      eventsAttended: json['eventsAttended'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convertit le UserModel en Map JSON (format base de données)
  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'email': email,
      'name': name,
      'avatar': avatarUrl, // DB field is 'avatar'
      'bio': bio,
      'locationLat': latitude, // DB field is 'locationLat'
      'locationLng': longitude, // DB field is 'locationLng'
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crée une copie avec des valeurs modifiées
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? bio,
    String? location,
    double? latitude,
    double? longitude,
    List<String>? interests,
    int? eventsCreated,
    int? eventsAttended,
    double? rating,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      interests: interests ?? this.interests,
      eventsCreated: eventsCreated ?? this.eventsCreated,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      rating: rating ?? this.rating,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si le profil est complet
  bool get isProfileComplete =>
      name.isNotEmpty &&
      bio != null &&
      bio!.isNotEmpty &&
      interests.isNotEmpty;

  /// Vérifie si la localisation est définie
  bool get hasLocation => latitude != null && longitude != null;

  /// Retourne les initiales du nom (pour l'avatar par défaut)
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        bio,
        location,
        latitude,
        longitude,
        interests,
        eventsCreated,
        eventsAttended,
        rating,
        isVerified,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';
}
