# Project Brief: FUG

> Document de reference pour les agents BMAD-METHOD

## Resume Executif

**FUG** (Fous-toi Une Guinze) est une application mobile de reseau social permettant aux utilisateurs de trouver des compagnons de boisson et d'organiser des evenements sociaux geolocalises.

| Attribut | Valeur |
|----------|--------|
| **Nom** | FUG |
| **Nom complet** | Fous-toi Une Guinze |
| **Type** | Application mobile reseau social |
| **Statut** | Brownfield (projet existant avec code) |
| **Equipe** | The Develobeers |
| **Cible** | Adultes majeurs souhaitant socialiser |

---

## Vision Produit

### Probleme

Les personnes souhaitant sortir boire un verre n'ont pas toujours de compagnons disponibles. Boire seul peut etre deprimant et les applications sociales existantes ne repondent pas a ce besoin specifique.

### Solution

FUG permet aux utilisateurs de:

1. **Creer des evenements ("FUG")** - Declarer une intention de sortir a un endroit precis
2. **Decouvrir les evenements** - Voir sur une carte les FUG a proximite
3. **Rejoindre des evenements** - Participer aux FUG d'autres utilisateurs
4. **Socialiser** - Rencontrer de nouvelles personnes partageant les memes interets
5. **Gamifier l'experience** - Gagner des points ("murgilarity") et des badges

### Proposition de valeur unique

"Ne buvez plus jamais seul" - FUG est le premier reseau social concu specifiquement pour trouver des compagnons de boisson de maniere spontanee et geolocalisee.

---

## Equipe

**The Develobeers**
- Michel Lammens
- Christophe Paquet

*Projet original (2014): Bruno Boi, Christophe Paquet, Michel Lammens*

---

## Stack Technique

### Frontend

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.x |
| Langage | Dart |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Maps | google_maps_flutter |
| Geolocalisation | geolocator |

### Backend (Appwrite)

| Service | Usage |
|---------|-------|
| Auth | OAuth2 (Google, Facebook, Apple), Email/Password |
| Database | Collections avec support Spatial |
| Storage | Avatars, images d'evenements |
| Functions | Logique metier serverless (Dart/Node.js) |
| Realtime | WebSocket pour mises a jour temps reel |
| Messaging | Push notifications (APNs/FCM) |

### Architecture

- **Pattern**: Clean Architecture + MVVM
- **Couches**: Presentation > Domain > Data
- **Structure**: Feature-first organization

---

## Concepts Metier Cles

### Lexique FUG

| Terme | Definition |
|-------|------------|
| **FUG** | Evenement social pour boire ensemble (synonyme: guinze, murge) |
| **Preum's** | Utilisateur createur d'une FUG |
| **Participant** | Utilisateur ayant rejoint une FUG |
| **Murgilarity** | Score de gamification (mot-valise: murge + hilarité/popularité) |
| **Follower** | Utilisateur suivant un autre pour voir ses FUG |

### Regles Metier Principales

1. **Age minimum**: Verification obligatoire (18+ selon pays)
2. **Geolocalisation**: Les FUG sont toujours liees a un lieu
3. **Visibility**: Les evenements sont publics par defaut
4. **Gamification**: Points attribues pour participation et creation
5. **Temps reel**: Notifications instantanees pour nouvelles FUG a proximite

---

## Fonctionnalites MVP (V1)

### Terminees

- [x] Authentification (Email + OAuth Google/Facebook/Apple)
- [x] Profil utilisateur avec avatar
- [x] Configuration du rayon de notification

### En cours

- [ ] Creation d'evenements (FUG)
- [ ] Carte des evenements a proximite
- [ ] Rejoindre un evenement
- [ ] Systeme de follow
- [ ] Notifications push
- [ ] Gamification basique (murgilarity)

### Futures (V2+)

- [ ] Chat entre participants
- [ ] Galerie photos par evenement
- [ ] Cercles d'amis
- [ ] Statistiques personnelles

---

## Structure du Projet

```
FUG/
├── app/                        # Application Flutter
│   ├── lib/
│   │   ├── core/               # Configuration, services
│   │   ├── features/           # Features par domaine
│   │   │   ├── auth/           # Authentification
│   │   │   ├── events/         # Gestion des FUG
│   │   │   ├── profile/        # Profil utilisateur
│   │   │   └── notifications/  # Notifications
│   │   └── main.dart
│   └── test/
│
├── functions/                  # Appwrite Functions
│   ├── follow-user/
│   ├── join-event/
│   ├── create-event/
│   └── gamification/
│
├── infrastructure/             # Configuration Appwrite
│
├── _bmad/                      # Configuration BMAD-METHOD
│   ├── bmm/config.yaml         # Configuration module
│   └── project-brief.md        # Ce document
│
├── _bmad-output/               # Artefacts generes par BMAD
│   ├── planning-artifacts/
│   └── implementation-artifacts/
│
├── docs/                       # Documentation projet
│   ├── index.md                # Vue d'ensemble
│   ├── architecture.md         # Architecture technique
│   └── business-rules.md       # Regles metier
│
└── .bmad-method/               # BMAD-METHOD framework (clone)
```

---

## Collections Appwrite

| Collection | Description | Spatial |
|------------|-------------|---------|
| `users` | Profils utilisateurs | Oui |
| `events` | Evenements/FUG | Oui |
| `followers` | Relations de follow | Non |
| `event_participants` | Participations | Non |
| `achievements` | Badges disponibles | Non |
| `user_achievements` | Badges debloques | Non |
| `notifications` | Notifications in-app | Non |

---

## Appwrite Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `follow-user` | HTTP | Gestion follow/unfollow |
| `join-event` | HTTP | Inscription aux FUG |
| `nearby-events` | HTTP | Recherche geospatiale |
| `gamification` | Event | Points et badges |
| `send-notification` | Event | Push notifications |
| `cleanup-events` | Schedule | Archive FUG expirees |

---

## Environnements

| Env | Appwrite Project | Usage |
|-----|------------------|-------|
| `development` | fug-dev | Dev local (Docker) |
| `staging` | fug-staging | Pre-production |
| `production` | fug-production | Production |

---

## Points d'Attention pour les Agents

### Performance

- Paginer les resultats avec `Query.limit()`
- Utiliser les compteurs denormalises (current_participants)
- Cacher les donnees frequemment accedees

### Securite

- Verifier l'age (birth_date) pour conformite legale
- Ne jamais exposer les API keys cote client
- Permissions Appwrite strictes

### Geolocalisation

- Format GeoJSON: `[longitude, latitude]` (ordre important!)
- Utiliser `Query.distanceLessThan()` pour recherches spatiales
- Throttling des mises a jour de position

### Code Style

- Suivre les conventions Flutter/Dart
- Documentation obligatoire pour les APIs publiques
- Tests unitaires avec coverage >= 80%

---

## Documents de Reference

| Document | Chemin | Description |
|----------|--------|-------------|
| Vision | `1. Document de vision.md` | Vision produit originale |
| Analyse | `2. Analyse fonctionnelle.md` | Specifications detaillees |
| Architecture | `3. Architecture technique.md` | Architecture complete |
| Backlog | `4. Backlog produit.md` | User stories |

---

*Derniere mise a jour: Janvier 2026*
*The Develobeers - Projet FUG*
