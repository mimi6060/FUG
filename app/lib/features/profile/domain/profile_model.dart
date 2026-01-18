import '../../auth/domain/user_model.dart';

/// Modele de profil etendant UserModel avec des statistiques additionnelles
///
/// Ce modele est utilise pour l'affichage du profil utilisateur
/// avec des informations supplementaires comme les statistiques sociales.
class ProfileModel {
  /// Donnees utilisateur de base
  final UserModel user;

  /// Nombre de followers
  final int followersCount;

  /// Nombre de personnes suivies
  final int followingCount;

  /// Nombre total d'evenements crees
  final int totalEventsCreated;

  /// Nombre total d'evenements auxquels l'utilisateur a participe
  final int totalEventsAttended;

  /// Badge/niveau de l'utilisateur
  final String? badge;

  /// Points de gamification
  final int points;

  /// Indique si l'utilisateur actuel suit ce profil
  final bool isFollowing;

  /// Indique si ce profil suit l'utilisateur actuel
  final bool isFollowedBy;

  const ProfileModel({
    required this.user,
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalEventsCreated = 0,
    this.totalEventsAttended = 0,
    this.badge,
    this.points = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  /// Cree un ProfileModel a partir d'un UserModel
  factory ProfileModel.fromUser(UserModel user) {
    return ProfileModel(
      user: user,
      totalEventsCreated: user.eventsCreated,
      totalEventsAttended: user.eventsAttended,
    );
  }

  /// Cree un ProfileModel a partir de JSON
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      user: UserModel.fromJson(json['user'] ?? json),
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      totalEventsCreated: json['totalEventsCreated'] as int? ?? 0,
      totalEventsAttended: json['totalEventsAttended'] as int? ?? 0,
      badge: json['badge'] as String?,
      points: json['points'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isFollowedBy: json['isFollowedBy'] as bool? ?? false,
    );
  }

  /// Convertit le ProfileModel en JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'totalEventsCreated': totalEventsCreated,
      'totalEventsAttended': totalEventsAttended,
      'badge': badge,
      'points': points,
      'isFollowing': isFollowing,
      'isFollowedBy': isFollowedBy,
    };
  }

  /// Cree une copie avec des valeurs modifiees
  ProfileModel copyWith({
    UserModel? user,
    int? followersCount,
    int? followingCount,
    int? totalEventsCreated,
    int? totalEventsAttended,
    String? badge,
    int? points,
    bool? isFollowing,
    bool? isFollowedBy,
  }) {
    return ProfileModel(
      user: user ?? this.user,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      totalEventsCreated: totalEventsCreated ?? this.totalEventsCreated,
      totalEventsAttended: totalEventsAttended ?? this.totalEventsAttended,
      badge: badge ?? this.badge,
      points: points ?? this.points,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
    );
  }

  // ===========================================
  // Proprietes calculees
  // ===========================================

  /// ID de l'utilisateur
  String get id => user.id;

  /// Nom de l'utilisateur
  String get name => user.name;

  /// Email de l'utilisateur
  String get email => user.email;

  /// Avatar URL
  String? get avatarUrl => user.avatarUrl;

  /// Bio de l'utilisateur
  String? get bio => user.bio;

  /// Localisation textuelle
  String? get location => user.location;

  /// Initiales pour l'avatar par defaut
  String get initials => user.initials;

  /// Indique si le profil est verifie
  bool get isVerified => user.isVerified;

  /// Note moyenne
  double get rating => user.rating;

  /// Niveau base sur les points
  int get level => (points / 100).floor() + 1;

  /// Progression vers le prochain niveau (0-100)
  double get levelProgress => (points % 100).toDouble();

  @override
  String toString() => 'ProfileModel(user: ${user.name}, followers: $followersCount)';
}
