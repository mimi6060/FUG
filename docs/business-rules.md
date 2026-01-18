# Regles Metier - FUG

> Documentation des regles metier pour les agents BMAD-METHOD

## Lexique FUG

### Termes Principaux

| Terme | Definition | Synonymes |
|-------|------------|-----------|
| **FUG** | Evenement social pour boire ensemble | Guinze, Murge |
| **Preum's** | Utilisateur qui cree une FUG | Createur, Initiateur |
| **Participant** | Utilisateur qui rejoint une FUG | Guinzeur |
| **Murgilarity** | Score de gamification | Murge + Hilarite/Popularite |
| **Follower** | Utilisateur suivant un autre | Abonne |
| **Followee** | Utilisateur suivi | - |

### Statuts Utilisateur

| Statut | Description |
|--------|-------------|
| `verified` | Email verifie, compte actif |
| `unverified` | Email non verifie |
| `banned` | Compte suspendu |
| `inactive` | Compte desactive par l'utilisateur |

### Statuts Evenement

| Statut | Description |
|--------|-------------|
| `draft` | Evenement en brouillon (non publie) |
| `active` | Evenement publie, en attente de debut |
| `ongoing` | Evenement en cours |
| `completed` | Evenement termine |
| `cancelled` | Evenement annule |

---

## Regles d'Inscription

### R-USR-01: Age Minimum

> **Regle**: Un utilisateur doit avoir l'age legal pour consommer de l'alcool dans son pays.

**Implementation**:
```dart
bool isEligible(DateTime birthDate, String countryCode) {
  final minAge = getMinimumDrinkingAge(countryCode); // 18 en France, 21 aux USA
  final age = DateTime.now().difference(birthDate).inDays ~/ 365;
  return age >= minAge;
}
```

**Contraintes**:
- Verification obligatoire a l'inscription
- Date de naissance stockee et immutable
- Verification du pays via IP ou declaration

### R-USR-02: Unicite Email/Username

> **Regle**: L'email et le username doivent etre uniques dans le systeme.

**Implementation**:
- Index `Unique` sur `email` dans Appwrite
- Index `Unique` sur `username` dans Appwrite
- Verification cote client avant soumission

### R-USR-03: Format Username

> **Regle**: Le username doit contenir entre 3 et 30 caracteres alphanumeriques.

**Validation**:
```dart
final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
bool isValidUsername(String username) => usernameRegex.hasMatch(username);
```

---

## Regles des Evenements (FUG)

### R-EVT-01: Creation d'un Evenement

> **Regle**: Seul un utilisateur verifie peut creer un evenement.

**Conditions**:
- `is_verified == true`
- `is_active == true`
- `is_banned == false`

**Donnees obligatoires**:
- `title` (1-100 caracteres)
- `location` (coordonnees GPS valides)
- `address` (adresse formatee)
- `starts_at` (date future)

### R-EVT-02: Evenement Toujours Public

> **Regle**: Un evenement est toujours visible par tous les utilisateurs.

**Justification**: FUG encourage la decouverte et les rencontres spontanees.

**Exception future**: Option `followers_only` prevue pour V2.

### R-EVT-03: Limite de Participants

> **Regle**: Un createur peut definir une limite de participants.

**Comportement**:
- `max_participants = null` : Illimite
- `max_participants > 0` : Limite stricte
- `current_participants >= max_participants` : Evenement complet

**Implementation**:
```dart
bool canJoin(EventModel event) {
  if (event.maxParticipants == null) return true;
  return event.currentParticipants < event.maxParticipants;
}
```

### R-EVT-04: Cycle de Vie Evenement

> **Regle**: Un evenement suit un cycle de vie strict.

```
draft --> active --> ongoing --> completed
                 \
                  --> cancelled
```

**Transitions automatiques** (via `cleanup-events` function):
- `active` -> `ongoing` : Quand `starts_at` est passe
- `ongoing` -> `completed` : Quand `ends_at` est passe OU 6h apres `starts_at`

**Transitions manuelles**:
- `draft` -> `active` : Publication par le createur
- `active/ongoing` -> `cancelled` : Annulation par le createur

### R-EVT-05: Modification d'Evenement

> **Regle**: Seul le createur peut modifier un evenement.

**Champs modifiables**:
- `title`
- `description`
- `ends_at`
- `max_participants`

**Champs immutables apres creation**:
- `location`
- `address`
- `starts_at` (si evenement deja `active`)

### R-EVT-06: Suppression Interdite

> **Regle**: Un evenement ne peut pas etre supprime, seulement annule.

**Justification**: Conservation de l'historique pour les statistiques et la gamification.

---

## Regles de Participation

### R-PAR-01: Auto-inscription Createur

> **Regle**: Le createur est automatiquement inscrit comme participant.

**Implementation** (dans `create-event` function):
```dart
// Creer l'evenement
final event = await databases.createDocument(...);

// Inscrire automatiquement le createur
await databases.createDocument(
  collectionId: 'event_participants',
  data: {
    'event_id': event.$id,
    'user_id': creatorId,
    'status': 'confirmed',
    'role': 'creator',
  },
);
```

### R-PAR-02: Une Seule Participation Active

> **Regle**: Un utilisateur ne peut avoir qu'une seule participation active par evenement.

**Verification**:
```dart
final existing = await databases.listDocuments(
  queries: [
    Query.equal('event_id', eventId),
    Query.equal('user_id', userId),
    Query.notEqual('status', 'left'),
  ],
);
if (existing.documents.isNotEmpty) {
  throw Exception('Deja inscrit');
}
```

### R-PAR-03: Desinscription Possible

> **Regle**: Un participant peut se desinscrire tant que l'evenement n'est pas termine.

**Contraintes**:
- Status evenement != `completed`
- Status evenement != `cancelled`
- Role != `creator` (le createur ne peut pas quitter)

**Comportement**:
- Le statut de participation passe a `left`
- `current_participants` est decremente

### R-PAR-04: Le Createur ne Peut Pas Quitter

> **Regle**: Le createur d'un evenement ne peut pas se desinscrire.

**Alternative**: Le createur peut annuler l'evenement.

---

## Regles de Follow

### R-FOL-01: Follow Reciprocite Non Obligatoire

> **Regle**: Le follow n'est pas reciproque par defaut.

- A suit B != B suit A
- Chaque relation de follow est independante

### R-FOL-02: Auto-Follow Interdit

> **Regle**: Un utilisateur ne peut pas se suivre lui-meme.

```dart
if (followerId == followeeId) {
  throw Exception('Impossible de se suivre soi-meme');
}
```

### R-FOL-03: Notification de Nouveau Follower

> **Regle**: Un utilisateur est notifie quand il gagne un nouveau follower.

**Implementation**:
- Creation d'une notification de type `new_follower`
- Push notification si active dans les preferences

---

## Regles de Gamification

### R-GAM-01: Attribution des Points (Murgilarity)

> **Regle**: Des points sont attribues pour les actions positives.

| Action | Points |
|--------|--------|
| Creer une FUG | +10 |
| Rejoindre une FUG | +5 |
| Recevoir un follower | +2 |
| Debloquer un badge | +points du badge |

**Note**: Les points ne peuvent pas etre negatifs ni retires.

### R-GAM-02: Calcul du Niveau

> **Regle**: Le niveau est calcule a partir du score de murgilarity.

**Formule**:
```dart
int calculateLevel(int murgilarityScore) {
  return (sqrt(murgilarityScore / 10)).floor() + 1;
}
```

| Score | Niveau |
|-------|--------|
| 0-9 | 1 |
| 10-39 | 2 |
| 40-89 | 3 |
| 90-159 | 4 |
| 160+ | 5+ |

### R-GAM-03: Deblocage de Badges

> **Regle**: Les badges sont debloques automatiquement quand les criteres sont atteints.

**Exemples de badges**:

| Badge | Code | Critere | Points |
|-------|------|---------|--------|
| Preum's | `first_fug` | 1 FUG creee | 10 |
| Papillon Social | `social_butterfly` | 10 FUG rejointes | 50 |
| Influenceur | `influencer` | 100 followers | 100 |
| Murge Master | `murge_master` | 1000 points murgilarity | 200 |

### R-GAM-04: Unicite des Badges

> **Regle**: Un badge ne peut etre debloque qu'une seule fois par utilisateur.

**Verification** avant attribution:
```dart
final existing = await databases.listDocuments(
  queries: [
    Query.equal('user_id', userId),
    Query.equal('achievement_id', achievementId),
  ],
);
if (existing.documents.isNotEmpty) {
  return; // Badge deja debloque
}
```

---

## Regles de Geolocalisation

### R-GEO-01: Format de Stockage

> **Regle**: Les coordonnees sont stockees au format GeoJSON.

```json
{
  "type": "Point",
  "coordinates": [longitude, latitude]
}
```

**Important**: L'ordre est `[longitude, latitude]`, pas l'inverse!

### R-GEO-02: Rayon de Notification

> **Regle**: Chaque utilisateur definit son rayon de notification.

- Valeur par defaut: 10 km
- Minimum: 1 km
- Maximum: 100 km

**Usage**: Determiner quelles nouvelles FUG notifier a l'utilisateur.

### R-GEO-03: Mise a Jour de Position

> **Regle**: La position utilisateur n'est mise a jour que si elle a change significativement.

**Seuil**: Changement > 100 metres depuis derniere mise a jour.

**Justification**: Economie de batterie et de requetes API.

---

## Regles de Notification

### R-NOT-01: Types de Notification

| Type | Description | Push |
|------|-------------|------|
| `new_event_nearby` | Nouvelle FUG a proximite | Oui |
| `event_invitation` | Invitation a un evenement | Oui |
| `new_follower` | Nouveau follower | Oui |
| `event_reminder` | Rappel evenement | Oui |
| `achievement_unlocked` | Badge debloque | Oui |
| `event_cancelled` | Evenement annule | Oui |
| `event_updated` | Evenement modifie | Non |

### R-NOT-02: Preferences Utilisateur

> **Regle**: L'utilisateur peut desactiver chaque type de notification.

**Stockage**: Champ `notification_preferences` (JSON) dans `users`.

```json
{
  "push_enabled": true,
  "email_enabled": false,
  "types": {
    "new_event_nearby": true,
    "new_follower": true,
    "event_reminder": true
  }
}
```

### R-NOT-03: Notification par Email Optionnelle

> **Regle**: Toute notification push peut aussi etre envoyee par email.

**Condition**: `email_enabled == true` dans les preferences.

---

## Regles de Suppression de Compte

### R-DEL-01: Anonymisation des Donnees

> **Regle**: La suppression de compte anonymise les donnees plutot que de les supprimer.

**Actions**:
1. Supprimer l'avatar
2. Anonymiser l'email: `deleted_xxx@anonymized.local`
3. Anonymiser le username: `deleted_xxx`
4. Effacer les champs personnels (nom, bio, etc.)
5. Anonymiser le creator_id des evenements passes

### R-DEL-02: Conservation de l'Historique

> **Regle**: Les evenements et participations sont conserves pour l'historique global.

**Justification**: Statistiques de l'application, integrite des donnees.

---

## Matrice de Validation

### Resume des Validations par Entite

| Entite | Champ | Validation |
|--------|-------|------------|
| User | email | Format email, unique |
| User | username | 3-30 car., alphanum, unique |
| User | birth_date | Age >= minimum legal |
| Event | title | 1-100 caracteres |
| Event | location | Coordonnees GPS valides |
| Event | starts_at | Date future |
| Participation | event_id | Evenement existe, pas complet |
| Participation | user_id | Utilisateur verifie |

---

*Derniere mise a jour: Janvier 2026*
*The Develobeers - Projet FUG*
