# FUG - Guide d'Installation Complet (From Scratch)

Ce guide couvre l'installation complète du projet FUG depuis zéro, incluant:
- Infrastructure Docker (Appwrite)
- Bootstrap automatique (projet, admin, migrations)
- Configuration OAuth et Push Notifications
- Configuration de l'app Flutter

---

## Table des matières

1. [Prérequis](#1-prérequis)
2. [Installation Rapide (Recommandé)](#2-installation-rapide-recommandé)
3. [Configuration des Services Externes](#3-configuration-des-services-externes)
4. [Configuration Flutter](#4-configuration-flutter)
5. [Vérification](#5-vérification)
6. [Installation Manuelle (Alternative)](#6-installation-manuelle-alternative)
7. [Dépannage](#7-dépannage)

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

## 2. Installation Rapide (Recommandé)

Le script `bootstrap.sh` automatise **tout** :
- Création du compte admin
- Création du projet FUG
- Création de la clé API
- Création de la base de données
- Exécution des migrations
- Génération des fichiers de configuration

### 2.1 Démarrer Appwrite

```bash
cd infrastructure

# Créer le fichier .env
make env

# Démarrer les services Docker
make up

# Attendre qu'Appwrite soit prêt (~2-3 minutes)
./scripts/wait-for-appwrite.sh
# ou simplement attendre que http://localhost:9000 réponde
```

### 2.2 Lancer le Bootstrap

```bash
cd infrastructure/setup

# Installer les dépendances des migrations
cd ../migrations && npm install && cd ../setup

# Lancer le bootstrap
./bootstrap.sh --env=development
```

### 2.3 Ce que fait le Bootstrap

```
[STEP] Checking Appwrite health...
[OK] Appwrite is running
[STEP] Generating secure admin password...
[OK] Password generated
[STEP] Setting up admin account...
[OK] Admin account created: fous.toi.une.guinze@gmail.com
[OK] Admin session created
[STEP] Creating project: FUG...
[OK] Project created: fug
[STEP] Creating API key for migrations...
[OK] API key created
[STEP] Creating database: FUG Database...
[OK] Database created: fug-db
[STEP] Generating migrations .env file...
[OK] Created .env
[STEP] Running database migrations...
[OK] Migrations completed

======================================================
  ADMIN PASSWORD (SAVE THIS NOW!)
======================================================

  xK9#mLp2$wQz...

  WARNING: This password will NOT be shown again!
======================================================
```

### 2.4 Fichiers Générés

Le bootstrap crée automatiquement :

```
infrastructure/setup/.admin-credentials    # Email + Password admin
infrastructure/migrations/.env             # Config pour les migrations
```

**IMPORTANT:** Sauvegardez le mot de passe admin affiché à l'écran !

---

## 3. Configuration des Services Externes

Ces configurations sont **optionnelles** mais recommandées pour une app complète.

1. Aller sur [Google Cloud Console](https://console.cloud.google.com)
2. Créer un projet ou en sélectionner un
3. APIs & Services > Credentials > Create Credentials > OAuth Client ID
4. Type: Web Application
5. Authorized redirect URIs:
   - `http://localhost:9000/v1/account/sessions/oauth2/callback/google/fug`
   - `https://votre-domaine.com/v1/account/sessions/oauth2/callback/google/fug`
6. Copier Client ID et Client Secret

```bash
cat > infrastructure/setup/.google-credentials << 'EOF'
GOOGLE_CLIENT_ID=123456789-xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxx
EOF
```

**Puis relancer la migration OAuth:**
```bash
cd infrastructure/migrations
node migrate.js down --env=development  # Rollback 022
node migrate.js down --env=development  # Rollback 021
node migrate.js up --env=development    # Réapplique avec Google OAuth
```

### 3.2 Firebase FCM (Push Notifications Android)

1. Aller sur [Firebase Console](https://console.firebase.google.com)
2. Créer un projet ou en sélectionner un
3. Project Settings > Service Accounts
4. Cliquer "Generate new private key"
5. Télécharger le fichier JSON

```bash
cp ~/Downloads/votre-projet-firebase-xxxxx.json \
   infrastructure/setup/firebase-service-account.json
```

**Puis relancer la migration messaging:**
```bash
cd infrastructure/migrations
node migrate.js down --env=development  # Rollback 022
node migrate.js up --env=development    # Configure FCM automatiquement
```

### 3.3 Apple APNs (Push Notifications iOS)

1. Aller sur [Apple Developer Portal](https://developer.apple.com)
2. Certificates, Identifiers & Profiles > Keys
3. Create a Key > Enable APNs
4. Télécharger le fichier .p8
5. Noter le Key ID et Team ID

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

**Puis relancer la migration messaging:**
```bash
cd infrastructure/migrations
node migrate.js down --env=development
node migrate.js up --env=development
```

### 3.4 Résumé des Fichiers de Configuration

```
infrastructure/setup/
├── .admin-credentials            # Créé par bootstrap.sh
├── .google-credentials           # Optionnel (Google Sign-In)
├── .apns-credentials             # Optionnel (iOS Push)
├── firebase-service-account.json # Optionnel (Android Push)
└── AuthKey_XXXXXX.p8             # Optionnel (iOS Push)

infrastructure/migrations/
└── .env                          # Créé par bootstrap.sh
```

---

## 4. Configuration Flutter

### 4.1 Dépendances

```bash
cd app
flutter pub get
```

### 4.2 Configuration Appwrite

Éditer `app/lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String appwriteEndpoint = 'http://localhost:9000/v1';
  static const String appwriteProjectId = 'fug';
  static const String appwriteDatabaseId = 'fug-db';
}
```

### 4.3 Lancer l'application

```bash
# Web (développement rapide)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

---

## 5. Vérification

### 5.1 Test de l'API

```bash
# Health check
curl http://localhost:9000/v1/health

# Version
curl http://localhost:9000/v1/health/version
```

### 5.2 Test de la Console

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

### 5.3 Test OAuth (si configuré)

1. Aller dans Project Settings > OAuth2 Providers
2. Vérifier que Google est enabled (si configuré)

### 5.4 Test Messaging (si configuré)

1. Aller dans Messaging > Providers
2. Vérifier que FCM est enabled (si configuré)

---

## 6. Installation Manuelle (Alternative)

Si le bootstrap échoue ou si vous préférez une installation manuelle :

### 6.1 Créer le compte Admin

1. Ouvrir http://localhost:9000
2. Cliquer "Sign Up"
3. Créer le compte administrateur

### 6.2 Créer le Projet

1. Cliquer "Create Project"
2. Nom: `FUG`
3. **IMPORTANT:** Définir l'ID: `fug`
4. Cliquer "Create"

### 6.3 Créer la Clé API

1. Project Settings (⚙️) > API Keys > Create API Key
2. Nom: `FUG Migrations Key`
3. Scopes: tous les `databases.*`, `collections.*`, `attributes.*`, `indexes.*`, `documents.*`, `users.*`, `buckets.*`, `files.*`

### 6.4 Configurer les fichiers

```bash
# Admin credentials
cat > infrastructure/setup/.admin-credentials << 'EOF'
APPWRITE_ADMIN_EMAIL=votre@email.com
APPWRITE_ADMIN_PASSWORD=votre_mot_de_passe
EOF

# Migrations .env
cat > infrastructure/migrations/.env << 'EOF'
APPWRITE_ENDPOINT=http://localhost:9000/v1
APPWRITE_PROJECT_ID=fug
APPWRITE_API_KEY=votre_cle_api
DATABASE_ID=fug-db
EOF
```

### 6.5 Lancer les migrations

```bash
cd infrastructure/migrations
npm install
node migrate.js up --env=development
```

---

## 7. Dépannage

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

### Installation Rapide (bootstrap.sh)
- [ ] Docker et Docker Compose installés
- [ ] Node.js 20+ installé
- [ ] Flutter 3.24+ installé
- [ ] `make up` exécuté avec succès
- [ ] `./bootstrap.sh` exécuté avec succès
- [ ] Mot de passe admin sauvegardé
- [ ] Flutter app lancée et connectée

### Services Optionnels
- [ ] (Optionnel) `.google-credentials` créé + migration relancée
- [ ] (Optionnel) `firebase-service-account.json` placé + migration relancée
- [ ] (Optionnel) `.apns-credentials` + `.p8` placés + migration relancée

---

*Documentation FUG - Installation From Scratch*
*Dernière mise à jour: Janvier 2026*
