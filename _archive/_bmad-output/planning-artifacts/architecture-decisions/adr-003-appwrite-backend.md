# ADR-003: Appwrite comme Backend-as-a-Service

> Architecture Decision Record

## Informations

| Champ | Valeur |
|-------|--------|
| **ID** | ADR-003 |
| **Statut** | Accepte |
| **Date** | Janvier 2026 |
| **Decideurs** | The Develobeers |

---

## Contexte

FUG necessite un backend robuste pour:
- Authentification (email, OAuth2)
- Base de donnees avec requetes geospatiales
- Stockage de fichiers (avatars, images)
- Functions serverless pour logique metier
- Notifications push
- Temps reel (WebSocket)

L'equipe The Develobeers est reduite (2-3 personnes) et souhaite:
- Minimiser le temps de developpement backend
- Eviter la gestion d'infrastructure complexe
- Garder le controle sur les donnees
- Avoir une solution evolutive

---

## Decision

Nous adoptons **Appwrite** (Self-Hosted ou Cloud) comme Backend-as-a-Service (BaaS) pour l'ensemble des services backend de FUG.

### Services Appwrite utilises

| Service | Usage FUG |
|---------|-----------|
| **Auth** | Authentification email, OAuth (Google, Facebook, Apple) |
| **Database** | Collections users, events, followers, etc. |
| **Storage** | Buckets avatars, event-images |
| **Functions** | gamification, cleanup-events, send-notification |
| **Realtime** | Subscriptions WebSocket |
| **Messaging** | Push notifications APNs/FCM |

### Deploiement

- **Developpement**: Docker Compose local
- **Staging/Production**: Appwrite Cloud EU

---

## Justification

### Avantages d'Appwrite

1. **Open Source**
   - Code source disponible
   - Pas de vendor lock-in
   - Communaute active

2. **Self-hosted possible**
   - Controle total des donnees
   - Conformite RGPD facilitee
   - Pas de dependance cloud

3. **Suite complete**
   - Un seul outil pour tous les besoins
   - APIs coherentes
   - SDK Flutter officiel

4. **Support Geospatial**
   - Type Spatial natif
   - Query.distanceLessThan()
   - Index GIST

5. **Functions Serverless**
   - Support Dart natif
   - Triggers sur events
   - Scheduled functions

6. **SDK Flutter officiel**
   - Bien maintenu
   - Documentation complete
   - Types Dart natifs

7. **Console d'administration**
   - UI moderne
   - Gestion des donnees
   - Logs et monitoring

### Comparaison avec alternatives

| Critere | Appwrite | Firebase | Supabase | Custom API |
|---------|----------|----------|----------|------------|
| Open Source | Oui | Non | Oui | N/A |
| Self-hosted | Oui | Non | Oui | Oui |
| Geospatial | Oui | Non* | Oui (PostGIS) | Variable |
| SDK Flutter | Officiel | Officiel | Communaute | Custom |
| Functions Dart | Oui | Non | Non | Oui |
| Complexite | Faible | Faible | Moyenne | Elevee |
| Cout | Gratuit/Cloud | Pay-as-you-go | Freemium | Variable |

*Firebase necessite GeoFire ou Cloud Functions pour geospatial

---

## Alternatives Considerees

### 1. Firebase

**Avantages:**
- Tres populaire
- Documentation excellente
- Integration Google
- Scaling automatique

**Inconvenients:**
- Vendor lock-in Google
- Pas de self-hosting
- Geospatial non-natif
- Pas de Functions Dart
- RGPD complexe (donnees US)

**Raison du rejet:** Vendor lock-in et absence de geospatial natif.

### 2. Supabase

**Avantages:**
- PostgreSQL (puissant)
- PostGIS pour geospatial
- Open source
- API auto-generee

**Inconvenients:**
- SDK Flutter non-officiel
- Functions en Deno/TypeScript
- Self-hosting plus complexe
- Moins mature

**Raison du rejet:** SDK Flutter moins mature, Functions pas en Dart.

### 3. API Custom (Node.js/Dart)

**Avantages:**
- Controle total
- Pas de limites
- Architecture sur mesure

**Inconvenients:**
- Temps de developpement eleve
- Maintenance infrastructure
- Securite a gerer
- Auth, storage a reimplementer

**Raison du rejet:** Trop de temps et ressources pour une petite equipe.

### 4. AWS Amplify

**Avantages:**
- Services AWS integres
- Scaling automatique
- GraphQL

**Inconvenients:**
- Vendor lock-in AWS
- Complexe a configurer
- Cout peut exploser
- SDK Flutter limite

**Raison du rejet:** Complexite et vendor lock-in.

---

## Consequences

### Positives

- Developpement backend accelere
- Infrastructure geree (Cloud) ou controlee (Self-hosted)
- Coherence des APIs
- SDK Flutter officiel et maintenu
- Geospatial natif pour FUG

### Negatives

- Dependance a Appwrite (meme si open source)
- Limites des queries (pas de SQL brut)
- Certaines features avancees manquantes
- Self-hosted necessite DevOps

### Neutres

- Migration possible vers autre solution
- Apprentissage specifique Appwrite

---

## Architecture Technique

### Schema des Collections

```
+-------------------+       +-------------------+
|      users        |       |      events       |
+-------------------+       +-------------------+
| $id               |       | $id               |
| email             |       | creatorId ------->|
| name              |       | title             |
| locationLat       |       | locationLat       |
| locationLng       |       | locationLng       |
| murgilarityScore  |       | status            |
| level             |       | startDate         |
+-------------------+       +-------------------+
        |                           |
        v                           v
+-------------------+       +-------------------+
|    followers      |       |event_participants |
+-------------------+       +-------------------+
| followerId ------>|       | eventId --------->|
| followeeId ------>|       | userId ---------->|
+-------------------+       | status            |
                            +-------------------+
```

### Requetes Geospatiales

```dart
// Recherche d'evenements dans un rayon
final events = await databases.listDocuments(
  databaseId: 'fug_database',
  collectionId: 'events',
  queries: [
    // Note: Appwrite utilise lat/lng separees, pas Spatial Point
    // Calcul de distance cote client ou via Function
    Query.equal('status', 'published'),
    Query.orderAsc('startDate'),
    Query.limit(50),
  ],
);
```

### Functions

```dart
// functions/gamification/src/main.dart
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> main(final context) async {
  final client = Client()
    .setEndpoint(Platform.environment['APPWRITE_ENDPOINT']!)
    .setProject(Platform.environment['APPWRITE_PROJECT']!)
    .setKey(Platform.environment['APPWRITE_API_KEY']!);

  final databases = Databases(client);

  // Logique gamification...

  return context.res.json({'success': true});
}
```

### Realtime

```dart
// Subscription aux nouveaux evenements
final subscription = realtime.subscribe([
  'databases.fug_database.collections.events.documents',
]);

subscription.stream.listen((event) {
  if (event.events.contains('databases.*.collections.*.documents.*.create')) {
    // Nouvel evenement cree
    final newEvent = EventModel.fromJson(event.payload);
    // Notifier l'utilisateur si dans son rayon
  }
});
```

---

## Configuration

### Docker Compose (Developpement)

```yaml
# infrastructure/docker-compose.yml
version: '3.8'

services:
  appwrite:
    image: appwrite/appwrite:1.5
    ports:
      - 80:80
      - 443:443
    volumes:
      - appwrite-uploads:/storage/uploads
      - appwrite-cache:/storage/cache
    environment:
      - _APP_ENV=development
      - _APP_OPENSSL_KEY_V1=your-secret-key
```

### SDK Flutter

```dart
// lib/core/services/appwrite_service.dart
class AppwriteService {
  static final instance = AppwriteService._();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;
  late final Realtime realtime;

  AppwriteService._() {
    client = Client()
      .setEndpoint(AppwriteConfig.endpoint)
      .setProject(AppwriteConfig.projectId)
      .setSelfSigned(status: AppwriteConfig.isDevelopment);

    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }
}
```

---

## Securite

### Permissions Collections

```yaml
users:
  Create: users (inscription)
  Read: user:{userId} (son profil), any (profils publics)
  Update: user:{userId}
  Delete: user:{userId}

events:
  Create: users
  Read: any
  Update: user:{creatorId}
  Delete: user:{creatorId}

event_participants:
  Create: users
  Read: any
  Update: user:{userId}
  Delete: user:{userId}
```

### API Keys

- **Development**: Cle locale dans `.env`
- **Production**: Variables d'environnement Appwrite Cloud
- **Functions**: Cles avec permissions limitees

---

## References

- [Appwrite Documentation](https://appwrite.io/docs)
- [Appwrite Flutter SDK](https://appwrite.io/docs/sdks#flutter)
- [Appwrite Self-Hosted](https://appwrite.io/docs/self-hosting)
- [Appwrite Functions](https://appwrite.io/docs/functions)

---

## Revision

| Date | Modification | Auteur |
|------|--------------|--------|
| Janvier 2026 | Creation initiale | The Develobeers |

---

*Document genere pour le projet FUG - The Develobeers*
