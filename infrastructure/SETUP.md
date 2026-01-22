# FUG - Guide d'Installation Complet (From Scratch)

Ce guide couvre l'installation complète du projet FUG depuis zéro, incluant:
- Infrastructure Docker (Appwrite)
- Création du projet et des credentials
- Migrations (collections, OAuth, push notifications)
- Configuration de l'app Flutter

---

## Table des matières

1. [Prérequis](#1-prérequis)
2. [Infrastructure Docker](#2-infrastructure-docker)
3. [Création du Projet Appwrite](#3-création-du-projet-appwrite)
4. [Configuration des Credentials](#4-configuration-des-credentials)
5. [Exécution des Migrations](#5-exécution-des-migrations)
6. [Configuration Flutter](#6-configuration-flutter)
7. [Vérification](#7-vérification)
8. [Dépannage](#8-dépannage)

---

## 1. Prérequis

### Logiciels requis

| Logiciel | Version | Installation |
|----------|---------|--------------|
| Docker | 24.0+ | `curl -fsSL https://get.docker.com \| sh` |
| Docker Compose | 2.20+ | Inclus avec Docker |
| Node.js | 20.0+ | `nvm install 20` |
| Flutter | 3.24+ | [flutter.dev](https://flutter.dev) |
| Make | 4.0+ | `apt install make` |

### Vérification

```bash
docker --version          # Docker version 24.x.x
docker compose version    # Docker Compose version v2.x.x
node --version           # v20.x.x
flutter --version        # Flutter 3.24.x
```

---

## 2. Infrastructure Docker

### 2.1 Démarrage d'Appwrite

```bash
cd infrastructure

# Créer le fichier .env depuis le template
make env

# (Optionnel) Éditer .env pour personnaliser les mots de passe
nano .env

# Démarrer les services Docker
make up

# Attendre qu'Appwrite soit prêt (~2-3 minutes)
make init
```

### 2.2 Vérification

```bash
# Vérifier que tous les services tournent
make status

# Vérifier la santé
make health
```

**URLs disponibles:**
- Console Appwrite: http://localhost:9000
- API: http://localhost:9000/v1

---

## 3. Création du Projet Appwrite

### 3.1 Créer le compte Admin

1. Ouvrir http://localhost:9000
2. Cliquer "Sign Up"
3. Créer le compte administrateur:
   - Email: `admin@fug.app` (ou votre email)
   - Password: (mot de passe sécurisé)
   - Name: `FUG Admin`

### 3.2 Créer le Projet

1. Cliquer "Create Project"
2. Nom: `FUG`
3. **IMPORTANT:** Définir l'ID manuellement: `fug`
4. Cliquer "Create"

### 3.3 Créer la Clé API pour les Migrations

1. Dans le projet FUG, aller dans **Settings** (⚙️)
2. Aller dans **API Keys**
3. Cliquer **Create API Key**
4. Nom: `FUG Migrations Key`
5. Expiration: `Never`
6. Scopes: Sélectionner **tous les scopes** suivants:
   - `databases.read`, `databases.write`
   - `collections.read`, `collections.write`
   - `attributes.read`, `attributes.write`
   - `indexes.read`, `indexes.write`
   - `documents.read`, `documents.write`
   - `users.read`, `users.write`
   - `buckets.read`, `buckets.write`
   - `files.read`, `files.write`
7. Copier le **Secret** généré

---

## 4. Configuration des Credentials

Tous les fichiers de credentials vont dans `infrastructure/setup/`.

### 4.1 Admin Credentials (OBLIGATOIRE)

Créer le fichier `.admin-credentials`:

```bash
cat > infrastructure/setup/.admin-credentials << 'EOF'
APPWRITE_ADMIN_EMAIL=admin@fug.app
APPWRITE_ADMIN_PASSWORD=votre_mot_de_passe_admin
EOF
```

### 4.2 Migrations Environment (OBLIGATOIRE)

Créer/éditer `infrastructure/migrations/.env`:

```bash
cat > infrastructure/migrations/.env << 'EOF'
# Appwrite Configuration
APPWRITE_ENDPOINT=http://localhost:9000/v1
APPWRITE_PROJECT_ID=fug
APPWRITE_API_KEY=votre_cle_api_copiee_etape_3.3
APPWRITE_DATABASE_ID=fug-db
EOF
```

### 4.3 Google OAuth (OPTIONNEL - pour Google Sign-In)

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Créer un projet ou en sélectionner un
3. APIs & Services > Credentials > Create Credentials > OAuth Client ID
4. Type: Web Application
5. Authorized redirect URIs:
   - `http://localhost:9000/v1/account/sessions/oauth2/callback/google/fug`
   - `https://votre-domaine.com/v1/account/sessions/oauth2/callback/google/fug`
6. Copier Client ID et Client Secret

Créer le fichier `.google-credentials`:

```bash
cat > infrastructure/setup/.google-credentials << 'EOF'
GOOGLE_CLIENT_ID=123456789-xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxx
EOF
```

### 4.4 Firebase FCM (OPTIONNEL - pour Push Notifications Android)

1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Créer un projet ou en sélectionner un
3. Project Settings > Service Accounts
4. Cliquer "Generate new private key"
5. Télécharger le fichier JSON

Placer le fichier dans le dossier setup:

```bash
cp ~/Downloads/votre-projet-firebase-xxxxx.json \
   infrastructure/setup/firebase-service-account.json
```

### 4.5 Apple APNs (OPTIONNEL - pour Push Notifications iOS)

1. Aller sur [Apple Developer Portal](https://developer.apple.com)
2. Certificates, Identifiers & Profiles > Keys
3. Create a Key > Enable APNs
4. Télécharger le fichier .p8
5. Noter le Key ID

```bash
# Copier le fichier .p8
cp ~/Downloads/AuthKey_XXXXXX.p8 infrastructure/setup/

# Créer le fichier credentials
cat > infrastructure/setup/.apns-credentials << 'EOF'
APNS_KEY_ID=XXXXXXXXXX
APNS_TEAM_ID=YYYYYYYYYY
APNS_BUNDLE_ID=com.fug.app
EOF
```

### 4.6 Résumé des fichiers

Après configuration, vous devriez avoir:

```
infrastructure/setup/
├── .admin-credentials           # OBLIGATOIRE
├── .google-credentials          # Optionnel (Google Sign-In)
├── .apns-credentials            # Optionnel (iOS Push)
├── firebase-service-account.json # Optionnel (Android Push)
└── AuthKey_XXXXXX.p8            # Optionnel (iOS Push)

infrastructure/migrations/
└── .env                         # OBLIGATOIRE
```

---

## 5. Exécution des Migrations

Les migrations créent automatiquement:
- Base de données et collections
- Attributs et index
- Configuration OAuth (Google, Apple)
- Providers de messaging (FCM, APNs)
- Buckets de stockage
- Badges de gamification

### 5.1 Installation des dépendances

```bash
cd infrastructure/migrations
npm install
```

### 5.2 Vérifier le statut

```bash
node migrate.js status --env=development
```

### 5.3 Exécuter les migrations

```bash
node migrate.js up --env=development
```

### 5.4 Résultat attendu

```
✔ Applied: 000_bootstrap_verify
✔ Applied: 001_initial_schema
✔ Applied: 002_users_base_attributes
...
✔ Applied: 021_google_oauth_update
✔ Applied: 022_messaging_provider

Summary:
  ✔ 23 migration(s) applied
```

### 5.5 En cas d'erreur

```bash
# Voir les détails d'une migration
node migrate.js up --env=development --verbose

# Rollback de la dernière migration
node migrate.js down --env=development

# Recommencer depuis zéro (ATTENTION: perte de données)
node migrate.js reset --env=development
```

---

## 6. Configuration Flutter

### 6.1 Dépendances

```bash
cd app
flutter pub get
```

### 6.2 Configuration Appwrite

Éditer `app/lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String appwriteEndpoint = 'http://localhost:9000/v1';
  static const String appwriteProjectId = 'fug';
  static const String appwriteDatabaseId = 'fug-db';
}
```

### 6.3 Lancer l'application

```bash
# Web (développement rapide)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 7. Vérification

### 7.1 Test de l'API

```bash
# Health check
curl http://localhost:9000/v1/health

# Version
curl http://localhost:9000/v1/health/version
```

### 7.2 Test de la Console

1. Aller sur http://localhost:9000
2. Se connecter avec le compte admin
3. Vérifier que le projet "FUG" existe
4. Vérifier les collections dans Database > fug-db:
   - users
   - events
   - followers
   - event_participants
   - achievements
   - user_achievements
   - notifications
   - content_reports
   - moderation_actions
   - account_deletion_requests
   - data_export_requests

### 7.3 Test OAuth (si configuré)

1. Aller dans Project Settings > OAuth2 Providers
2. Vérifier que Google est enabled (si configuré)

### 7.4 Test Messaging (si configuré)

1. Aller dans Messaging > Providers
2. Vérifier que FCM est enabled (si configuré)

---

## 8. Dépannage

### Migration échoue: "Connection refused"

```bash
# Vérifier qu'Appwrite tourne
make status

# Vérifier l'endpoint dans .env
cat infrastructure/migrations/.env | grep ENDPOINT
```

### Migration échoue: "Invalid API key"

```bash
# Régénérer la clé API dans Appwrite Console
# Project Settings > API Keys > Create new key
# Mettre à jour infrastructure/migrations/.env
```

### Migration échoue: "Admin session failed"

```bash
# Vérifier les credentials admin
cat infrastructure/setup/.admin-credentials

# S'assurer que l'email/password correspondent au compte créé
```

### FCM configuration failed

```bash
# Vérifier que le fichier JSON existe
ls -la infrastructure/setup/firebase-service-account.json

# Vérifier que c'est un JSON valide
cat infrastructure/setup/firebase-service-account.json | python -m json.tool
```

### Flutter: "Connection refused"

```bash
# Sur Android Emulator, utiliser 10.0.2.2 au lieu de localhost
# Éditer app_config.dart:
static const String appwriteEndpoint = 'http://10.0.2.2:9000/v1';
```

---

## Commandes Utiles

```bash
# Infrastructure
cd infrastructure
make up              # Démarrer
make down            # Arrêter
make logs            # Voir les logs
make status          # Statut des containers

# Migrations
cd infrastructure/migrations
node migrate.js status     # Voir le statut
node migrate.js up         # Appliquer les migrations
node migrate.js down       # Rollback dernière migration

# Flutter
cd app
flutter pub get            # Installer dépendances
flutter run -d chrome      # Lancer en web
flutter test               # Lancer les tests
```

---

## Checklist Installation

- [ ] Docker et Docker Compose installés
- [ ] Node.js 20+ installé
- [ ] Flutter 3.24+ installé
- [ ] `make up` exécuté avec succès
- [ ] Compte admin créé dans Appwrite Console
- [ ] Projet "fug" créé
- [ ] Clé API créée avec tous les scopes
- [ ] `infrastructure/setup/.admin-credentials` créé
- [ ] `infrastructure/migrations/.env` configuré
- [ ] `node migrate.js up` exécuté avec succès
- [ ] (Optionnel) Google OAuth configuré
- [ ] (Optionnel) Firebase FCM configuré
- [ ] Flutter app lancée et connectée

---

*Documentation FUG - Installation From Scratch*
*Dernière mise à jour: Janvier 2026*
