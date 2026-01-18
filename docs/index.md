# FUG - Documentation Projet

> Vue d'ensemble du projet pour les agents BMAD-METHOD

## A Propos de FUG

**FUG** (Fous-toi Une Guinze) est une application mobile de reseau social geolocalisee permettant aux utilisateurs de trouver des compagnons de boisson et d'organiser des evenements sociaux spontanes.

### Mission

"Ne buvez plus jamais seul" - Connecter les personnes souhaitant socialiser autour d'un verre de maniere spontanee et geolocalisee.

### Equipe

**The Develobeers** - Une equipe passionnee de developpeurs:

- **Michel Lammens** - Tech Lead
- **Bruno Boi** - Flutter Lead
- **Christophe Paquet** - Backend Lead

---

## Navigation Rapide

### Pour les Agents BMAD

| Document | Description |
|----------|-------------|
| [Project Brief](./_bmad/project-brief.md) | Resume executif pour les agents |
| [Architecture](./architecture.md) | Architecture technique detaillee |
| [Business Rules](./business-rules.md) | Regles metier et concepts FUG |

### Documentation Technique

| Document | Description |
|----------|-------------|
| [Vision Produit](../1.%20Document%20de%20vision.md) | Vision originale du projet |
| [Analyse Fonctionnelle](../2.%20Analyse%20fonctionnelle.md) | Specifications detaillees |
| [Architecture Technique](../3.%20Architecture%20technique.md) | Architecture complete Flutter + Appwrite |
| [Backlog Produit](../4.%20Backlog%20produit.md) | User stories et priorites |

---

## Stack Technique

```
+-------------------+     +-------------------+
|   Flutter App     |     |    Appwrite       |
|   (Dart)          |<--->|    Backend        |
+-------------------+     +-------------------+
| - Riverpod        |     | - Auth (OAuth2)   |
| - GoRouter        |     | - Database        |
| - google_maps     |     | - Storage         |
| - geolocator      |     | - Functions       |
+-------------------+     | - Realtime        |
                          | - Messaging       |
                          +-------------------+
```

### Frontend (Flutter)

| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | >=3.2.0 | Framework mobile |
| Dart | >=3.2.0 | Langage |
| Riverpod | 2.x | State management |
| GoRouter | 13.x | Navigation |
| google_maps_flutter | 2.x | Cartes |
| geolocator | 10.x | Geolocalisation |

### Backend (Appwrite)

| Service | Usage |
|---------|-------|
| Auth | OAuth2, Email/Password |
| Database | Collections avec Spatial support |
| Storage | Avatars, images |
| Functions | Logique metier (Dart/Node.js) |
| Realtime | WebSocket subscriptions |
| Messaging | Push notifications |

---

## Architecture

Le projet suit une **Clean Architecture** organisee par features:

```
app/lib/
├── core/                    # Services partagés
│   ├── config/              # Configuration Appwrite
│   ├── constants/           # Constantes
│   ├── errors/              # Gestion erreurs
│   └── services/            # Services techniques
│
├── features/                # Features par domaine
│   ├── auth/                # Authentification
│   │   ├── data/            # Repositories
│   │   ├── domain/          # Models, interfaces
│   │   └── presentation/    # Screens, widgets
│   │
│   ├── events/              # Gestion des FUG
│   ├── profile/             # Profil utilisateur
│   ├── notifications/       # Notifications
│   └── gamification/        # Points et badges
│
└── main.dart                # Point d'entree
```

### Couches

1. **Presentation** - Screens, Widgets, Providers (Riverpod)
2. **Domain** - Models, Entities, Repository interfaces
3. **Data** - Repository implementations, Data sources

---

## Concepts Cles

### FUG (Evenement)

Un **FUG** est un evenement social geolocalisé cree par un utilisateur pour inviter d'autres personnes a boire un verre.

```dart
class EventModel {
  final String id;
  final String creatorId;
  final String title;
  final GeoPoint location;     // Position GPS
  final DateTime startsAt;
  final int currentParticipants;
  final EventStatus status;
}
```

### Murgilarity

Score de gamification attribue aux utilisateurs:

- **+10 points** - Creer une FUG
- **+5 points** - Rejoindre une FUG
- **+2 points** - Recevoir un follower

### Follow System

Les utilisateurs peuvent suivre d'autres utilisateurs pour:
- Voir leurs FUG en priorite
- Recevoir des notifications

---

## Developpement avec BMAD

### Configuration

Les fichiers BMAD sont dans `_bmad/`:

```
_bmad/
├── bmm/
│   └── config.yaml         # Configuration module
├── project-brief.md        # Brief projet
└── workflows/
    └── add-feature.md      # Workflow custom
```

### Agents Recommandes

| Agent | Usage |
|-------|-------|
| `quick-flow-solo-dev` | Features rapides, corrections |
| `architect` | Decisions d'architecture |
| `dev` | Implementation de features |
| `tech-writer` | Documentation |

### Workflow Typique

1. **Analyse** - Lire les specs, evaluer l'impact
2. **Database** - Modifier les collections Appwrite
3. **Model** - Creer le model Dart
4. **Repository** - Implementer la couche data
5. **UI** - Creer les screens avec Riverpod
6. **Tests** - Ecrire les tests (coverage >= 80%)
7. **Documentation** - Documenter le code

---

## Liens Utiles

### Externe

- [Flutter Documentation](https://docs.flutter.dev)
- [Appwrite Documentation](https://appwrite.io/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [BMAD-METHOD Documentation](https://docs.bmad-method.org)

### Interne

- [README Principal](../README.md)
- [CONTRIBUTING](../CONTRIBUTING.md)
- [Project Structure](../PROJECT_STRUCTURE.md)

---

*Derniere mise a jour: Janvier 2026*
*The Develobeers - Projet FUG*
