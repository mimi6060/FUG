# Architecture Technique - FUG

> Documentation d'architecture pour les agents BMAD-METHOD

## Vue d'Ensemble

FUG utilise une architecture moderne basee sur **Flutter** pour le frontend mobile et **Appwrite** comme Backend-as-a-Service (BaaS).

```
+------------------------------------------------------------------+
|                        CLIENTS                                    |
+------------------------------------------------------------------+
|   +------------------------+      +------------------------+     |
|   |      Flutter App       |      |      Flutter Web       |     |
|   |   (Android + iOS)      |      |        (PWA)           |     |
|   +-----------+------------+      +-----------+------------+     |
|               |                               |                  |
|               +---------------+---------------+                  |
|                               |                                  |
+------------------------------------------------------------------+
                                |
                          HTTPS/WSS
                                |
+------------------------------------------------------------------+
|                     APPWRITE BACKEND                              |
+------------------------------------------------------------------+
|   +-------------------------------------------------------+      |
|   |                   APPWRITE CLOUD                      |      |
|   +-------------------------------------------------------+      |
|   |  +-------+  +-------+  +-------+  +-------+  +-------+|      |
|   |  | Auth  |  |  DB   |  |Storage|  |Realtime| |Funcs  ||      |
|   |  +-------+  +-------+  +-------+  +-------+  +-------+|      |
|   +-------------------------------------------------------+      |
+------------------------------------------------------------------+
```

---

## Architecture Frontend (Flutter)

### Clean Architecture

Le projet suit les principes de **Clean Architecture** avec separation claire des responsabilites:

```
lib/
├── core/                      # Couche infrastructure partagee
│   ├── config/
│   │   ├── app_config.dart    # Configuration par environnement
│   │   └── appwrite_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── services/
│   │   ├── appwrite_service.dart
│   │   └── location_service.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
│
├── features/                  # Features par domaine
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_remote_datasource.dart
│   │   ├── domain/
│   │   │   ├── user_model.dart
│   │   │   └── auth_repository_interface.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── register_screen.dart
│   │       └── widgets/
│   │           └── auth_form_widget.dart
│   │
│   ├── events/
│   │   ├── data/
│   │   │   └── event_repository.dart
│   │   ├── domain/
│   │   │   └── event_model.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── profile/
│   ├── notifications/
│   └── gamification/
│
└── main.dart
```

### Couches

#### 1. Presentation Layer

- **Screens**: Pages de l'application
- **Widgets**: Composants reutilisables
- **Providers**: Gestion d'etat avec Riverpod

```dart
// Exemple: Provider Riverpod
final eventListProvider = FutureProvider<List<EventModel>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getNearbyEvents(
    latitude: userLocation.latitude,
    longitude: userLocation.longitude,
    radiusKm: 10,
  );
});
```

#### 2. Domain Layer

- **Models**: Classes de donnees avec Equatable
- **Repository Interfaces**: Contrats abstraits

```dart
// Exemple: Model
class EventModel extends Equatable {
  final String id;
  final String title;
  final GeoPoint location;
  final DateTime startsAt;

  const EventModel({...});

  factory EventModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;

  @override
  List<Object?> get props => [id, title, location, startsAt];
}
```

#### 3. Data Layer

- **Repositories**: Implementation des interfaces
- **Data Sources**: Interaction avec Appwrite

```dart
// Exemple: Repository
class EventRepository {
  final Databases _databases;

  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final response = await _databases.listDocuments(
      databaseId: 'fug_database',
      collectionId: 'events',
      queries: [
        Query.distanceLessThan('location', longitude, latitude, radiusKm * 1000),
        Query.equal('status', 'active'),
      ],
    );
    return response.documents.map((d) => EventModel.fromJson(d.data)).toList();
  }
}
```

---

## Architecture Backend (Appwrite)

### Services Utilises

| Service | Usage | Configuration |
|---------|-------|---------------|
| **Auth** | Authentification | OAuth2 (Google, Facebook, Apple), Email |
| **Database** | Stockage donnees | Collections avec indexes Spatial |
| **Storage** | Fichiers | Buckets: avatars, event-images |
| **Functions** | Logique metier | Dart, Node.js serverless |
| **Realtime** | Temps reel | WebSocket subscriptions |
| **Messaging** | Notifications | APNs (iOS), FCM (Android) |

### Schema de Base de Donnees

```
+-------------------+       +-------------------+
|      users        |       |      events       |
+-------------------+       +-------------------+
| $id               |       | $id               |
| email             |       | creator_id ------>|
| username          |       | title             |
| location (SPATIAL)|       | location (SPATIAL)|
| murgilarity_score |       | starts_at         |
| level             |       | status            |
+-------------------+       +-------------------+
        |                           |
        v                           v
+-------------------+       +-------------------+
|    followers      |       |event_participants |
+-------------------+       +-------------------+
| follower_id ----->|       | event_id -------->|
| followee_id ----->|       | user_id --------->|
+-------------------+       | status            |
                            +-------------------+
```

### Collections

#### users

| Attribut | Type | Description |
|----------|------|-------------|
| `email` | String | Email unique |
| `username` | String | Pseudo unique (3-30 car.) |
| `location` | Spatial Point | Position GPS |
| `murgilarity_score` | Integer | Score gamification |
| `level` | Integer | Niveau utilisateur |
| `notification_radius` | Integer | Rayon notifications (km) |
| `is_verified` | Boolean | Email verifie |
| `is_active` | Boolean | Compte actif |

**Indexes**:
- `email`: Unique
- `username`: Unique
- `location`: Spatial (GIST)
- `murgilarity_score`: Descending

#### events

| Attribut | Type | Description |
|----------|------|-------------|
| `creator_id` | String | ID createur |
| `title` | String | Titre (100 car. max) |
| `location` | Spatial Point | Coordonnees GPS |
| `address` | String | Adresse formatee |
| `starts_at` | DateTime | Date/heure debut |
| `status` | Enum | draft/active/ongoing/completed/cancelled |
| `current_participants` | Integer | Compteur denormalise |

**Indexes**:
- `location`: Spatial (GIST)
- `status`: Key
- `starts_at`: Key

---

## Appwrite Functions

### Architecture des Functions

```
functions/
├── follow-user/           # Gestion follow/unfollow
│   ├── src/main.dart
│   └── pubspec.yaml
│
├── join-event/            # Inscription aux evenements
│   ├── src/main.dart
│   └── pubspec.yaml
│
├── nearby-events/         # Recherche geospatiale
│   ├── src/main.dart
│   └── pubspec.yaml
│
├── gamification/          # Attribution points/badges
│   ├── src/main.dart
│   └── pubspec.yaml
│
├── send-notification/     # Push notifications
│   └── src/main.js        # Node.js
│
└── cleanup-events/        # Archive evenements
    ├── src/main.dart
    └── pubspec.yaml
```

### Triggers

| Function | Trigger | Description |
|----------|---------|-------------|
| `follow-user` | HTTP POST | Cree/supprime une relation follow |
| `join-event` | HTTP POST | Inscrit/desinscrit un participant |
| `nearby-events` | HTTP GET | Retourne les events dans un rayon |
| `gamification` | Event (DB) | Declenche sur create/update |
| `send-notification` | Event (DB) | Sur creation notification |
| `cleanup-events` | Schedule | Toutes les heures (cron) |

---

## Requetes Geospatiales

### Configuration Spatial

Appwrite supporte les colonnes de type **Spatial** pour les coordonnees:

```yaml
Attribut: location
Type: Spatial
Subtype: Point
```

Format de stockage (GeoJSON):
```json
{
  "type": "Point",
  "coordinates": [longitude, latitude]
}
```

> **Important**: L'ordre est `[longitude, latitude]` selon le standard GeoJSON.

### Query.distanceLessThan()

```dart
// Rechercher dans un rayon de 5 km
final events = await databases.listDocuments(
  databaseId: 'fug_database',
  collectionId: 'events',
  queries: [
    Query.distanceLessThan(
      'location',     // Attribut
      4.3528,         // Longitude
      50.8485,        // Latitude
      5000,           // Rayon en metres
    ),
    Query.equal('status', 'active'),
    Query.orderAsc('starts_at'),
  ],
);
```

---

## Realtime

### Subscriptions

```dart
// S'abonner aux evenements d'une collection
final subscription = realtime.subscribe([
  'databases.fug_database.collections.events.documents',
]);

subscription.stream.listen((event) {
  if (event.events.contains('databases.*.collections.*.documents.*.create')) {
    // Nouvel evenement cree
    final newEvent = EventModel.fromJson(event.payload);
    // Mettre a jour l'UI
  }
});
```

### Cas d'Usage

1. **Nouveaux evenements a proximite** - Notifier en temps reel
2. **Mises a jour d'un evenement** - Participants, statut
3. **Nouvelles notifications** - Badge, compteur

---

## Gestion Hors-ligne

### Cache Local (Hive)

```dart
@HiveType(typeId: 0)
class CachedEvent extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime cachedAt;
}
```

### File d'Attente Actions

Les actions effectuees hors-ligne sont mises en queue et synchronisees au retour de la connexion:

```dart
class OfflineSyncService {
  Future<void> queueAction(String type, Map<String, dynamic> payload);
  Future<void> syncPendingActions();
}
```

---

## Environnements

| Environnement | Appwrite | Usage |
|---------------|----------|-------|
| **development** | Docker local | Dev, tests |
| **staging** | Cloud EU | Pre-production |
| **production** | Cloud EU | Production |

### Configuration Multi-Environnement

```dart
enum Environment { development, staging, production }

class AppConfig {
  final String appwriteEndpoint;
  final String appwriteProjectId;

  static void initialize(Environment env) {
    switch (env) {
      case Environment.development:
        // localhost:8080
        break;
      case Environment.staging:
        // cloud.appwrite.io, projet staging
        break;
      case Environment.production:
        // cloud.appwrite.io, projet prod
        break;
    }
  }
}
```

---

## Securite

### Authentification

- **OAuth2**: Google, Facebook, Apple
- **Email/Password**: Avec verification email
- **Sessions**: 365 jours (mobile), 7 jours (web)

### Permissions Appwrite

```yaml
users:
  Read: user:{userId}
  Update: user:{userId}
  Delete: user:{userId}

events:
  Create: users
  Read: any
  Update: user:{creator_id}
  Delete: user:{creator_id}
```

### RGPD

- Export des donnees utilisateur
- Suppression complete du compte
- Anonymisation des evenements

---

## Performance

### Optimisations

1. **Pagination**: `Query.limit()` + `Query.offset()`
2. **Denormalisation**: `current_participants` dans events
3. **Cache local**: Hive pour donnees frequentes
4. **Lazy loading**: Images, listes longues

### Metriques Cibles

| Metrique | Cible |
|----------|-------|
| Time to First Byte | < 200ms |
| First Contentful Paint | < 1.5s |
| API Response Time | < 500ms |
| Offline Ready | Oui |

---

*Derniere mise a jour: Janvier 2026*
*The Develobeers - Projet FUG*
