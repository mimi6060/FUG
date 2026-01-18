/// Fichier d'export pour tous les providers de l'application
///
/// Ce fichier centralise les exports de tous les providers Riverpod
/// pour faciliter les imports dans l'application.
library;

// Auth providers
export 'auth_provider.dart';

// Events providers
export 'events_provider.dart';

// Location providers
export 'location_provider.dart';

// Re-export des providers depuis les features pour compatibilite
export '../../features/profile/presentation/profile_screen.dart'
    show profileRepositoryProvider, currentProfileProvider, profileProvider;

export '../../features/notifications/presentation/notifications_screen.dart'
    show notificationRepositoryProvider, notificationsProvider, unreadCountProvider;
