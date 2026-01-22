import 'package:equatable/equatable.dart';

/// Categorie d'un achievement
enum AchievementCategory {
  /// Participation aux evenements
  participation,
  /// Creation d'evenements
  creation,
  /// Social (followers)
  social,
  /// Niveau
  level,
  /// Badges speciaux
  special,
}

/// Extension pour convertir la categorie en string
extension AchievementCategoryExtension on AchievementCategory {
  String get value {
    switch (this) {
      case AchievementCategory.participation:
        return 'participation';
      case AchievementCategory.creation:
        return 'creation';
      case AchievementCategory.social:
        return 'social';
      case AchievementCategory.level:
        return 'level';
      case AchievementCategory.special:
        return 'special';
    }
  }

  static AchievementCategory fromString(String value) {
    switch (value) {
      case 'participation':
        return AchievementCategory.participation;
      case 'creation':
        return AchievementCategory.creation;
      case 'social':
        return AchievementCategory.social;
      case 'level':
        return AchievementCategory.level;
      case 'special':
      default:
        return AchievementCategory.special;
    }
  }
}

/// Tier/niveau d'un achievement
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

/// Extension pour le tier
extension AchievementTierExtension on AchievementTier {
  String get value {
    switch (this) {
      case AchievementTier.bronze:
        return 'bronze';
      case AchievementTier.silver:
        return 'silver';
      case AchievementTier.gold:
        return 'gold';
      case AchievementTier.platinum:
        return 'platinum';
    }
  }

  static AchievementTier fromString(String value) {
    switch (value) {
      case 'bronze':
        return AchievementTier.bronze;
      case 'silver':
        return AchievementTier.silver;
      case 'gold':
        return AchievementTier.gold;
      case 'platinum':
        return AchievementTier.platinum;
      default:
        return AchievementTier.bronze;
    }
  }
}

/// Progression vers un achievement
class AchievementProgress extends Equatable {
  /// Valeur actuelle
  final int current;

  /// Valeur cible
  final int target;

  /// Pourcentage de progression (0-100)
  final int percentage;

  /// Si le badge est attribue manuellement
  final bool manual;

  const AchievementProgress({
    required this.current,
    required this.target,
    required this.percentage,
    this.manual = false,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      current: json['current'] as int? ?? 0,
      target: json['target'] as int? ?? 1,
      percentage: json['percentage'] as int? ?? 0,
      manual: json['manual'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'target': target,
      'percentage': percentage,
      'manual': manual,
    };
  }

  @override
  List<Object?> get props => [current, target, percentage, manual];
}

/// Modele representant un achievement/badge
class AchievementModel extends Equatable {
  /// ID unique de l'achievement
  final String id;

  /// Nom de l'achievement
  final String name;

  /// Description de l'achievement
  final String description;

  /// Icone de l'achievement
  final String icon;

  /// Categorie de l'achievement
  final AchievementCategory category;

  /// Tier/niveau de l'achievement
  final AchievementTier tier;

  /// Points requis ou attribues
  final int requiredPoints;

  /// Indique si l'achievement est debloque
  final bool isUnlocked;

  /// Date de deblocage (si debloque)
  final DateTime? unlockedAt;

  /// Progression vers l'achievement
  final AchievementProgress? progress;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.category = AchievementCategory.special,
    this.tier = AchievementTier.bronze,
    this.requiredPoints = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress,
  });

  /// Cree un AchievementModel a partir d'un Map JSON
  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] != null
          ? AchievementCategoryExtension.fromString(json['category'] as String)
          : _categoryFromId(json['id'] as String),
      tier: json['tier'] != null
          ? AchievementTierExtension.fromString(json['tier'] as String)
          : _tierFromId(json['id'] as String),
      requiredPoints: json['requiredPoints'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] != null
          ? AchievementProgress.fromJson(json['progress'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertit l'AchievementModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category.value,
      'tier': tier.value,
      'requiredPoints': requiredPoints,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress?.toJson(),
    };
  }

  /// Cree une copie avec des valeurs modifiees
  AchievementModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    AchievementCategory? category,
    AchievementTier? tier,
    int? requiredPoints,
    bool? isUnlocked,
    DateTime? unlockedAt,
    AchievementProgress? progress,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      tier: tier ?? this.tier,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }

  /// Determine la categorie a partir de l'ID
  static AchievementCategory _categoryFromId(String id) {
    if (id.contains('event') && id.contains('join')) {
      return AchievementCategory.participation;
    }
    if (id.contains('event') && id.contains('creat')) {
      return AchievementCategory.creation;
    }
    if (id.contains('social') || id.contains('follower') || id.contains('influencer')) {
      return AchievementCategory.social;
    }
    if (id.contains('level')) {
      return AchievementCategory.level;
    }
    return AchievementCategory.special;
  }

  /// Determine le tier a partir de l'ID
  static AchievementTier _tierFromId(String id) {
    if (id.contains('platinum') || id.contains('ultimate') || id.contains('100')) {
      return AchievementTier.platinum;
    }
    if (id.contains('legend') || id.contains('star') || id.contains('25')) {
      return AchievementTier.gold;
    }
    if (id.contains('master') || id.contains('veteran') || id.contains('10')) {
      return AchievementTier.silver;
    }
    return AchievementTier.bronze;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        category,
        tier,
        requiredPoints,
        isUnlocked,
        unlockedAt,
        progress,
      ];

  @override
  String toString() =>
      'AchievementModel(id: $id, name: $name, isUnlocked: $isUnlocked)';
}
