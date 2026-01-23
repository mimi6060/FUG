# FUG - Fous-toi Une Guinze

> Partagez des moments conviviaux - Reseau social geolocalize pour trouver des compagnons de sortie

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev)
[![Appwrite](https://img.shields.io/badge/Appwrite-1.4+-F02E65?logo=appwrite)](https://appwrite.io)
[![License](https://img.shields.io/badge/License-Proprietary-red)]()
[![BMAD](https://img.shields.io/badge/BMAD-Method-blue)](https://docs.bmad-method.org)
[![Responsible](https://img.shields.io/badge/Consommation-Responsable-green)]()

---

## Description

**FUG** est une application mobile qui connecte les gens autour de moments conviviaux:

- Creez des evenements sociaux ("FUG") geolocalises
- Decouvrez les sorties a proximite sur une carte interactive
- Rejoignez des evenements et rencontrez de nouvelles personnes
- Suivez vos amis et soyez notifie de leurs activites
- Gagnez des points de "Murgilarity" et debloquez des badges

> FUG encourage une consommation responsable. L'abus d'alcool est dangereux pour la sante.

**Equipe**: The Develobeers - Michel Lammens, Christophe Paquet

---

## Stack Technique

| Couche | Technologie |
|--------|-------------|
| **Frontend** | Flutter 3.x (Dart) |
| **State Management** | Riverpod 2.x |
| **Navigation** | GoRouter |
| **Backend** | Appwrite (Auth, Database, Functions, Storage) |
| **Maps** | Google Maps Flutter |
| **Architecture** | Clean Architecture |

---

## Quick Start

```bash
# 1. Cloner le repository
git clone https://github.com/develobeers/fug.git
cd fug

# 2. Installer les dependances Flutter
cd app && flutter pub get

# 3. Lancer l'application en mode developpement
flutter run
```

### Pre-requis

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Docker (pour Appwrite local)
- Compte Appwrite Cloud (ou instance self-hosted)

### Versions OS Minimales (MOD-004)

| Plateforme | Version Minimum | API Level | Notes |
|------------|-----------------|-----------|-------|
| **Android** | 10.0 (Q) | API 29 | Scoped storage, privacy enhancements |
| **iOS** | 14.0 | N/A | App Tracking Transparency, widgets |
| **Web** | Navigateurs modernes | N/A | Chrome, Firefox, Safari, Edge |

> **Justification (2026):** Ces versions garantissent la securite et l'acces aux fonctionnalites modernes. Market share: Android 10+ = 85%+, iOS 14+ = 95%+.

#### Configuration des plateformes natives

Lors de la premiere generation des plateformes (`flutter create --platforms=android,ios`):

**Android** (`android/app/build.gradle`):
```groovy
defaultConfig {
    minSdk = 29      // Android 10
    targetSdk = 34   // Android 14
}
```

**iOS** (`ios/Podfile`):
```ruby
platform :ios, '14.0'
```

---

## Structure du Repository

```
FUG/
├── app/                        # Application Flutter
│   ├── lib/
│   │   ├── core/               # Configuration, services, utils
│   │   │   ├── config/         # Configuration Appwrite
│   │   │   └── services/       # Services techniques
│   │   ├── features/           # Features par domaine
│   │   │   ├── auth/           # Authentification
│   │   │   ├── events/         # Gestion des evenements
│   │   │   ├── profile/        # Profil utilisateur
│   │   │   └── notifications/  # Notifications
│   │   └── main.dart           # Point d'entree
│   ├── test/                   # Tests unitaires et widget
│   ├── assets/                 # Images, fonts, icons
│   └── pubspec.yaml            # Dependances Flutter
│
├── functions/                  # Appwrite Functions
│   ├── follow-user/            # Gestion des follows
│   ├── join-event/             # Inscription aux evenements
│   ├── create-event/           # Creation d'evenements
│   └── gamification/           # Systeme de points/badges
│
├── _bmad/                      # Configuration BMAD-METHOD (v6)
│   ├── bmm/config.yaml         # Configuration module BMM
│   ├── project-brief.md        # Brief projet pour les agents
│   └── workflows/              # Workflows personnalises
│
├── _bmad-output/               # Artefacts generes par BMAD
│   ├── planning-artifacts/     # Documents de planification
│   └── implementation-artifacts/  # Sprint status, stories
│
├── .bmad-method/               # BMAD-METHOD framework (clone)
│
├── docs/                       # Documentation pour agents BMAD
│   ├── index.md                # Vue d'ensemble du projet
│   ├── architecture.md         # Architecture technique
│   └── business-rules.md       # Regles metier FUG
│
├── 1. Document de vision.md    # Vision produit originale
├── 2. Analyse fonctionnelle.md # Specifications detaillees
├── 3. Architecture technique.md # Architecture complete
└── 4. Backlog produit.md       # User stories
```

---

## Environnements

| Environnement | Appwrite Project | Description |
|---------------|------------------|-------------|
| **Development** | `fug-dev` | Local Docker, donnees de test |
| **Staging** | `fug-staging` | Appwrite Cloud, pre-production |
| **Production** | `fug-production` | Appwrite Cloud, production |

### Configuration des environnements

```bash
# Developpement (defaut)
flutter run

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor production -t lib/main_prod.dart
```

---

## Commandes Disponibles

### Flutter (depuis /app)

```bash
# Installation des dependances
flutter pub get

# Lancer l'application
flutter run

# Build Android
flutter build apk --release

# Build iOS
flutter build ios --release

# Lancer les tests
flutter test

# Tests avec coverage
flutter test --coverage

# Analyser le code
flutter analyze

# Generer le code (Riverpod, JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Appwrite CLI

```bash
# Login
appwrite login

# Deployer les functions
appwrite deploy function --all

# Deployer les collections
appwrite deploy collection

# Voir les logs d'une function
appwrite functions listExecutions --functionId=<ID>
```

### Docker (Appwrite local)

```bash
# Demarrer Appwrite
docker compose up -d

# Arreter Appwrite
docker compose down

# Voir les logs
docker compose logs -f
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Document de Vision](./1.%20Document%20de%20vision.md) | Vision produit, exigences fonctionnelles |
| [Analyse Fonctionnelle](./2.%20Analyse%20fonctionnelle.md) | Specifications detaillees |
| [Architecture Technique](./3.%20Architecture%20technique.md) | Architecture, schema DB, Functions |
| [Backlog Produit](./4.%20Backlog%20produit.md) | User stories, priorites |
| [App README](./app/README.md) | Documentation Flutter specifique |
| [Functions README](./functions/README.md) | Documentation Appwrite Functions |

---

## Developpement avec BMAD-METHOD

Ce projet utilise [BMAD-METHOD](https://docs.bmad-method.org) v6 pour structurer le developpement agile assiste par IA.

### Structure BMAD

```
FUG/
├── _bmad/                      # Configuration BMAD (nouveau format v6)
│   ├── bmm/
│   │   └── config.yaml         # Configuration du module BMad Method
│   ├── project-brief.md        # Brief projet pour les agents
│   └── workflows/
│       └── add-feature.md      # Workflow personnalise
│
├── _bmad-output/               # Artefacts generes par BMAD
│   ├── planning-artifacts/     # Documents de planification
│   └── implementation-artifacts/  # Artefacts d'implementation
│
├── .bmad-method/               # Framework BMAD-METHOD (clone)
│
└── docs/                       # Documentation projet (project_knowledge)
    ├── index.md                # Vue d'ensemble
    ├── architecture.md         # Architecture technique
    └── business-rules.md       # Regles metier FUG
```

### Configuration BMAD

La configuration est dans `_bmad/bmm/config.yaml`:

```yaml
core:
  user_name: "The Develobeers"
  communication_language: "French"
  output_folder: "_bmad-output"

project:
  name: "FUG"
  status: "brownfield"
  team: "The Develobeers"

tech_stack:
  frontend:
    framework: "Flutter"
    state_management: "Riverpod"
  backend:
    platform: "Appwrite"
```

### Agents Recommandes

| Agent | Usage |
|-------|-------|
| `quick-flow-solo-dev` | Features rapides (< 4h), corrections de bugs |
| `architect` | Decisions d'architecture, nouvelles collections |
| `dev` | Implementation de features |
| `tech-writer` | Documentation |

### Documentation pour les Agents

Les agents BMAD peuvent consulter:

| Document | Chemin | Description |
|----------|--------|-------------|
| Project Brief | `_bmad/project-brief.md` | Resume executif du projet |
| Vue d'ensemble | `docs/index.md` | Navigation et stack technique |
| Architecture | `docs/architecture.md` | Clean Architecture + Appwrite |
| Regles metier | `docs/business-rules.md` | Concepts FUG, murgilarity |

### Workflow pour Ajouter une Feature

```
1. ANALYSE     2. DATABASE    3. MODEL       4. REPOSITORY
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Specs & │───►│Migration│───►│  Dart   │───►│  Data   │
│ Impact  │    │ Appwrite│    │  Model  │    │  Layer  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
                                                   │
                                                   ▼
5. DOCS        6. TESTS       7. UI
┌─────────┐    ┌─────────┐    ┌─────────┐
│Document │◄───│  Write  │◄───│ Screen  │
│  Code   │    │  Tests  │    │ Widget  │
└─────────┘    └─────────┘    └─────────┘
```

Voir `_bmad/workflows/add-feature.md` pour le workflow detaille.

### Commandes BMAD

```bash
# Installer BMAD-METHOD
npx bmad-method@alpha install

# Lancer un workflow
*workflow-init

# Utiliser un agent
@quick-flow-solo-dev "Corriger le bug X"
```

---

## Collections Appwrite

| Collection | Description |
|------------|-------------|
| `users` | Profils utilisateurs avec geolocalisation |
| `events` | Evenements/FUG avec localisation |
| `followers` | Relations de follow |
| `event_participants` | Participations aux evenements |
| `achievements` | Badges disponibles |
| `user_achievements` | Badges debloques par utilisateur |
| `notifications` | Notifications in-app |

---

## Appwrite Functions

| Function | Trigger | Description |
|----------|---------|-------------|
| `follow-user` | HTTP | Gestion des follows/unfollows |
| `join-event` | HTTP | Inscription/desinscription |
| `nearby-events` | HTTP | Recherche geospatiale |
| `gamification` | Event | Attribution des points et badges |
| `send-notification` | Event | Envoi des push notifications |
| `cleanup-events` | Schedule | Archive des evenements expires |

---

## Tests

```bash
# Tous les tests
cd app && flutter test

# Avec coverage
flutter test --coverage

# Generer le rapport HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Objectif de coverage**: >= 80%

---

## CI/CD

Le pipeline CI/CD utilise GitHub Actions:

- **Tests**: Executes sur chaque PR
- **Lint**: Analyse statique du code
- **Build**: Android et iOS sur merge vers main
- **Deploy Functions**: Deploiement automatique vers staging

Voir `.github/workflows/` pour la configuration.

---

## Securite

- Les API keys ne sont jamais commitees (utiliser des variables d'environnement)
- Les donnees utilisateur sont chiffrees au repos
- Conformite RGPD implementee (export/suppression des donnees)
- Verification de l'age obligatoire (18+)

---

## Roadmap

### V1.0 - MVP
- [x] Authentification
- [x] Profil utilisateur
- [ ] Creation d'evenements
- [ ] Carte des evenements
- [ ] Systeme de follow
- [ ] Notifications push
- [ ] Gamification basique

### V2.0 - Social
- [ ] Chat entre participants
- [ ] Galerie photos
- [ ] Cercles d'amis
- [ ] Statistiques

---

## Licence

Proprietary - The Develobeers (c) 2014-2026

---

## Contact

**The Develobeers**
- Michel Lammens
- Christophe Paquet

*Projet original (2014): Bruno Boi, Christophe Paquet, Michel Lammens*

---

*Built with Flutter, Appwrite, and BMAD-METHOD*
