# FUG - Structure du Projet

**Find Urban Gatherings** - Application de decouverte d'evenements locaux

Ce document presente la structure complete du projet FUG et le role de chaque fichier.

---

## Vue d'ensemble

```
FUG/
├── app/                      # Application Flutter mobile
├── functions/                # Fonctions Appwrite (serverless)
├── .github/                  # Configuration GitHub (CI/CD)
├── .bmad/                    # Configuration BMAD method
└── docs/                     # Documentation supplementaire

# Backend (repository separe)
fug-backend/                  # Infrastructure Appwrite partagee
├── docker-compose.yml        # Stack Appwrite
├── migrations/               # Migrations base de donnees
└── setup/                    # Scripts de bootstrap
```

---

## Fichiers Racine

| Fichier | Role |
|---------|------|
| `README.md` | Documentation principale du projet |
| `CONTRIBUTING.md` | Guide de contribution pour les developpeurs |
| `LICENSE` | Licence MIT du projet |
| `.gitignore` | Fichiers ignores par Git |
| `setup.sh` | Script de setup automatique (dev/test/prod) |
| `1. Document de vision.md` | Vision produit et objectifs |
| `2. Analyse fonctionnelle.md` | Specifications fonctionnelles detaillees |
| `3. Architecture technique.md` | Architecture technique et decisions |
| `4. Backlog produit.md` | User stories et priorites |
| `Modification.md` | Journal des modifications |
| `PROJECT_STRUCTURE.md` | Ce fichier - inventaire du projet |

---

## Application Flutter (`app/`)

Application mobile cross-platform (iOS/Android) construite avec Flutter.

### Structure

```
app/
├── lib/
│   ├── main.dart                              # Point d'entree de l'application
│   ├── core/
│   │   ├── config/
│   │   │   └── appwrite_config.dart           # Configuration Appwrite (endpoints, IDs)
│   │   └── services/
│   │       └── appwrite_service.dart          # Service singleton Appwrite
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   └── auth_repository.dart       # Repository d'authentification
│       │   ├── domain/
│       │   │   └── user_model.dart            # Modele utilisateur
│       │   └── presentation/
│       │       └── login_screen.dart          # Ecran de connexion
│       ├── events/
│       │   ├── data/
│       │   │   └── event_repository.dart      # Repository des evenements
│       │   └── domain/
│       │       └── event_model.dart           # Modele evenement
│       └── profile/
│           ├── data/
│           │   └── profile_repository.dart    # Repository profil
│           ├── domain/
│           │   └── profile_model.dart         # Modele profil
│           └── presentation/
│               ├── profile_screen.dart        # Ecran profil
│               └── edit_profile_screen.dart   # Edition du profil
├── assets/
│   ├── images/                                # Images de l'application
│   ├── icons/                                 # Icones personnalisees
│   └── fonts/                                 # Polices (Poppins)
├── pubspec.yaml                               # Dependances Flutter
└── README.md                                  # Documentation app
```

### Fichiers cles

| Fichier | Role |
|---------|------|
| `lib/main.dart` | Initialisation Flutter, themes, AuthWrapper |
| `lib/core/config/appwrite_config.dart` | Constantes de configuration Appwrite |
| `lib/core/services/appwrite_service.dart` | Singleton pour acces aux services Appwrite |
| `pubspec.yaml` | Dependances: appwrite, riverpod, go_router, geolocator |

---

## Fonctions Appwrite (`functions/`)

Fonctions serverless executees cote serveur pour la logique metier.

### Structure

```
functions/
├── follow-user/
│   ├── src/
│   │   └── main.js          # Logique de suivi d'utilisateurs
│   ├── test/
│   │   └── main.test.js     # Tests unitaires
│   ├── package.json         # Dependances (node-appwrite ^13.0.0)
│   └── jest.config.js       # Configuration Jest
├── join-event/
│   ├── src/
│   │   └── main.js          # Inscription aux evenements
│   └── package.json
├── create-event/
│   ├── src/
│   │   └── main.js          # Creation d'evenements avec notifications
│   └── package.json
├── gamification/
│   ├── src/
│   │   └── main.js          # Systeme de badges et leaderboard
│   └── package.json
├── test-utils/
│   ├── index.js             # Utilitaires de test partages
│   └── package.json
└── README.md                # Documentation des fonctions
```

### Details des fonctions

| Fonction | Role | Points de gamification |
|----------|------|------------------------|
| `follow-user` | Cree relation follower/following, notifie, attribue points | 5 (suivre), 10 (etre suivi) |
| `join-event` | Inscrit a un evenement, verifie limites, notifie | 15 (rejoindre), bonus milestones |
| `create-event` | Cree evenement, notifie followers, attribue points | 25 (creer), 50 (premier), milestones |
| `gamification` | Verifie achievements, calcule leaderboard, attribue badges | Variable selon badges |

---

## Backend (fug-backend)

L'infrastructure Appwrite est geree dans le repository separe **fug-backend**.

```bash
# Demarrer le backend
cd /home/knabo/dev/fug-backend
make dev

# Premier demarrage
./setup/bootstrap.sh --env development
```

Voir: https://github.com/knabo6/fug-backend

---

## GitHub Actions (`.github/`)

Configuration CI/CD pour integration et deploiement continus.

### Workflows

| Fichier | Role |
|---------|------|
| `workflows/flutter-ci.yml` | Tests et build Flutter |
| `workflows/functions-ci.yml` | Tests des fonctions Appwrite |
| `workflows/deploy-staging.yml` | Deploiement en staging |
| `workflows/deploy-production.yml` | Deploiement en production |
| `dependabot.yml` | Mises a jour automatiques des dependances |

---

## Configuration BMAD (`.bmad/`)

Methode BMAD pour la gestion de projet agile avec IA.

| Fichier | Role |
|---------|------|
| `config.yaml` | Configuration BMAD |
| `project-context.md` | Contexte du projet pour l'IA |
| `workflows/add-feature.md` | Workflow d'ajout de fonctionnalite |

---

## Dependances Principales

### Backend (Node.js)

| Package | Version | Usage |
|---------|---------|-------|
| `node-appwrite` | ^13.0.0 | SDK Appwrite serveur |
| `dotenv` | ^16.3.1 | Variables d'environnement |
| `commander` | ^11.1.0 | CLI migrations |

### Frontend (Flutter)

| Package | Version | Usage |
|---------|---------|-------|
| `appwrite` | ^12.0.0 | SDK Appwrite client |
| `flutter_riverpod` | ^2.4.9 | State management |
| `go_router` | ^13.0.0 | Navigation |
| `geolocator` | ^10.1.0 | Geolocalisation |
| `google_maps_flutter` | ^2.5.0 | Cartes |

---

## Collections Appwrite

| Collection | Role |
|------------|------|
| `users` | Profils utilisateurs etendus |
| `events` | Evenements |
| `event_participants` | Participations aux evenements |
| `followers` | Relations de suivi |
| `notifications` | Notifications utilisateurs |
| `gamification` | Points et badges |
| `leaderboard` | Classements |
| `achievements` | Definitions des badges |

---

## Buckets Storage

| Bucket | Role |
|--------|------|
| `avatars` | Photos de profil |
| `event_images` | Images des evenements |

---

## Commandes Utiles

### Setup complet

```bash
./setup.sh dev      # Environnement de developpement
./setup.sh test     # Environnement de test
./setup.sh prod     # Environnement de production
```

### Infrastructure

```bash
cd infrastructure

# Docker
make up             # Demarrer les services
make down           # Arreter les services
make logs           # Voir les logs
make restart        # Redemarrer

# Migrations
cd migrations
npm run migrate:up     # Executer les migrations
npm run migrate:down   # Rollback derniere migration
npm run migrate:status # Voir le statut
npm run migrate:fresh  # Reset complet
```

### Application Flutter

```bash
cd app

flutter pub get                    # Installer dependances
flutter pub run build_runner build # Generer le code
flutter run                        # Lancer l'app
flutter test                       # Executer les tests
flutter build apk                  # Build Android
flutter build ios                  # Build iOS
```

### Fonctions Appwrite

```bash
cd functions/<nom-fonction>

npm install          # Installer dependances
npm test             # Executer les tests
npm start            # Tester localement
```

---

## Contacts

- **Equipe**: The Develobeers
- **Email**: contact@thedevelobeers.com
- **Repository**: https://github.com/TheDevelobeers/FUG

---

*Document genere le 18 janvier 2025*
