import 'package:equatable/equatable.dart';

/// Type de notification
enum NotificationType {
  /// Nouvel evenement dans la zone
  newEvent,
  /// Evenement auquel on participe bientot
  eventReminder,
  /// Evenement annule
  eventCancelled,
  /// Evenement modifie
  eventUpdated,
  /// Quelqu'un a rejoint notre evenement
  newParticipant,
  /// Quelqu'un nous suit
  newFollower,
  /// Quelqu'un a aime notre evenement
  eventLiked,
  /// Nouveau commentaire sur notre evenement
  newComment,
  /// Message direct
  directMessage,
  /// Notification systeme
  system,
}

/// Extension pour convertir le type en string
extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.newEvent:
        return 'new_event';
      case NotificationType.eventReminder:
        return 'event_reminder';
      case NotificationType.eventCancelled:
        return 'event_cancelled';
      case NotificationType.eventUpdated:
        return 'event_updated';
      case NotificationType.newParticipant:
        return 'new_participant';
      case NotificationType.newFollower:
        return 'new_follower';
      case NotificationType.eventLiked:
        return 'event_liked';
      case NotificationType.newComment:
        return 'new_comment';
      case NotificationType.directMessage:
        return 'direct_message';
      case NotificationType.system:
        return 'system';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'new_event':
        return NotificationType.newEvent;
      case 'event_reminder':
        return NotificationType.eventReminder;
      case 'event_cancelled':
        return NotificationType.eventCancelled;
      case 'event_updated':
        return NotificationType.eventUpdated;
      case 'new_participant':
        return NotificationType.newParticipant;
      case 'new_follower':
        return NotificationType.newFollower;
      case 'event_liked':
        return NotificationType.eventLiked;
      case 'new_comment':
        return NotificationType.newComment;
      case 'direct_message':
        return NotificationType.directMessage;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }

  /// Icone associee au type
  String get iconName {
    switch (this) {
      case NotificationType.newEvent:
        return 'event';
      case NotificationType.eventReminder:
        return 'alarm';
      case NotificationType.eventCancelled:
        return 'cancel';
      case NotificationType.eventUpdated:
        return 'update';
      case NotificationType.newParticipant:
        return 'person_add';
      case NotificationType.newFollower:
        return 'person_add';
      case NotificationType.eventLiked:
        return 'favorite';
      case NotificationType.newComment:
        return 'comment';
      case NotificationType.directMessage:
        return 'message';
      case NotificationType.system:
        return 'info';
    }
  }
}

/// Modele representant une notification
class NotificationModel extends Equatable {
  /// ID unique de la notification
  final String id;

  /// ID de l'utilisateur destinataire
  final String userId;

  /// Type de notification
  final NotificationType type;

  /// Titre de la notification
  final String title;

  /// Corps/message de la notification
  final String body;

  /// Donnees additionnelles (IDs, metadata, etc.)
  final Map<String, dynamic>? data;

  /// ID de l'evenement lie (si applicable)
  final String? eventId;

  /// ID de l'utilisateur source (si applicable)
  final String? fromUserId;

  /// Nom de l'utilisateur source (si applicable)
  final String? fromUserName;

  /// Avatar de l'utilisateur source (si applicable)
  final String? fromUserAvatar;

  /// Image associee a la notification
  final String? imageUrl;

  /// URL de redirection au clic
  final String? actionUrl;

  /// Indique si la notification a ete lue
  final bool isRead;

  /// Date de creation
  final DateTime createdAt;

  /// Date de lecture (si lue)
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.eventId,
    this.fromUserId,
    this.fromUserName,
    this.fromUserAvatar,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  /// Cree une NotificationModel a partir d'un Map JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['\$id'] as String? ?? json['id'] as String,
      userId: json['userId'] as String,
      type: NotificationTypeExtension.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>?,
      eventId: json['eventId'] as String?,
      fromUserId: json['fromUserId'] as String?,
      fromUserName: json['fromUserName'] as String?,
      fromUserAvatar: json['fromUserAvatar'] as String?,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  /// Convertit le NotificationModel en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
      'eventId': eventId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// Cree une copie avec des valeurs modifiees
  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? eventId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      eventId: eventId ?? this.eventId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // =============================================
  // Proprietes calculees
  // =============================================

  /// Temps relatif depuis la creation
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${createdAt.day}/${createdAt.month}';
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

  /// Verifie si la notification est recente (moins de 24h)
  bool get isRecent => DateTime.now().difference(createdAt).inHours < 24;

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        body,
        data,
        eventId,
        fromUserId,
        fromUserName,
        fromUserAvatar,
        imageUrl,
        actionUrl,
        isRead,
        createdAt,
        readAt,
      ];

  @override
  String toString() =>
      'NotificationModel(id: $id, type: ${type.value}, title: $title)';
}
