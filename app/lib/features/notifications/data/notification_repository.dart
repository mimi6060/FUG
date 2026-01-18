import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/appwrite_config.dart';
import '../../../core/services/appwrite_service.dart';
import '../domain/notification_model.dart';

/// Exception personnalisee pour les notifications
class NotificationException implements Exception {
  final String message;
  final int? code;

  NotificationException(this.message, {this.code});

  @override
  String toString() => 'NotificationException: $message';
}

/// Repository pour la gestion des notifications
class NotificationRepository {
  final AppwriteService _appwrite;

  NotificationRepository({AppwriteService? appwrite})
      : _appwrite = appwrite ?? AppwriteService.instance;

  Databases get _databases => _appwrite.databases;

  // =============================================
  // Recuperation des notifications
  // =============================================

  /// Recupere les notifications d'un utilisateur
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final queries = <String>[
        Query.equal('userId', userId),
        Query.orderDesc('createdAt'),
        Query.limit(limit),
        Query.offset(offset),
      ];

      if (unreadOnly) {
        queries.add(Query.equal('isRead', false));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        queries: queries,
      );

      return result.documents
          .map((doc) => NotificationModel.fromJson(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors de la recuperation des notifications.',
        code: e.code,
      );
    }
  }

  /// Recupere le nombre de notifications non lues
  Future<int> getUnreadCount(String userId) async {
    try {
      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('isRead', false),
          Query.limit(1),
        ],
      );

      return result.total;
    } on AppwriteException catch (e) {
      if (kDebugMode) {
        print('Error getting unread count: ${e.message}');
      }
      return 0;
    }
  }

  // =============================================
  // Gestion des notifications
  // =============================================

  /// Marque une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: notificationId,
        data: {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors du marquage de la notification.',
        code: e.code,
      );
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      // Recuperer toutes les notifications non lues
      final unreadNotifications = await getNotifications(
        userId: userId,
        unreadOnly: true,
        limit: 100,
      );

      // Marquer chacune comme lue
      for (final notification in unreadNotifications) {
        await markAsRead(notification.id);
      }
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors du marquage des notifications.',
        code: e.code,
      );
    }
  }

  /// Supprime une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: notificationId,
      );
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors de la suppression de la notification.',
        code: e.code,
      );
    }
  }

  /// Supprime toutes les notifications d'un utilisateur
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final notifications = await getNotifications(
        userId: userId,
        limit: 100,
      );

      for (final notification in notifications) {
        await deleteNotification(notification.id);
      }
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors de la suppression des notifications.',
        code: e.code,
      );
    }
  }

  // =============================================
  // Creation de notifications (utilise par le backend)
  // =============================================

  /// Cree une notification
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? eventId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? imageUrl,
    String? actionUrl,
  }) async {
    try {
      final doc = await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.notificationsCollectionId,
        documentId: ID.unique(),
        data: {
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
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
          'readAt': null,
        },
        permissions: [
          Permission.read(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ],
      );

      return NotificationModel.fromJson(doc.data);
    } on AppwriteException catch (e) {
      throw NotificationException(
        e.message ?? 'Erreur lors de la creation de la notification.',
        code: e.code,
      );
    }
  }

  // =============================================
  // Realtime
  // =============================================

  /// S'abonne aux nouvelles notifications
  RealtimeSubscription subscribeToNotifications({
    required String userId,
    required Function(NotificationModel) onNewNotification,
  }) {
    final channel = AppwriteConfig.userNotificationsChannel(userId);

    return _appwrite.realtime.subscribe([channel]).stream.listen((response) {
      if (response.events.any((e) => e.contains('.create'))) {
        final notification = NotificationModel.fromJson(response.payload);
        // Verifier que c'est bien pour cet utilisateur
        if (notification.userId == userId) {
          onNewNotification(notification);
        }
      }
    }) as RealtimeSubscription;
  }
}
