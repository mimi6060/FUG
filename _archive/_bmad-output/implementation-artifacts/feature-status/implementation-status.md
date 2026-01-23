# Statut d'Implementation - FUG

> Suivi de l'avancement du developpement

**Derniere mise a jour:** Janvier 2026

---

## Vue d'Ensemble

| Categorie | Termine | En cours | A faire | Total |
|-----------|---------|----------|---------|-------|
| Core/Infrastructure | 5 | 0 | 2 | 7 |
| Authentification | 6 | 1 | 1 | 8 |
| Evenements | 5 | 2 | 3 | 10 |
| Social | 3 | 1 | 2 | 6 |
| Gamification | 2 | 0 | 6 | 8 |
| Notifications | 1 | 1 | 3 | 5 |
| **TOTAL** | **22** | **5** | **17** | **44** |

**Progression globale:** 50% termine, 11% en cours

---

## 1. Core / Infrastructure

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| Configuration Appwrite | `lib/core/config/appwrite_config.dart` | Environnements dev/prod |
| Service Appwrite | `lib/core/services/appwrite_service.dart` | Singleton client |
| Router | `lib/core/router/app_router.dart` | GoRouter configure |
| Provider Auth | `lib/core/providers/auth_provider.dart` | Etat authentification |
| Provider Events | `lib/core/providers/events_provider.dart` | Liste evenements |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| Gestion erreurs centralisee | Haute | `lib/core/errors/` |
| Service offline/cache | Moyenne | Hive pour cache local |

---

## 2. Feature: Authentification

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| AuthRepository | `lib/features/auth/data/auth_repository.dart` | Complet |
| UserModel | `lib/features/auth/domain/user_model.dart` | Avec serialisation JSON |
| LoginScreen | `lib/features/auth/presentation/login_screen.dart` | UI fonctionnelle |
| RegisterScreen | `lib/features/auth/presentation/register_screen.dart` | Avec validation |
| Connexion email | - | Via AuthRepository |
| Deconnexion | - | Via AuthRepository |

### En Cours

| Composant | Progression | Bloquant |
|-----------|-------------|----------|
| Connexion OAuth | 50% | Configuration providers Google/Apple |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| Verification email | Haute | URL callback a configurer |

---

## 3. Feature: Evenements

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| EventModel | `lib/features/events/domain/event_model.dart` | Complet avec props calculees |
| EventRepository | `lib/features/events/data/event_repository.dart` | CRUD basique |
| EventsListScreen | `lib/features/events/presentation/events_list_screen.dart` | Liste avec cards |
| EventDetailScreen | `lib/features/events/presentation/event_detail_screen.dart` | Affichage detail |
| CreateEventScreen | `lib/features/events/presentation/create_event_screen.dart` | Formulaire creation |

### En Cours

| Composant | Progression | Bloquant |
|-----------|-------------|----------|
| EventsMapScreen | 70% | Integration flutter_map |
| Location Provider | 60% | Permissions a finaliser |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| Participation evenements | Haute | Collection event_participants |
| Recherche geospatiale | Haute | Query distanceLessThan |
| Filtres et tri | Moyenne | Par categorie, date, distance |

---

## 4. Feature: Social (Follow)

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| SocialRepository | `lib/features/social/data/social_repository.dart` | Follow/unfollow |
| FollowersListScreen | `lib/features/social/presentation/followers_list_screen.dart` | Liste followers |
| UserSearchScreen | `lib/features/social/presentation/user_search_screen.dart` | Recherche utilisateurs |

### En Cours

| Composant | Progression | Bloquant |
|-----------|-------------|----------|
| Compteurs followers | 40% | Denormalisation a implementer |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| Feed personnalise | Moyenne | FUG des personnes suivies |
| Suggestions follow | Basse | Basees sur localisation |

---

## 5. Feature: Profil

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| ProfileModel | `lib/features/profile/domain/profile_model.dart` | Donnees profil |
| ProfileState | `lib/features/profile/domain/profile_state.dart` | Etat du profil |
| ProfileScreen | `lib/features/profile/presentation/profile_screen.dart` | Affichage profil |
| ProfileRepository | `lib/features/profile/data/profile_repository.dart` | CRUD profil |
| EditProfileScreen | `lib/features/profile/presentation/edit_profile_screen.dart` | Edition profil |

---

## 6. Feature: Gamification

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| Champs UserModel | `lib/features/auth/domain/user_model.dart` | points, level |
| Affichage score | - | Dans ProfileScreen |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| Collection achievements | Haute | Schema a creer |
| Collection user_achievements | Haute | Badges debloques |
| Function gamification | Haute | Attribution points automatique |
| AchievementsScreen | Moyenne | Liste des badges |
| LeaderboardScreen | Moyenne | Classement utilisateurs |
| Notifications badges | Basse | Push au deblocage |

---

## 7. Feature: Notifications

### Termine

| Composant | Fichier | Notes |
|-----------|---------|-------|
| NotificationModel | `lib/features/notifications/domain/notification_model.dart` | Modele |

### En Cours

| Composant | Progression | Bloquant |
|-----------|-------------|----------|
| NotificationsScreen | 50% | UI a finaliser |

### A Faire

| Composant | Priorite | Notes |
|-----------|----------|-------|
| NotificationRepository | Haute | Lecture/marquage lu |
| Push notifications | Haute | FCM/APNs |
| Function send-notification | Moyenne | Envoi automatique |

---

## Collections Appwrite

### Creees

| Collection | Attributs | Index |
|------------|-----------|-------|
| `users` | Complet | email, username uniques |
| `events` | Complet | status, startDate |
| `followers` | Complet | followerId, followeeId |

### A Creer

| Collection | Priorite | Schema defini |
|------------|----------|---------------|
| `event_participants` | Haute | Oui |
| `achievements` | Moyenne | Oui |
| `user_achievements` | Moyenne | Oui |
| `notifications` | Moyenne | Oui |

---

## Appwrite Functions

### A Developper

| Function | Trigger | Priorite | Notes |
|----------|---------|----------|-------|
| `gamification` | Event DB | Haute | Attribution points |
| `join-event` | HTTP | Haute | Inscription/desinscription |
| `follow-user` | HTTP | Moyenne | Avec notification |
| `send-notification` | Event | Moyenne | Push FCM/APNs |
| `cleanup-events` | Schedule | Basse | Archive evenements |
| `nearby-events` | HTTP | Basse | Recherche geospatiale |

---

## Tests

### Couverture Actuelle

| Module | Coverage | Cible |
|--------|----------|-------|
| auth | 20% | 80% |
| events | 15% | 80% |
| social | 10% | 80% |
| profile | 25% | 80% |
| core | 30% | 80% |

### Tests Manquants

- [ ] Tests unitaires repositories
- [ ] Tests widgets screens principaux
- [ ] Tests integration Appwrite
- [ ] Tests E2E parcours utilisateur

---

## Prochaines Etapes (Sprint)

### Sprint 1 (Semaine prochaine)

1. Finaliser EventsMapScreen avec flutter_map
2. Implementer participation aux evenements
3. Creer collection event_participants
4. Tests unitaires EventRepository

### Sprint 2

1. Recherche geospatiale complete
2. Notifications push (FCM)
3. Function gamification
4. Collection achievements

### Sprint 3

1. Ecran badges
2. Ecran classement
3. Feed personnalise
4. Tests integration

---

## Blocages Actuels

| Blocage | Impact | Solution proposee | Responsable |
|---------|--------|-------------------|-------------|
| Configuration OAuth Google | Moyen | Creer projet Google Cloud | PAC |
| Permissions location iOS | Faible | Ajouter Info.plist | LAM |

---

## Notes de Version

### v0.1.0 (Actuel)

- Auth email fonctionnelle
- CRUD evenements basique
- Profil utilisateur
- Follow/unfollow

### v0.2.0 (Prochaine)

- Carte des evenements
- Participation evenements
- Recherche geospatiale
- Notifications in-app

### v1.0.0 (MVP)

- Toutes features core
- Gamification complete
- Push notifications
- Tests > 80%

---

*Document maintenu par The Develobeers*
