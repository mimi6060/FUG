# Environnements - Infrastructure FUG

Documentation complete sur la configuration des environnements dev, test et production.

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Environnement de developpement](#environnement-de-developpement)
- [Environnement de test](#environnement-de-test)
- [Environnement de production](#environnement-de-production)
- [Variables par environnement](#variables-par-environnement)
- [Processus de promotion](#processus-de-promotion)
- [Checklist de deploiement](#checklist-de-deploiement)

---

## Vue d'ensemble

### Comparaison des environnements

| Aspect | Developpement | Test | Production |
|--------|---------------|------|------------|
| **Objectif** | Developpement local | Tests automatises | Utilisateurs finaux |
| **Donnees** | Fictives/seed | Automatisees | Reelles |
| **HTTPS** | Non | Optionnel | Obligatoire |
| **Debug** | Active | Active | Desactive |
| **Outils** | Complets | Minimaux | Aucun |
| **Backup** | Non | Non | Quotidien |
| **Monitoring** | Optionnel | Optionnel | Obligatoire |

### Fichiers de configuration

```
infrastructure/
  |-- .env.example              # Template de configuration
  |-- .env                      # Configuration locale (non commite)
  |-- docker-compose.yml        # Configuration de base
  |-- docker-compose.override.yml  # Surcharges developpement (auto-charge)
  |
  +-- migrations/
      +-- environments/
          |-- .env.development  # Config migrations dev
          |-- .env.test         # Config migrations test
          |-- .env.production   # Config migrations prod
```

---

## Environnement de developpement

### Caracteristiques

- Mode debug active
- Ports internes exposes
- Outils supplementaires (Adminer, Redis Commander, Mailhog)
- Hot-reload des fonctions
- Protection anti-abus desactivee
- HTTPS non obligatoire

### Demarrage

```bash
# Demarrage standard (charge automatiquement docker-compose.override.yml)
make up

# Equivalent a:
docker compose up -d
```

### Configuration .env pour le developpement

```ini
# =============================================================================
# ENVIRONNEMENT DEVELOPPEMENT
# =============================================================================

# Core
_APP_ENV=development
_APP_LOCALE=fr
_APP_OPTIONS_ABUSE=disabled
_APP_OPTIONS_FORCE_HTTPS=disabled

# Domaine local
_APP_DOMAIN=localhost
_APP_DOMAIN_TARGET=localhost
_APP_DOMAIN_FUNCTIONS=functions.localhost

# Console - acces ouvert en dev
_APP_CONSOLE_WHITELIST_ROOT=enabled
_APP_CONSOLE_WHITELIST_EMAILS=
_APP_CONSOLE_WHITELIST_IPS=

# Secrets (simples en dev, complexes en prod)
_APP_OPENSSL_KEY_V1=dev-key-not-for-production-use-only
_APP_EXECUTOR_SECRET=dev-executor-secret-change-in-prod

# Base de donnees
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=appwrite
MYSQL_USER=appwrite
MYSQL_PASSWORD=password
_APP_DB_USER=appwrite
_APP_DB_PASS=password
_APP_DB_SCHEMA=appwrite

# Redis (pas de mot de passe en dev)
_APP_REDIS_USER=
_APP_REDIS_PASS=

# Logging verbose
_APP_LOGGING_PROVIDER=
_APP_LOGGING_CONFIG=

# Workers
_APP_WORKER_PER_CORE=4

# Functions - limites elevees pour le debug
_APP_FUNCTIONS_TIMEOUT=900
_APP_FUNCTIONS_BUILD_TIMEOUT=900
```

### Services supplementaires (Override)

Le fichier `docker-compose.override.yml` ajoute:

| Service | Port | Description |
|---------|------|-------------|
| Mailhog | 1025, 8025 | Capture SMTP |
| Adminer | 8081 | Admin MariaDB |
| Redis Commander | 8082 | Admin Redis |

### URLs de developpement

| Service | URL |
|---------|-----|
| Appwrite Console | http://localhost |
| Appwrite API | http://localhost/v1 |
| Appwrite Direct | http://localhost:9000 |
| Traefik Dashboard | http://localhost:8080 |
| Adminer | http://localhost:8081 |
| Redis Commander | http://localhost:8082 |
| Mailhog | http://localhost:8025 |
| MariaDB | localhost:3306 |
| Redis | localhost:6379 |

---

## Environnement de test

### Caracteristiques

- Utilise pour CI/CD
- Donnees de test automatisees
- Isolation complete
- Pas de persistance entre les runs
- Configuration proche de la production

### Demarrage

```bash
# Utiliser un projet Docker Compose separe
COMPOSE_PROJECT_NAME=fug-test docker compose -f docker-compose.yml up -d

# Ou avec le Makefile
make up-prod  # Sans les outils de dev
```

### Configuration .env pour les tests

```ini
# =============================================================================
# ENVIRONNEMENT TEST
# =============================================================================

# Core
_APP_ENV=production  # Simule la prod
_APP_LOCALE=fr
_APP_OPTIONS_ABUSE=enabled
_APP_OPTIONS_FORCE_HTTPS=disabled  # Pas de SSL en test local

# Domaine
_APP_DOMAIN=localhost
_APP_DOMAIN_TARGET=localhost
_APP_DOMAIN_FUNCTIONS=functions.localhost

# Console - restreint
_APP_CONSOLE_WHITELIST_ROOT=enabled
_APP_CONSOLE_WHITELIST_EMAILS=test@example.com
_APP_CONSOLE_WHITELIST_IPS=

# Secrets de test (uniques, differents de dev/prod)
_APP_OPENSSL_KEY_V1=test-key-unique-per-environment
_APP_EXECUTOR_SECRET=test-executor-secret-unique

# Base de donnees
MYSQL_ROOT_PASSWORD=testroot
MYSQL_DATABASE=appwrite_test
MYSQL_USER=appwrite_test
MYSQL_PASSWORD=testpassword
_APP_DB_USER=appwrite_test
_APP_DB_PASS=testpassword
_APP_DB_SCHEMA=appwrite_test

# Redis
_APP_REDIS_USER=
_APP_REDIS_PASS=

# Workers reduits
_APP_WORKER_PER_CORE=2

# Functions - timeouts courts pour les tests
_APP_FUNCTIONS_TIMEOUT=60
_APP_FUNCTIONS_BUILD_TIMEOUT=120
```

### Configuration migrations pour les tests

Fichier `migrations/environments/.env.test`:

```ini
# FUG Migrations - Test Environment
APPWRITE_ENDPOINT=http://localhost/v1
APPWRITE_PROJECT_ID=fug-test
APPWRITE_API_KEY=your-test-api-key-here
DATABASE_ID=fug-db-test
```

### Integration CI/CD

**Exemple GitHub Actions:**

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Start infrastructure
        working-directory: ./infrastructure
        run: |
          cp .env.example .env
          # Modifier pour l'environnement de test
          sed -i 's/_APP_ENV=development/_APP_ENV=production/' .env
          docker compose -f docker-compose.yml up -d

      - name: Wait for Appwrite
        working-directory: ./infrastructure
        run: |
          ./scripts/wait-for-appwrite.sh

      - name: Run migrations
        working-directory: ./infrastructure/migrations
        run: |
          cp environments/.env.test .env
          npm install
          npm run migrate

      - name: Run tests
        run: |
          npm test

      - name: Cleanup
        if: always()
        working-directory: ./infrastructure
        run: |
          docker compose down -v
```

---

## Environnement de production

### Caracteristiques

- Securite maximale
- HTTPS obligatoire
- Protection anti-abus activee
- Pas d'outils de debug
- Monitoring active
- Backups quotidiens
- Alertes configurees

### Demarrage

```bash
# Utiliser uniquement docker-compose.yml (pas d'override)
make up-prod

# Equivalent a:
docker compose -f docker-compose.yml up -d
```

### Configuration .env pour la production

```ini
# =============================================================================
# ENVIRONNEMENT PRODUCTION
# =============================================================================
# ATTENTION: Ce fichier contient des secrets sensibles
# Ne JAMAIS commiter dans Git
# =============================================================================

# Core
_APP_ENV=production
_APP_LOCALE=fr
_APP_OPTIONS_ABUSE=enabled
_APP_OPTIONS_FORCE_HTTPS=enabled

# Domaine de production
_APP_DOMAIN=appwrite.fug.app
_APP_DOMAIN_TARGET=appwrite.fug.app
_APP_DOMAIN_FUNCTIONS=functions.fug.app

# Console - acces restreint
_APP_CONSOLE_WHITELIST_ROOT=enabled
_APP_CONSOLE_WHITELIST_EMAILS=admin@fug.app,ops@fug.app
_APP_CONSOLE_WHITELIST_IPS=

# =============================================================================
# SECRETS - GENERER AVEC: openssl rand -hex 64 (ou 32)
# =============================================================================
_APP_OPENSSL_KEY_V1=VOTRE_CLE_GENEREE_128_BITS_MINIMUM
_APP_EXECUTOR_SECRET=VOTRE_SECRET_EXECUTOR_256_BITS

# =============================================================================
# BASE DE DONNEES
# =============================================================================
MYSQL_ROOT_PASSWORD=MOT_DE_PASSE_ROOT_SECURISE
MYSQL_DATABASE=appwrite
MYSQL_USER=appwrite
MYSQL_PASSWORD=MOT_DE_PASSE_USER_SECURISE
_APP_DB_HOST=mariadb
_APP_DB_PORT=3306
_APP_DB_USER=appwrite
_APP_DB_PASS=MOT_DE_PASSE_USER_SECURISE
_APP_DB_SCHEMA=appwrite

# =============================================================================
# REDIS
# =============================================================================
_APP_REDIS_HOST=redis
_APP_REDIS_PORT=6379
_APP_REDIS_USER=
_APP_REDIS_PASS=MOT_DE_PASSE_REDIS_SI_NECESSAIRE

# =============================================================================
# SMTP (Production)
# =============================================================================
_APP_SMTP_HOST=smtp.provider.com
_APP_SMTP_PORT=587
_APP_SMTP_SECURE=tls
_APP_SMTP_USERNAME=votre-email@provider.com
_APP_SMTP_PASSWORD=votre-mot-de-passe-smtp

# =============================================================================
# STOCKAGE
# =============================================================================
_APP_STORAGE_LIMIT=52428800          # 50MB
_APP_STORAGE_PREVIEW_LIMIT=20000000  # 20MB
_APP_STORAGE_ANTIVIRUS=disabled
_APP_STORAGE_DEVICE=local            # ou s3

# Configuration S3 (si utilise)
# _APP_STORAGE_DEVICE=s3
# _APP_STORAGE_S3_ACCESS_KEY=votre-access-key
# _APP_STORAGE_S3_SECRET=votre-secret-key
# _APP_STORAGE_S3_REGION=eu-west-1
# _APP_STORAGE_S3_BUCKET=fug-storage

# =============================================================================
# FUNCTIONS
# =============================================================================
_APP_FUNCTIONS_SIZE_LIMIT=30000000   # 30MB
_APP_FUNCTIONS_TIMEOUT=300           # 5 minutes max
_APP_FUNCTIONS_BUILD_TIMEOUT=600     # 10 minutes max
_APP_FUNCTIONS_CPUS=1
_APP_FUNCTIONS_MEMORY=512
_APP_FUNCTIONS_RUNTIMES=node-18.0,node-20.0,dart-3.0

# =============================================================================
# MAINTENANCE
# =============================================================================
_APP_MAINTENANCE_INTERVAL=86400
_APP_MAINTENANCE_RETENTION_EXECUTION=1209600
_APP_MAINTENANCE_RETENTION_CACHE=2592000
_APP_MAINTENANCE_RETENTION_ABUSE=86400
_APP_MAINTENANCE_RETENTION_AUDIT=2592000  # 30 jours en prod
_APP_MAINTENANCE_RETENTION_USAGE_HOURLY=8640000
_APP_MAINTENANCE_RETENTION_SCHEDULES=86400

# =============================================================================
# WORKERS
# =============================================================================
_APP_WORKER_PER_CORE=6

# =============================================================================
# LOGGING (Optionnel - Sentry, etc.)
# =============================================================================
# _APP_LOGGING_PROVIDER=sentry
# _APP_LOGGING_CONFIG={"dsn":"https://xxx@sentry.io/yyy"}

# =============================================================================
# MONITORING
# =============================================================================
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=MOT_DE_PASSE_INFLUXDB_SECURISE
INFLUXDB_ORG=fug
INFLUXDB_BUCKET=appwrite
INFLUXDB_TOKEN=TOKEN_INFLUXDB_SECURISE

# =============================================================================
# BACKUP
# =============================================================================
BACKUP_DIR=/var/backups/fug
BACKUP_RETENTION_DAYS=30
```

### Configuration migrations pour la production

Fichier `migrations/environments/.env.production`:

```ini
# FUG Migrations - Production Environment
# DANGER: This is the production configuration!
APPWRITE_ENDPOINT=https://appwrite.fug.app/v1
APPWRITE_PROJECT_ID=fug-prod

# API Key via variable systeme pour securite
# Set via: export APPWRITE_API_KEY=your-production-key
APPWRITE_API_KEY=${APPWRITE_API_KEY}

DATABASE_ID=fug-db
```

### URLs de production

| Service | URL |
|---------|-----|
| Appwrite Console | https://appwrite.fug.app |
| Appwrite API | https://appwrite.fug.app/v1 |
| Appwrite Realtime | wss://appwrite.fug.app/v1/realtime |

---

## Variables par environnement

### Tableau comparatif complet

| Variable | Dev | Test | Prod |
|----------|-----|------|------|
| `_APP_ENV` | development | production | production |
| `_APP_OPTIONS_ABUSE` | disabled | enabled | enabled |
| `_APP_OPTIONS_FORCE_HTTPS` | disabled | disabled | enabled |
| `_APP_DOMAIN` | localhost | localhost | appwrite.fug.app |
| `_APP_CONSOLE_WHITELIST_ROOT` | enabled | enabled | enabled |
| `_APP_CONSOLE_WHITELIST_EMAILS` | (vide) | test@example.com | admin@fug.app |
| `_APP_WORKER_PER_CORE` | 4 | 2 | 6 |
| `_APP_FUNCTIONS_TIMEOUT` | 900 | 60 | 300 |
| `_APP_MAINTENANCE_RETENTION_AUDIT` | 1209600 | 86400 | 2592000 |
| `MYSQL_PASSWORD` | password | testpassword | (securise) |
| `_APP_OPENSSL_KEY_V1` | dev-key... | test-key... | (securise) |

### Generation de la configuration par environnement

```bash
#!/bin/bash
# generate-env.sh - Generer un fichier .env pour un environnement

ENV=${1:-development}
OUTPUT=".env.${ENV}"

case $ENV in
    development)
        cp .env.example "$OUTPUT"
        sed -i 's/_APP_ENV=.*/_APP_ENV=development/' "$OUTPUT"
        sed -i 's/_APP_OPTIONS_ABUSE=.*/_APP_OPTIONS_ABUSE=disabled/' "$OUTPUT"
        ;;
    test)
        cp .env.example "$OUTPUT"
        sed -i 's/_APP_ENV=.*/_APP_ENV=production/' "$OUTPUT"
        sed -i 's/MYSQL_DATABASE=.*/MYSQL_DATABASE=appwrite_test/' "$OUTPUT"
        sed -i 's/_APP_DB_SCHEMA=.*/_APP_DB_SCHEMA=appwrite_test/' "$OUTPUT"
        ;;
    production)
        cp .env.example "$OUTPUT"
        sed -i 's/_APP_ENV=.*/_APP_ENV=production/' "$OUTPUT"
        sed -i 's/_APP_OPTIONS_FORCE_HTTPS=.*/_APP_OPTIONS_FORCE_HTTPS=enabled/' "$OUTPUT"
        sed -i 's/_APP_DOMAIN=.*/_APP_DOMAIN=appwrite.fug.app/' "$OUTPUT"
        echo ""
        echo "ATTENTION: Remplacez les secrets par des valeurs securisees!"
        echo "Utilisez: openssl rand -hex 64"
        ;;
esac

echo "Fichier $OUTPUT genere."
```

---

## Processus de promotion

### Pipeline de deploiement

```
DEVELOPPEMENT          TEST                   PRODUCTION
     |                   |                        |
     |    Commit PR      |                        |
     +------------------>|                        |
     |                   |                        |
     |            Tests automatises               |
     |                   |                        |
     |              Merge main                    |
     |                   +----------------------->|
     |                   |                        |
     |                   |        Deploiement     |
     |                   |        automatique     |
     |                   |            ou          |
     |                   |         manuel         |
     |                   |                        |
     v                   v                        v
  localhost           localhost              fug.app
```

### Etapes de promotion Dev -> Test

1. **Creer une Pull Request**
   ```bash
   git checkout -b feature/ma-feature
   # ... developpement ...
   git push origin feature/ma-feature
   # Creer PR sur GitHub
   ```

2. **Tests automatiques (CI)**
   - Lint du code
   - Tests unitaires
   - Tests d'integration
   - Build des images

3. **Review et merge**
   - Code review par un pair
   - Approbation
   - Merge dans `main`

### Etapes de promotion Test -> Prod

1. **Preparation**
   ```bash
   # Verifier les migrations
   cd infrastructure/migrations
   npm run migrate:dry-run -- --env production

   # Verifier les fonctions
   cd ../functions
   appwrite functions list
   ```

2. **Backup pre-deploiement**
   ```bash
   # Sur le serveur de production
   cd /path/to/FUG/infrastructure
   make backup
   ```

3. **Deploiement**
   ```bash
   # Methode 1: Pull et redemarrage
   git pull origin main
   make pull
   make down
   make up-prod

   # Methode 2: Rolling update (si disponible)
   docker compose pull
   docker compose up -d --no-deps appwrite
   ```

4. **Verification post-deploiement**
   ```bash
   # Verifier la sante
   make health

   # Verifier les logs
   make logs-appwrite | head -100

   # Test fonctionnel
   curl https://appwrite.fug.app/v1/health
   ```

5. **Rollback si necessaire**
   ```bash
   # Restaurer le backup
   make restore-db BACKUP_FILE=./backups/db-YYYYMMDD-HHMMSS.sql

   # Redemarrer avec l'ancienne version
   docker compose down
   git checkout HEAD~1
   make up-prod
   ```

---

## Checklist de deploiement

### Pre-deploiement

- [ ] Code review approuve
- [ ] Tests CI passes
- [ ] Migrations testees en staging
- [ ] Documentation mise a jour
- [ ] Changelog prepare
- [ ] Backup production effectue
- [ ] Fenetre de maintenance communiquee

### Deploiement

- [ ] Pull des dernieres modifications
- [ ] Pull des nouvelles images Docker
- [ ] Arret des services
- [ ] Execution des migrations
- [ ] Demarrage des services
- [ ] Verification du health check

### Post-deploiement

- [ ] Verification des logs (pas d'erreurs)
- [ ] Test fonctionnel de base
- [ ] Verification du monitoring
- [ ] Test des fonctionnalites critiques
- [ ] Communication de fin de maintenance
- [ ] Documentation du deploiement

### Rollback (si necessaire)

- [ ] Identifier le probleme
- [ ] Decider du rollback
- [ ] Restaurer le backup
- [ ] Redeployer l'ancienne version
- [ ] Verifier la restauration
- [ ] Documenter l'incident
- [ ] Post-mortem

---

## Scripts utiles

### Script de deploiement

```bash
#!/bin/bash
# deploy.sh - Script de deploiement production

set -e

ENV=${1:-production}
BACKUP_BEFORE=${BACKUP_BEFORE:-true}

echo "=== DEPLOIEMENT FUG - $ENV ==="
echo "Date: $(date)"

# Verification
if [ "$ENV" = "production" ]; then
    read -p "Deployer en PRODUCTION? [y/N] " confirm
    [ "$confirm" != "y" ] && exit 0
fi

# Backup
if [ "$BACKUP_BEFORE" = "true" ]; then
    echo ">>> Backup pre-deploiement..."
    make backup
fi

# Pull
echo ">>> Pull des modifications..."
git pull origin main

# Update images
echo ">>> Mise a jour des images..."
make pull

# Restart
echo ">>> Redemarrage des services..."
make down
make up-prod

# Wait
echo ">>> Attente du demarrage..."
./scripts/wait-for-appwrite.sh

# Health check
echo ">>> Verification sante..."
make health

echo "=== DEPLOIEMENT TERMINE ==="
```

### Script de rollback

```bash
#!/bin/bash
# rollback.sh - Script de rollback

set -e

BACKUP_FILE=${1:-}

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    echo ""
    echo "Backups disponibles:"
    ls -la backups/*.tar.gz
    exit 1
fi

echo "=== ROLLBACK FUG ==="
echo "Backup: $BACKUP_FILE"

read -p "Confirmer le rollback? [y/N] " confirm
[ "$confirm" != "y" ] && exit 0

# Extraire et restaurer
tar -xzf "$BACKUP_FILE" -C /tmp
BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz)

# Arreter les services
make down

# Restaurer la DB
make restore-db BACKUP_FILE=/tmp/$BACKUP_NAME/database.sql

# Redemarrer
make up-prod

# Verifier
make health

# Nettoyer
rm -rf /tmp/$BACKUP_NAME

echo "=== ROLLBACK TERMINE ==="
```

---

*Documentation Environnements FUG - Janvier 2026*
