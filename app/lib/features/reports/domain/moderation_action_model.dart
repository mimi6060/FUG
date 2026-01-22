import 'package:equatable/equatable.dart';

import 'report_model.dart';

/// Type d'action de moderation
enum ModerationAction {
  /// Avertissement envoye
  warning,
  /// Contenu supprime
  contentRemoved,
  /// Contenu cache
  contentHidden,
  /// Compte suspendu temporairement
  accountSuspended,
  /// Compte banni definitivement
  accountBanned,
}

/// Extension pour ModerationAction
extension ModerationActionExtension on ModerationAction {
  String get value {
    switch (this) {
      case ModerationAction.warning:
        return 'warning';
      case ModerationAction.contentRemoved:
        return 'content_removed';
      case ModerationAction.contentHidden:
        return 'content_hidden';
      case ModerationAction.accountSuspended:
        return 'account_suspended';
      case ModerationAction.accountBanned:
        return 'account_banned';
    }
  }

  String get displayName {
    switch (this) {
      case ModerationAction.warning:
        return 'Avertissement';
      case ModerationAction.contentRemoved:
        return 'Contenu supprime';
      case ModerationAction.contentHidden:
        return 'Contenu masque';
      case ModerationAction.accountSuspended:
        return 'Compte suspendu';
      case ModerationAction.accountBanned:
        return 'Compte banni';
    }
  }

  String get userFriendlyDescription {
    switch (this) {
      case ModerationAction.warning:
        return 'Vous avez recu un avertissement. Merci de respecter les regles de la communaute.';
      case ModerationAction.contentRemoved:
        return 'Votre contenu a ete retire car il ne respectait pas nos conditions d\'utilisation.';
      case ModerationAction.contentHidden:
        return 'Votre contenu a ete temporairement masque en attendant verification.';
      case ModerationAction.accountSuspended:
        return 'Votre compte a ete temporairement suspendu suite a des violations repetees.';
      case ModerationAction.accountBanned:
        return 'Votre compte a ete definitivement ferme pour non-respect des conditions d\'utilisation.';
    }
  }

  static ModerationAction fromString(String value) {
    switch (value) {
      case 'warning':
        return ModerationAction.warning;
      case 'content_removed':
        return ModerationAction.contentRemoved;
      case 'content_hidden':
        return ModerationAction.contentHidden;
      case 'account_suspended':
        return ModerationAction.accountSuspended;
      case 'account_banned':
        return ModerationAction.accountBanned;
      default:
        return ModerationAction.warning;
    }
  }
}

/// Statut d'un appel (contestation DSA)
enum AppealStatus {
  /// En attente de traitement
  pending,
  /// Appel accepte, action annulee
  accepted,
  /// Appel rejete, action maintenue
  rejected,
}

/// Extension pour AppealStatus
extension AppealStatusExtension on AppealStatus {
  String get value {
    switch (this) {
      case AppealStatus.pending:
        return 'pending';
      case AppealStatus.accepted:
        return 'accepted';
      case AppealStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case AppealStatus.pending:
        return 'En attente';
      case AppealStatus.accepted:
        return 'Accepte';
      case AppealStatus.rejected:
        return 'Rejete';
    }
  }

  static AppealStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'pending':
        return AppealStatus.pending;
      case 'accepted':
        return AppealStatus.accepted;
      case 'rejected':
        return AppealStatus.rejected;
      default:
        return null;
    }
  }
}

/// Modele representant une action de moderation
/// Conforme au DSA (Digital Services Act) - inclut le droit d'appel
class ModerationActionModel extends Equatable {
  /// ID unique de l'action
  final String id;

  /// ID du signalement lie (optionnel)
  final String? reportId;

  /// Type de contenu modere
  final ReportContentType contentType;

  /// ID du contenu modere
  final String contentId;

  /// ID de l'utilisateur modere
  final String targetUserId;

  /// Action de moderation prise
  final ModerationAction action;

  /// Raison de l'action (DSA: doit etre claire)
  final String reason;

  /// ID du moderateur
  final String moderatorId;

  /// L'utilisateur a-t-il fait appel? (DSA: droit d'appel)
  final bool isAppealed;

  /// Texte de l'appel
  final String? appealText;

  /// Date de l'appel
  final DateTime? appealedAt;

  /// Statut de l'appel
  final AppealStatus? appealStatus;

  /// Date de traitement de l'appel
  final DateTime? appealReviewedAt;

  /// Qui a traite l'appel
  final String? appealReviewedBy;

  /// Raison de la decision d'appel (DSA: decision finale motivee)
  final String? appealDecisionReason;

  /// Date d'envoi de notification (DSA: obligation de notification)
  final DateTime? notificationSentAt;

  /// Date de creation
  final DateTime createdAt;

  const ModerationActionModel({
    required this.id,
    this.reportId,
    required this.contentType,
    required this.contentId,
    required this.targetUserId,
    required this.action,
    required this.reason,
    required this.moderatorId,
    this.isAppealed = false,
    this.appealText,
    this.appealedAt,
    this.appealStatus,
    this.appealReviewedAt,
    this.appealReviewedBy,
    this.appealDecisionReason,
    this.notificationSentAt,
    required this.createdAt,
  });

  /// Cree un ModerationActionModel a partir d'un Map JSON
  factory ModerationActionModel.fromJson(Map<String, dynamic> json) {
    return ModerationActionModel(
      id: json['\$id'] as String? ?? json['id'] as String,
      reportId: json['reportId'] as String?,
      contentType: ReportContentTypeExtension.fromString(json['contentType'] as String),
      contentId: json['contentId'] as String,
      targetUserId: json['targetUserId'] as String,
      action: ModerationActionExtension.fromString(json['action'] as String),
      reason: json['reason'] as String,
      moderatorId: json['moderatorId'] as String,
      isAppealed: json['isAppealed'] as bool? ?? false,
      appealText: json['appealText'] as String?,
      appealedAt: json['appealedAt'] != null
          ? DateTime.parse(json['appealedAt'] as String)
          : null,
      appealStatus: AppealStatusExtension.fromString(json['appealStatus'] as String?),
      appealReviewedAt: json['appealReviewedAt'] != null
          ? DateTime.parse(json['appealReviewedAt'] as String)
          : null,
      appealReviewedBy: json['appealReviewedBy'] as String?,
      appealDecisionReason: json['appealDecisionReason'] as String?,
      notificationSentAt: json['notificationSentAt'] != null
          ? DateTime.parse(json['notificationSentAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convertit le ModerationActionModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'contentType': contentType.value,
      'contentId': contentId,
      'targetUserId': targetUserId,
      'action': action.value,
      'reason': reason,
      'moderatorId': moderatorId,
      'isAppealed': isAppealed,
      'appealText': appealText,
      'appealedAt': appealedAt?.toIso8601String(),
      'appealStatus': appealStatus?.value,
      'appealReviewedAt': appealReviewedAt?.toIso8601String(),
      'appealReviewedBy': appealReviewedBy,
      'appealDecisionReason': appealDecisionReason,
      'notificationSentAt': notificationSentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Cree une copie avec des valeurs modifiees
  ModerationActionModel copyWith({
    String? id,
    String? reportId,
    ReportContentType? contentType,
    String? contentId,
    String? targetUserId,
    ModerationAction? action,
    String? reason,
    String? moderatorId,
    bool? isAppealed,
    String? appealText,
    DateTime? appealedAt,
    AppealStatus? appealStatus,
    DateTime? appealReviewedAt,
    String? appealReviewedBy,
    String? appealDecisionReason,
    DateTime? notificationSentAt,
    DateTime? createdAt,
  }) {
    return ModerationActionModel(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      targetUserId: targetUserId ?? this.targetUserId,
      action: action ?? this.action,
      reason: reason ?? this.reason,
      moderatorId: moderatorId ?? this.moderatorId,
      isAppealed: isAppealed ?? this.isAppealed,
      appealText: appealText ?? this.appealText,
      appealedAt: appealedAt ?? this.appealedAt,
      appealStatus: appealStatus ?? this.appealStatus,
      appealReviewedAt: appealReviewedAt ?? this.appealReviewedAt,
      appealReviewedBy: appealReviewedBy ?? this.appealReviewedBy,
      appealDecisionReason: appealDecisionReason ?? this.appealDecisionReason,
      notificationSentAt: notificationSentAt ?? this.notificationSentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // =============================================
  // Proprietes calculees
  // =============================================

  /// Peut faire appel (DSA: delai de 72h)
  bool get canAppeal {
    if (isAppealed) return false;
    final timeSinceCreation = DateTime.now().difference(createdAt);
    return timeSinceCreation.inHours <= 72;
  }

  /// Temps restant pour faire appel
  Duration get timeLeftToAppeal {
    if (isAppealed) return Duration.zero;
    final appealDeadline = createdAt.add(const Duration(hours: 72));
    final remaining = appealDeadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// L'appel est-il en attente?
  bool get isAppealPending => isAppealed && appealStatus == AppealStatus.pending;

  /// L'appel a-t-il ete accepte?
  bool get isAppealAccepted => appealStatus == AppealStatus.accepted;

  /// L'appel a-t-il ete rejete?
  bool get isAppealRejected => appealStatus == AppealStatus.rejected;

  /// L'utilisateur a-t-il ete notifie?
  bool get wasNotified => notificationSentAt != null;

  /// Temps relatif depuis l'action
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

  /// Message formaté pour le temps restant
  String get timeLeftToAppealFormatted {
    final remaining = timeLeftToAppeal;
    if (remaining == Duration.zero) return 'Delai expire';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min restantes';
    }
    return '${minutes} minutes restantes';
  }

  @override
  List<Object?> get props => [
        id,
        reportId,
        contentType,
        contentId,
        targetUserId,
        action,
        reason,
        moderatorId,
        isAppealed,
        appealText,
        appealedAt,
        appealStatus,
        appealReviewedAt,
        appealReviewedBy,
        appealDecisionReason,
        notificationSentAt,
        createdAt,
      ];

  @override
  String toString() =>
      'ModerationActionModel(id: $id, action: ${action.value}, isAppealed: $isAppealed)';
}
