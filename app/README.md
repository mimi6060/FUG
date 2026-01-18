# FUG - Find Urban Gatherings

Application mobile Flutter pour la decouverte et la participation a des evenements locaux.

## Structure du projet

```
app/
├── lib/
│   ├── main.dart                 # Point d'entree de l'application
│   ├── core/
│   │   ├── config/
│   │   │   └── appwrite_config.dart    # Configuration Appwrite
│   │   └── services/
│   │       └── appwrite_service.dart   # Service singleton Appwrite
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   └── auth_repository.dart
│       │   ├── domain/
│       │   │   └── user_model.dart
│       │   └── presentation/
│       │       └── login_screen.dart
│       ├── events/
│       │   ├── data/
│       │   │   └── event_repository.dart
│       │   ├── domain/
│       │   │   └── event_model.dart
│       │   └── presentation/
│       ├── profile/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       └── notifications/
│           ├── data/
│           ├── domain/
│           └── presentation/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── pubspec.yaml
└── README.md
```

## Installation

### Prerequis

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Un projet Appwrite configure

### Etapes

1. **Cloner le repository**
   ```bash
   cd /path/to/FUG/app
   ```

2. **Installer les dependances**
   ```bash
   flutter pub get
   ```

3. **Configurer Appwrite**

   Modifier le fichier `lib/core/config/appwrite_config.dart`:
   ```dart
   static const String endpoint = 'https://votre-instance.appwrite.io/v1';
   static const String projectId = 'VOTRE_PROJECT_ID';
   ```

4. **Creer les dossiers d'assets**
   ```bash
   mkdir -p assets/images assets/icons assets/fonts
   ```

5. **Lancer l'application**
   ```bash
   flutter run
   ```

## Configuration Appwrite

### Collections requises

Creer les collections suivantes dans votre projet Appwrite:

#### Collection `users`
| Attribut | Type | Required |
|----------|------|----------|
| userId | string | oui |
| email | string | oui |
| name | string | oui |
| avatarUrl | string | non |
| bio | string | non |
| location | string | non |
| latitude | double | non |
| longitude | double | non |
| interests | string[] | non |
| eventsCreated | integer | non |
| eventsAttended | integer | non |
| rating | double | non |
| isVerified | boolean | non |
| createdAt | datetime | oui |
| updatedAt | datetime | oui |

#### Collection `events`
| Attribut | Type | Required |
|----------|------|----------|
| title | string | oui |
| description | string | oui |
| organizerId | string | oui |
| organizerName | string | oui |
| categoryId | string | oui |
| categoryName | string | non |
| imageUrl | string | non |
| additionalImages | string[] | non |
| address | string | oui |
| latitude | double | oui |
| longitude | double | oui |
| venueName | string | non |
| startDate | datetime | oui |
| endDate | datetime | oui |
| maxParticipants | integer | non |
| currentParticipants | integer | non |
| price | integer | non |
| currency | string | non |
| tags | string[] | non |
| status | string | oui |
| isFeatured | boolean | non |
| rating | double | non |
| reviewCount | integer | non |
| createdAt | datetime | oui |
| updatedAt | datetime | oui |

### Index recommandes

Pour la collection `events`:
- Index sur `status` (key)
- Index sur `categoryId` (key)
- Index sur `organizerId` (key)
- Index sur `latitude` (key)
- Index sur `longitude` (key)
- Index sur `startDate` (key)
- Index fulltext sur `title` (pour la recherche)

### Buckets Storage

- `avatars` - Pour les photos de profil
- `event_images` - Pour les images d'evenements

## Architecture

L'application suit une architecture Clean Architecture simplifiee:

- **data/** - Repositories et sources de donnees
- **domain/** - Modeles et entites metier
- **presentation/** - UI (screens, widgets)

### State Management

L'application utilise **Riverpod** pour la gestion d'etat:
- Providers pour les services
- StateProviders pour l'etat simple
- StateNotifierProviders pour l'etat complexe

### Navigation

La navigation utilise **go_router** pour:
- Navigation declarative
- Deep linking
- Guards d'authentification

## Dependances principales

| Package | Version | Usage |
|---------|---------|-------|
| appwrite | ^12.0.0 | Backend as a Service |
| flutter_riverpod | ^2.4.9 | State management |
| go_router | ^13.0.0 | Navigation |
| geolocator | ^10.1.0 | Geolocalisation |
| google_maps_flutter | ^2.5.0 | Cartes |
| shared_preferences | ^2.2.2 | Stockage local |
| flutter_local_notifications | ^16.3.0 | Notifications |

## Scripts utiles

```bash
# Generer le code (models, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Analyser le code
flutter analyze

# Executer les tests
flutter test

# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release
```

## TODO

- [ ] Implementer go_router avec les routes
- [ ] Ajouter l'ecran d'accueil avec la carte
- [ ] Implementer la creation d'evenements
- [ ] Ajouter les notifications push
- [ ] Implementer le profil utilisateur
- [ ] Ajouter les tests unitaires
- [ ] Configurer CI/CD

## Contribution

1. Fork le projet
2. Creer une branche feature (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajouter nouvelle fonctionnalite'`)
4. Push la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## License

Ce projet est sous licence MIT.
