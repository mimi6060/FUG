import 'package:equatable/equatable.dart';

/// Type de contenu signalable
enum ReportContentType {
  /// Evenement
  event,
  /// Profil utilisateur
  user,
  /// Commentaire
  comment,
}

/// Extension pour ReportContentType
extension ReportContentTypeExtension on ReportContentType {
  String get value {
    switch (this) {
      case ReportContentType.event:
        return 'event';
      case ReportContentType.user:
        return 'user';
      case ReportContentType.comment:
        return 'comment';
    }
  }

  String get displayName {
    switch (this) {
      case ReportContentType.event:
        return 'Evenement';
      case ReportContentType.user:
        return 'Utilisateur';
      case ReportContentType.comment:
        return 'Commentaire';
    }
  }

  static ReportContentType fromString(String value) {
    switch (value) {
      case 'event':
        return ReportContentType.event;
      case 'user':
        return ReportContentType.user;
      case 'comment':
        return ReportContentType.comment;
      default:
        return ReportContentType.event;
    }
  }
}

/// Categorie de signalement (DSA)
enum ReportCategory {
  /// Contenu illegal (incitation a la haine, violence, etc.)
  illegal,
  /// Contenu inapproprie (non conforme aux CGU)
  inappropriate,
  /// Spam ou publicite non sollicitee
  spam,
  /// Autre raison
  other,
}

/// Extension pour ReportCategory
extension ReportCategoryExtension on ReportCategory {
  String get value {
    switch (this) {
      case ReportCategory.illegal:
        return 'illegal';
      case ReportCategory.inappropriate:
        return 'inappropriate';
      case ReportCategory.spam:
        return 'spam';
      case ReportCategory.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ReportCategory.illegal:
        return 'Contenu illegal';
      case ReportCategory.inappropriate:
        return 'Contenu inapproprie';
      case ReportCategory.spam:
        return 'Spam';
      case ReportCategory.other:
        return 'Autre';
    }
  }

  String get description {
    switch (this) {
      case ReportCategory.illegal:
        return 'Incitation a la haine, violence, contenu interdit par la loi';
      case ReportCategory.inappropriate:
        return 'Ne respecte pas les conditions d\'utilisation';
      case ReportCategory.spam:
        return 'Publicite non sollicitee ou contenu repetitif';
      case ReportCategory.other:
        return 'Autre probleme avec ce contenu';
    }
  }

  static ReportCategory fromString(String value) {
    switch (value) {
      case 'illegal':
        return ReportCategory.illegal;
      case 'inappropriate':
        return ReportCategory.inappropriate;
      case 'spam':
        return ReportCategory.spam;
      case 'other':
        return ReportCategory.other;
      default:
        return ReportCategory.other;
    }
  }
}

/// Statut du signalement
enum ReportStatus {
  /// En attente de traitement
  pending,
  /// Examine par un moderateur
  reviewed,
  /// Action prise suite au signalement
  actioned,
  /// Signalement rejete
  dismissed,
}

/// Extension pour ReportStatus
extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.actioned:
        return 'actioned';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }

  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'En attente';
      case ReportStatus.reviewed:
        return 'Examine';
      case ReportStatus.actioned:
        return 'Action prise';
      case ReportStatus.dismissed:
        return 'Rejete';
    }
  }

  static ReportStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'actioned':
        return ReportStatus.actioned;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }
}

/// Action prise suite au signalement
enum ReportActionTaken {
  /// Avertissement envoye
  warning,
  /// Contenu supprime
  removed,
  /// Utilisateur banni
  banned,
  /// Aucune action
  none,
}

/// Extension pour ReportActionTaken
extension ReportActionTakenExtension on ReportActionTaken {
  String get value {
    switch (this) {
      case ReportActionTaken.warning:
        return 'warning';
      case ReportActionTaken.removed:
        return 'removed';
      case ReportActionTaken.banned:
        return 'banned';
      case ReportActionTaken.none:
        return 'none';
    }
  }

  String get displayName {
    switch (this) {
      case ReportActionTaken.warning:
        return 'Avertissement';
      case ReportActionTaken.removed:
        return 'Contenu supprime';
      case ReportActionTaken.banned:
        return 'Compte suspendu';
      case ReportActionTaken.none:
        return 'Aucune action';
    }
  }

  static ReportActionTaken? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'warning':
        return ReportActionTaken.warning;
      case 'removed':
        return ReportActionTaken.removed;
      case 'banned':
        return ReportActionTaken.banned;
      case 'none':
        return ReportActionTaken.none;
      default:
        return null;
    }
  }
}

/// Modele representant un signalement de contenu
/// Conforme au DSA (Digital Services Act)
class ReportModel extends Equatable {
  /// ID unique du signalement
  final String id;

  /// ID de l'utilisateur qui signale
  final String reporterId;

  /// Type de contenu signale
  final ReportContentType contentType;

  /// ID du contenu signale
  final String contentId;

  /// Categorie du signalement
  final ReportCategory category;

  /// Description optionnelle
  final String? description;

  /// Statut actuel du signalement
  final ReportStatus status;

  /// ID du moderateur qui a traite
  final String? moderatorId;

  /// Note interne du moderateur
  final String? moderatorNote;

  /// Action prise
  final ReportActionTaken? actionTaken;

  /// Date de creation
  final DateTime createdAt;

  /// Date de traitement
  final DateTime? reviewedAt;

  const ReportModel({
    required this.id,
    required this.reporterId,
    required this.contentType,
    required this.contentId,
    required this.category,
    this.description,
    this.status = ReportStatus.pending,
    this.moderatorId,
    this.moderatorNote,
    this.actionTaken,
    required this.createdAt,
    this.reviewedAt,
  });

  /// Cree un ReportModel a partir d'un Map JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['\$id'] as String? ?? json['id'] as String,
      reporterId: json['reporterId'] as String,
      contentType: ReportContentTypeExtension.fromString(json['contentType'] as String),
      contentId: json['contentId'] as String,
      category: ReportCategoryExtension.fromString(json['category'] as String),
      description: json['description'] as String?,
      status: ReportStatusExtension.fromString(json['status'] as String? ?? 'pending'),
      moderatorId: json['moderatorId'] as String?,
      moderatorNote: json['moderatorNote'] as String?,
      actionTaken: ReportActionTakenExtension.fromString(json['actionTaken'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
    );
  }

  /// Convertit le ReportModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'contentType': contentType.value,
      'contentId': contentId,
      'category': category.value,
      'description': description,
      'status': status.value,
      'moderatorId': moderatorId,
      'moderatorNote': moderatorNote,
      'actionTaken': actionTaken?.value,
      'createdAt': createdAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  /// Cree une copie avec des valeurs modifiees
  ReportModel copyWith({
    String? id,
    String? reporterId,
    ReportContentType? contentType,
    String? contentId,
    ReportCategory? category,
    String? description,
    ReportStatus? status,
    String? moderatorId,
    String? moderatorNote,
    ReportActionTaken? actionTaken,
    DateTime? createdAt,
    DateTime? reviewedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      category: category ?? this.category,
      description: description ?? this.description,
      status: status ?? this.status,
      moderatorId: moderatorId ?? this.moderatorId,
      moderatorNote: moderatorNote ?? this.moderatorNote,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  // =============================================
  // Proprietes calculees
  // =============================================

  /// Verifie si le signalement est en attente
  bool get isPending => status == ReportStatus.pending;

  /// Verifie si le signalement a ete traite
  bool get isProcessed => status != ReportStatus.pending;

  /// Verifie si une action a ete prise
  bool get hasActionTaken => actionTaken != null && actionTaken != ReportActionTaken.none;

  /// Temps relatif depuis la creation
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'A l\'instant';
    }
  }

  @override
  List<Object?> get props => [
        id,
        reporterId,
        contentType,
        contentId,
        category,
        description,
        status,
        moderatorId,
        moderatorNote,
        actionTaken,
        createdAt,
        reviewedAt,
      ];

  @override
  String toString() =>
      'ReportModel(id: $id, category: ${category.value}, status: ${status.value})';
}
