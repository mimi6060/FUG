# PRD: Gestion des Evenements (FUG)

> Product Requirements Document - Feature Evenements

## Informations

| Champ | Valeur |
|-------|--------|
| **ID Feature** | EVT-001 |
| **Nom** | Gestion des Evenements FUG |
| **Statut** | Implemente |
| **Version** | 1.0 |
| **Date** | Janvier 2026 |
| **Equipe** | The Develobeers |

---

## 1. Resume Executif

Le systeme de gestion des evenements est le coeur de l'application FUG. Il permet aux utilisateurs de creer des "FUG" (evenements sociaux pour boire ensemble), de les decouvrir sur une carte, de consulter les details et de rejoindre ceux qui les interessent.

### Objectifs

- Permettre la creation d'evenements geolocalises
- Afficher les evenements a proximite sur une carte interactive
- Gerer le cycle de vie complet des evenements
- Faciliter la participation aux evenements

---

## 2. Contexte et Motivation

### Probleme

Les utilisateurs souhaitant sortir boire un verre n'ont pas toujours de compagnons disponibles. Il n'existe pas de solution simple pour:
- Declarer son intention de sortir a un lieu precis
- Decouvrir qui est disponible a proximite
- Rejoindre spontanement un groupe

### Solution

FUG permet de creer et decouvrir des evenements geolocalises ("FUG") avec:
- Une carte temps reel des evenements actifs
- Un systeme de participation simple
- Des notifications pour les evenements a proximite

---

## 3. User Stories

### US-EVT-01: Creer un evenement
**En tant qu'** utilisateur verifie
**Je veux** creer un evenement FUG
**Afin d'** inviter d'autres personnes a me rejoindre

**Criteres d'acceptation:**
- [ ] Formulaire avec titre, description, lieu, date/heure
- [ ] Selection du lieu sur une carte ou par adresse
- [ ] Option pour definir un nombre max de participants
- [ ] Choix de la categorie (bar, cafe, parc, etc.)
- [ ] Confirmation et publication de l'evenement

### US-EVT-02: Voir les evenements sur la carte
**En tant qu'** utilisateur
**Je veux** voir les evenements a proximite sur une carte
**Afin de** trouver une FUG pres de moi

**Criteres d'acceptation:**
- [ ] Carte centree sur ma position actuelle
- [ ] Marqueurs pour chaque evenement actif
- [ ] Cluster des marqueurs si trop nombreux
- [ ] Tap sur marqueur affiche preview de l'evenement
- [ ] Filtre par categorie et distance

### US-EVT-03: Voir la liste des evenements
**En tant qu'** utilisateur
**Je veux** voir une liste des evenements proches
**Afin de** les parcourir facilement

**Criteres d'acceptation:**
- [ ] Liste triee par distance ou date
- [ ] Carte de preview avec titre, lieu, participants
- [ ] Indicateur de distance
- [ ] Pull-to-refresh pour actualiser

### US-EVT-04: Voir le detail d'un evenement
**En tant qu'** utilisateur
**Je veux** consulter les details d'un evenement
**Afin de** decider si je veux y participer

**Criteres d'acceptation:**
- [ ] Titre, description complete
- [ ] Carte avec localisation
- [ ] Informations organisateur
- [ ] Liste des participants
- [ ] Bouton pour rejoindre/quitter

### US-EVT-05: Rejoindre un evenement
**En tant qu'** utilisateur
**Je veux** rejoindre un evenement
**Afin de** participer a la FUG

**Criteres d'acceptation:**
- [ ] Bouton "Rejoindre" sur le detail
- [ ] Verification que l'evenement n'est pas complet
- [ ] Confirmation de participation
- [ ] Ajout a mes evenements

### US-EVT-06: Quitter un evenement
**En tant que** participant
**Je veux** quitter un evenement
**Afin de** me desinscrire

**Criteres d'acceptation:**
- [ ] Bouton "Quitter" sur le detail (si participant)
- [ ] Confirmation avant desinscription
- [ ] Mise a jour du compteur de participants

### US-EVT-07: Annuler un evenement
**En tant que** createur d'un evenement
**Je veux** annuler mon evenement
**Afin d'** informer les participants

**Criteres d'acceptation:**
- [ ] Bouton "Annuler" visible uniquement pour le createur
- [ ] Confirmation avant annulation
- [ ] Notification aux participants
- [ ] Statut passe a "cancelled"

---

## 4. Specifications Techniques

### 4.1 Architecture

```
lib/features/events/
├── data/
│   └── event_repository.dart       # Implementation repository
├── domain/
│   └── event_model.dart            # Modele evenement
└── presentation/
    ├── create_event_screen.dart    # Creation evenement
    ├── event_detail_screen.dart    # Detail evenement
    ├── events_list_screen.dart     # Liste evenements
    └── events_map_screen.dart      # Carte evenements
```

### 4.2 EventModel

```dart
class EventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final String organizerName;
  final String categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String address;
  final double latitude;
  final double longitude;
  final String? venueName;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxParticipants;
  final int currentParticipants;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Proprietes calculees
  bool get isFull;
  int? get remainingSpots;
  bool get isOngoing;
  bool get isPast;
  bool get isUpcoming;
  Duration get duration;
}

enum EventStatus {
  draft,      // Brouillon
  published,  // Publie et visible
  cancelled,  // Annule
  completed,  // Termine
}
```

### 4.3 EventRepository

```dart
class EventRepository {
  // Liste des evenements
  Future<List<EventModel>> getEvents({
    double? latitude,
    double? longitude,
    double? radiusKm,
    EventStatus? status,
    String? category,
    int limit = 20,
    int offset = 0,
  });

  // Evenements proches
  Future<List<EventModel>> getNearbyEvents({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  });

  // Detail evenement
  Future<EventModel?> getEvent(String eventId);

  // CRUD
  Future<EventModel> createEvent(EventModel event);
  Future<EventModel> updateEvent(String eventId, Map<String, dynamic> data);
  Future<void> deleteEvent(String eventId);

  // Participation
  Future<void> joinEvent(String eventId, String userId);
  Future<void> leaveEvent(String eventId, String userId);
  Future<List<String>> getParticipants(String eventId);
}
```

### 4.4 Integration Appwrite

| Collection | Usage |
|------------|-------|
| `events` | Stockage des evenements |
| `event_participants` | Relations participation |

**Index Spatial:**
```yaml
Collection: events
Attribut: location (ou locationLat/locationLng)
Type: Spatial Point
```

**Requete geospatiale:**
```dart
Query.distanceLessThan('location', longitude, latitude, radiusMeters)
```

### 4.5 Categories

| Code | Libelle |
|------|---------|
| `bar` | Bar |
| `cafe` | Cafe |
| `restaurant` | Restaurant |
| `park` | Parc |
| `home` | Chez quelqu'un |
| `other` | Autre |

---

## 5. Ecrans UI

### 5.1 Events Map Screen

**Elements:**
- Carte OpenStreetMap/Google Maps plein ecran
- Marqueurs des evenements actifs
- Bouton "Ma position" pour recentrer
- Bottom sheet avec preview au tap sur marqueur
- FAB pour creer un evenement
- Filtres (categorie, distance)

### 5.2 Events List Screen

**Elements:**
- Barre de recherche
- Filtres rapides (Aujourd'hui, Ce soir, etc.)
- Liste des evenements avec:
  - Image ou icone categorie
  - Titre
  - Lieu
  - Distance
  - Nombre de participants
  - Heure de debut

### 5.3 Event Detail Screen

**Elements:**
- Image header (ou placeholder categorie)
- Titre et description
- Mini-carte avec lieu
- Adresse cliquable (ouvre navigation)
- Info organisateur (avatar, nom)
- Date et heure
- Nombre de participants / max
- Liste des participants (avatars)
- Bouton "Rejoindre" / "Quitter"
- Menu options (signaler, partager)

### 5.4 Create Event Screen

**Elements:**
- Champ titre
- Champ description
- Selecteur de categorie
- Picker de lieu (carte ou recherche adresse)
- Pickers date et heure debut
- Picker heure fin (optionnel)
- Champ nombre max participants (optionnel)
- Bouton "Publier"

---

## 6. Regles Metier

### R-EVT-01: Creation par utilisateurs verifies
Seuls les utilisateurs avec `is_verified == true` peuvent creer des evenements.

### R-EVT-02: Evenements publics
Tous les evenements sont visibles par tous les utilisateurs (pas d'evenements prives en V1).

### R-EVT-03: Auto-inscription createur
Le createur est automatiquement inscrit comme participant lors de la creation.

### R-EVT-04: Limite de participants
Si `max_participants` est defini, les inscriptions sont bloquees quand `current_participants >= max_participants`.

### R-EVT-05: Cycle de vie
```
draft --> published --> completed
               \
                --> cancelled
```
- `draft` -> `published`: Publication par le createur
- `published` -> `completed`: Automatique quand `end_date` est passee
- `published` -> `cancelled`: Annulation par le createur

### R-EVT-06: Modification limitee
Apres publication, seuls peuvent etre modifies:
- `description`
- `end_date`
- `max_participants`

Les champs `title`, `location`, `start_date` sont immutables.

### R-EVT-07: Desinscription possible
Un participant peut quitter tant que le statut n'est pas `completed` ou `cancelled`.

### R-EVT-08: Createur ne peut pas quitter
Le createur ne peut pas se desinscrire. Il doit annuler l'evenement.

---

## 7. Notifications

| Declencheur | Destinataire | Type |
|-------------|--------------|------|
| Nouvel evenement a proximite | Utilisateurs dans le rayon | Push |
| Nouveau participant | Createur | Push |
| Participant quitte | Createur | In-app |
| Evenement annule | Participants | Push |
| Rappel 1h avant | Participants | Push |

---

## 8. Metriques de Succes

| Metrique | Cible |
|----------|-------|
| Evenements crees / jour | > 50 |
| Taux de participation | > 30% |
| Evenements completes | > 70% |
| Temps moyen creation | < 90s |

---

## 9. Dependances

- **flutter_map** ou **google_maps_flutter**: Affichage carte
- **geolocator**: Position utilisateur
- **geocoding**: Recherche d'adresses
- **Appwrite SDK**: Backend

---

## 10. Points d'Attention

### Performance
- Pagination des resultats (Query.limit/offset)
- Denormalisation `currentParticipants` pour eviter les JOINs
- Cache local des evenements recemment consultes

### Geolocalisation
- Format GeoJSON: `[longitude, latitude]` (ordre important!)
- Rayon par defaut: 10 km
- Throttling des mises a jour de position (> 100m de changement)

### Securite
- Verifier `creator_id == current_user` pour modifications
- Rate limiting sur creation d'evenements

---

## 11. Historique

| Date | Version | Changement |
|------|---------|------------|
| Janvier 2026 | 1.0 | Version initiale implementee |

---

*Document genere pour le projet FUG - The Develobeers*
