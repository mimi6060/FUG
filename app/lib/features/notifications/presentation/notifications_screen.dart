import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/notification_repository.dart';
import '../domain/notification_model.dart';

/// Provider pour le repository des notifications
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Provider pour les notifications de l'utilisateur
final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getNotifications(userId: user.$id);
});

/// Provider pour le nombre de notifications non lues
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return 0;

  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnreadCount(user.$id);
});

/// Ecran des notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final user = await ref.read(currentUserProvider.future);
              if (user == null) return;

              final repository = ref.read(notificationRepositoryProvider);

              switch (value) {
                case 'mark_all_read':
                  await repository.markAllAsRead(user.$id);
                  ref.invalidate(notificationsProvider);
                  ref.invalidate(unreadCountProvider);
                  break;
                case 'delete_all':
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer toutes les notifications'),
                      content: const Text(
                        'Etes-vous sur de vouloir supprimer toutes vos notifications?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await repository.deleteAllNotifications(user.$id);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(unreadCountProvider);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.done_all),
                  title: Text('Tout marquer comme lu'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Tout supprimer'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos notifications apparaitront ici',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, ref, notification),
                  onDismiss: () => _handleNotificationDismiss(ref, notification),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    // Marquer comme lu
    if (!notification.isRead) {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notification.id);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    }

    // Naviguer selon le type
    if (!context.mounted) return;

    switch (notification.type) {
      case NotificationType.newEvent:
      case NotificationType.eventReminder:
      case NotificationType.eventCancelled:
      case NotificationType.eventUpdated:
      case NotificationType.newParticipant:
      case NotificationType.eventLiked:
      case NotificationType.newComment:
        if (notification.eventId != null) {
          context.push('/events/${notification.eventId}');
        }
        break;
      case NotificationType.newFollower:
        if (notification.fromUserId != null) {
          context.push('/users/${notification.fromUserId}');
        }
        break;
      case NotificationType.directMessage:
        // TODO: Navigation vers les messages
        break;
      case NotificationType.system:
        // Pas de navigation
        break;
    }
  }

  Future<void> _handleNotificationDismiss(
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    final repository = ref.read(notificationRepositoryProvider);
    await repository.deleteNotification(notification.id);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }
}

/// Tuile de notification
class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: _buildLeading(theme),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        tileColor: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withOpacity(0.1),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading(ThemeData theme) {
    // Avatar de l'utilisateur source si disponible
    if (notification.fromUserAvatar != null) {
      return Stack(
        children: [
          CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              notification.fromUserAvatar!,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                size: 12,
                color: _getIconColor(theme),
              ),
            ),
          ),
        ],
      );
    }

    // Icone par defaut
    return CircleAvatar(
      backgroundColor: _getIconColor(theme).withOpacity(0.1),
      child: Icon(
        _getIcon(),
        color: _getIconColor(theme),
      ),
    );
  }

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.newEvent:
        return Icons.event;
      case NotificationType.eventReminder:
        return Icons.alarm;
      case NotificationType.eventCancelled:
        return Icons.cancel;
      case NotificationType.eventUpdated:
        return Icons.update;
      case NotificationType.newParticipant:
        return Icons.person_add;
      case NotificationType.newFollower:
        return Icons.person_add;
      case NotificationType.eventLiked:
        return Icons.favorite;
      case NotificationType.newComment:
        return Icons.comment;
      case NotificationType.directMessage:
        return Icons.message;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (notification.type) {
      case NotificationType.newEvent:
        return theme.colorScheme.primary;
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.eventCancelled:
        return Colors.red;
      case NotificationType.eventUpdated:
        return Colors.blue;
      case NotificationType.newParticipant:
      case NotificationType.newFollower:
        return Colors.green;
      case NotificationType.eventLiked:
        return Colors.pink;
      case NotificationType.newComment:
        return Colors.purple;
      case NotificationType.directMessage:
        return theme.colorScheme.primary;
      case NotificationType.system:
        return theme.colorScheme.onSurfaceVariant;
    }
  }
}
