import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/events/presentation/events_map_screen.dart';
import '../../features/events/presentation/events_list_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/events/presentation/create_event_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/social/presentation/user_search_screen.dart';
import '../../features/social/presentation/followers_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/delete_account_screen.dart';

/// Cle de navigation globale
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Provider pour le GoRouter
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,

    /// Gestion de la redirection selon l'etat d'authentification
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // Si pas connecte et pas sur une page d'auth, rediriger vers login
      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // Si connecte et sur une page d'auth, rediriger vers home
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/home';
      }

      return null;
    },

    /// Configuration des routes
    routes: [
      // Route racine - redirection automatique
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),

      // ================================================
      // Routes d'authentification
      // ================================================
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ================================================
      // Routes principales
      // ================================================
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const EventsMapScreen(),
      ),

      // ================================================
      // Routes des evenements
      // ================================================
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventsListScreen(),
        routes: [
          // Creation d'evenement
          GoRoute(
            path: 'create',
            name: 'createEvent',
            builder: (context, state) => const CreateEventScreen(),
          ),
          // Recherche d'evenements
          GoRoute(
            path: 'search',
            name: 'searchEvents',
            builder: (context, state) => const UserSearchScreen(),
          ),
          // Detail d'un evenement
          GoRoute(
            path: ':id',
            name: 'eventDetail',
            builder: (context, state) {
              final eventId = state.pathParameters['id']!;
              return EventDetailScreen(eventId: eventId);
            },
            routes: [
              // Edition d'evenement
              GoRoute(
                path: 'edit',
                name: 'editEvent',
                builder: (context, state) {
                  final eventId = state.pathParameters['id']!;
                  // TODO: Creer EditEventScreen
                  return EventDetailScreen(eventId: eventId);
                },
              ),
            ],
          ),
        ],
      ),

      // ================================================
      // Routes du profil
      // ================================================
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          // Edition du profil
          GoRoute(
            path: 'edit',
            name: 'editProfile',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),

      // Profil d'un autre utilisateur
      GoRoute(
        path: '/users/:userId',
        name: 'userProfile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ProfileScreen(userId: userId);
        },
        routes: [
          // Followers d'un utilisateur
          GoRoute(
            path: 'followers',
            name: 'userFollowers',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return FollowersListScreen(
                userId: userId,
                isFollowers: true,
              );
            },
          ),
          // Personnes suivies par un utilisateur
          GoRoute(
            path: 'following',
            name: 'userFollowing',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              return FollowersListScreen(
                userId: userId,
                isFollowers: false,
              );
            },
          ),
          // Evenements d'un utilisateur
          GoRoute(
            path: 'events',
            name: 'userEvents',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              // TODO: Creer UserEventsScreen
              return ProfileScreen(userId: userId);
            },
          ),
        ],
      ),

      // ================================================
      // Routes des notifications
      // ================================================
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ================================================
      // Routes de recherche
      // ================================================
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const UserSearchScreen(),
      ),

      // ================================================
      // Routes des parametres
      // ================================================
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          // Suppression de compte (RGPD)
          GoRoute(
            path: 'delete-account',
            name: 'deleteAccount',
            builder: (context, state) => const DeleteAccountScreen(),
          ),
        ],
      ),
    ],

    /// Page d'erreur 404
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );
});

/// Ecran d'erreur
class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page non trouvee',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (error != null)
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('Retour a l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
