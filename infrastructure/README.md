# FUG Infrastructure - Guide Complet

Documentation complete pour l'infrastructure Docker du projet FUG (Appwrite Self-Hosted).

## Table des matieres

- [Prerequis](#prerequis)
- [Installation rapide](#installation-rapide)
- [Installation detaillee](#installation-detaillee)
- [Configuration des environnements](#configuration-des-environnements)
- [Commandes Makefile](#commandes-makefile)
- [URLs des services](#urls-des-services)
- [Troubleshooting](#troubleshooting)
- [Documentation supplementaire](#documentation-supplementaire)

---

## Prerequis

### Logiciels requis

| Logiciel | Version minimale | Verification |
|----------|------------------|--------------|
| Docker | 24.0+ | `docker --version` |
| Docker Compose | 2.20+ | `docker compose version` |
| Node.js | 20.0+ | `node --version` |
| Make | 4.0+ | `make --version` |

### Verification des prerequis

```bash
# Verifier Docker
docker --version
# Attendu: Docker version 24.x.x ou superieur

# Verifier Docker Compose
docker compose version
# Attendu: Docker Compose version v2.20.x ou superieur

# Verifier Node.js (pour les scripts de setup)
node --version
# Attendu: v20.x.x ou superieur

# Verifier Make
make --version
# Attendu: GNU Make 4.x ou superieur
```

### Installation des prerequis

#### macOS (Homebrew)

```bash
# Docker Desktop (inclut Docker Compose)
brew install --cask docker

# Node.js 20
brew install node@20

# Make (generalement pre-installe)
brew install make
```

#### Ubuntu/Debian

```bash
# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Make
sudo apt-get install -y make
```

#### Windows

```powershell
# Docker Desktop
winget install Docker.DockerDesktop

# Node.js
winget install OpenJS.NodeJS.LTS

# Make (via Chocolatey)
choco install make
```

### Ressources systeme recommandees

| Environnement | CPU | RAM | Disque |
|---------------|-----|-----|--------|
| Developpement | 2 coeurs | 4 Go | 20 Go |
| Test | 4 coeurs | 8 Go | 50 Go |
| Production | 8 coeurs | 16 Go | 100 Go+ |

---

## Installation rapide

Pour demarrer rapidement en **5 commandes**:

```bash
# 1. Aller dans le dossier infrastructure
cd /path/to/FUG/infrastructure

# 2. Creer le fichier de configuration
make env

# 3. Editer le fichier .env avec vos parametres (optionnel en dev)
nano .env

# 4. Demarrer l'infrastructure
make up

# 5. Initialiser et attendre qu'Appwrite soit pret
make init
```

Une fois termine, Appwrite est accessible sur **http://localhost**

---

## Installation detaillee

### Etape 1: Preparation de l'environnement

```bash
# Aller dans le dossier infrastructure
cd /path/to/FUG/infrastructure

# Creer le fichier .env a partir du template
cp .env.example .env
```

### Etape 2: Configuration des variables d'environnement

Editez le fichier `.env` et modifiez les valeurs selon vos besoins.

**Generer des cles secretes uniques:**

```bash
# Cle OpenSSL (minimum 128 bits) - OBLIGATOIRE
openssl rand -hex 64

# Secret pour l'executor - OBLIGATOIRE
openssl rand -hex 32
```

**Variables essentielles a modifier:**

```ini
# =============================================================================
# SECURITE - OBLIGATOIRE EN PRODUCTION
# =============================================================================
_APP_OPENSSL_KEY_V1=votre-cle-generee-avec-openssl-rand-hex-64
_APP_EXECUTOR_SECRET=votre-cle-generee-avec-openssl-rand-hex-32

# =============================================================================
# BASE DE DONNEES
# =============================================================================
MYSQL_ROOT_PASSWORD=mot-de-passe-root-securise
MYSQL_PASSWORD=mot-de-passe-appwrite-securise
_APP_DB_PASS=mot-de-passe-appwrite-securise

# =============================================================================
# DOMAINE (pour la production)
# =============================================================================
_APP_DOMAIN=votre-domaine.com
_APP_DOMAIN_TARGET=votre-domaine.com
_APP_DOMAIN_FUNCTIONS=functions.votre-domaine.com
```

### Etape 3: Demarrage des services

```bash
# Mode developpement (avec outils de debug)
make up

# Mode production (sans outils de debug)
make up-prod

# Avec monitoring (InfluxDB + Telegraf)
make up-monitoring
```

### Etape 4: Verification du demarrage

```bash
# Attendre qu'Appwrite soit completement operationnel
./scripts/wait-for-appwrite.sh

# Verifier le statut des services
make status

# Verifier la sante des services
make health
```

### Etape 5: Configuration initiale d'Appwrite

1. Ouvrez **http://localhost** dans votre navigateur
2. Creez votre compte administrateur
3. Creez un nouveau projet "FUG"
4. Notez le **Project ID** genere
5. Creez une **API Key** avec les permissions necessaires

**Pour automatiser la configuration:**

```bash
# Installer les dependances des scripts
cd scripts && npm install && cd ..

# Configurer les variables du script
cp scripts/.env.example scripts/.env
# Editer scripts/.env avec votre Project ID et API Key

# Executer le setup automatique
make setup
```

---

## Configuration des environnements

### Developpement (defaut)

Le mode developpement inclut des outils supplementaires pour faciliter le debug:

| Outil | Port | Description |
|-------|------|-------------|
| Traefik Dashboard | 8080 | Visualisation du reverse proxy |
| MariaDB | 3306 | Acces direct a la base de donnees |
| Redis | 6379 | Acces direct au cache |
| Mailhog | 8025 | Capture des emails de test |
| Adminer | 8081 | Interface d'administration DB |
| Redis Commander | 8082 | Interface Redis |

```bash
# Demarrer en mode developpement
make up
```

**Specificites:**
- Logs verbeux actives
- Protection anti-abus desactivee
- HTTPS non obligatoire
- Hot-reload des fonctions

### Production

Le mode production est securise et optimise:

```bash
# Demarrer en mode production
make up-prod
```

**Specificites:**
- Pas d'exposition directe des ports internes
- Pas d'outils de debug
- HTTPS obligatoire
- Protection anti-abus activee
- Logs standards

**Variables specifiques a la production:**

```ini
_APP_ENV=production
_APP_OPTIONS_FORCE_HTTPS=enabled
_APP_OPTIONS_ABUSE=enabled
_APP_DOMAIN=votre-domaine.com
_APP_CONSOLE_WHITELIST_EMAILS=admin@votre-domaine.com
```

### Test

Pour les tests automatises et CI/CD:

```bash
# Utiliser l'environnement de test des migrations
cd migrations
cp environments/.env.test .env
```

---

## Commandes Makefile

### Demarrage et arret

| Commande | Description |
|----------|-------------|
| `make up` | Demarrer tous les services (mode dev) |
| `make up-prod` | Demarrer en mode production |
| `make up-monitoring` | Demarrer avec le monitoring |
| `make down` | Arreter tous les services |
| `make restart` | Redemarrer tous les services |

### Initialisation

| Commande | Description |
|----------|-------------|
| `make init` | Initialisation complete (up + wait + setup) |
| `make setup` | Configurer Appwrite (collections, buckets) |
| `make env` | Creer le fichier .env depuis .env.example |
| `make check-env` | Verifier la configuration .env |

### Monitoring et debug

| Commande | Description |
|----------|-------------|
| `make status` | Afficher le statut des containers |
| `make ps` | Alias pour status |
| `make logs` | Afficher les logs en temps reel |
| `make logs-appwrite` | Logs Appwrite uniquement |
| `make logs-db` | Logs MariaDB uniquement |
| `make health` | Verifier la sante des services |

### Acces aux services

| Commande | Description |
|----------|-------------|
| `make shell` | Ouvrir un shell dans le container Appwrite |
| `make db-shell` | Ouvrir un shell MySQL dans MariaDB |
| `make redis-cli` | Ouvrir le CLI Redis |

### Backup et maintenance

| Commande | Description |
|----------|-------------|
| `make backup` | Sauvegarder la DB et les volumes |
| `make backup-db` | Sauvegarder uniquement la base de donnees |
| `make restore-db BACKUP_FILE=path/to/file.sql` | Restaurer la base de donnees |
| `make clean` | Arreter et supprimer les volumes (DANGER!) |
| `make prune` | Nettoyer les ressources Docker inutilisees |
| `make pull` | Mettre a jour les images Docker |

---

## URLs des services

### Mode Developpement

| Service | URL | Description |
|---------|-----|-------------|
| Appwrite Console | http://localhost | Interface d'administration |
| Appwrite API | http://localhost/v1 | API REST |
| Appwrite Direct | http://localhost:9000 | Acces direct (sans Traefik) |
| Appwrite Realtime | ws://localhost/v1/realtime | WebSocket |
| Traefik Dashboard | http://localhost:8080 | Dashboard du reverse proxy |
| Adminer | http://localhost:8081 | Administration MariaDB |
| Redis Commander | http://localhost:8082 | Interface Redis |
| Mailhog | http://localhost:8025 | Emails de test |
| InfluxDB | http://localhost:8086 | Metriques (si monitoring actif) |

### Mode Production

| Service | URL | Description |
|---------|-----|-------------|
| Appwrite Console | https://votre-domaine.com | Interface d'administration |
| Appwrite API | https://votre-domaine.com/v1 | API REST |
| Appwrite Realtime | wss://votre-domaine.com/v1/realtime | WebSocket |

---

## Troubleshooting

### Appwrite ne demarre pas

**Symptome:** Le health check echoue apres plusieurs minutes.

**Solutions:**

```bash
# 1. Verifier les logs d'Appwrite
docker compose logs appwrite

# 2. Verifier que MariaDB est operationnel
docker compose logs mariadb
make health

# 3. Verifier que Redis est operationnel
docker compose logs redis

# 4. Redemarrer proprement
make down
make up
```

### Probleme de connexion a la base de donnees

**Symptome:** Erreur "Connection refused" ou "Access denied".

**Solutions:**

```bash
# 1. Verifier les credentials dans .env
grep MYSQL .env
grep _APP_DB .env

# 2. Verifier que MariaDB est pret
docker compose exec mariadb mysqladmin -u root -p status

# 3. Reinitialiser la base de donnees (ATTENTION: perte de donnees)
make down
docker volume rm fug-mariadb-data
make up
```

### Probleme de memoire

**Symptome:** Container qui redemarrent en boucle ou erreur "OOM killed".

**Solutions:**

```bash
# 1. Verifier l'utilisation memoire
docker stats

# 2. Augmenter la memoire allouee a Docker
# Dans Docker Desktop: Preferences > Resources > Memory

# 3. Reduire le nombre de workers
# Dans .env:
_APP_WORKER_PER_CORE=2
```

### Probleme de permissions sur les volumes

**Symptome:** Erreur "Permission denied" dans les logs.

**Solutions:**

```bash
# 1. Verifier les permissions des volumes
docker volume inspect fug-appwrite-uploads

# 2. Corriger les permissions (sur Linux)
sudo chown -R 1000:1000 /var/lib/docker/volumes/fug-*

# 3. Recreer les volumes si necessaire
make clean  # ATTENTION: perte de donnees
make up
```

### Les fonctions ne s'executent pas

**Symptome:** Les Cloud Functions ne se lancent pas ou echouent.

**Solutions:**

```bash
# 1. Verifier l'executor
docker compose logs appwrite-executor

# 2. Verifier le secret de l'executor
grep EXECUTOR_SECRET .env

# 3. Verifier que Docker socket est accessible
ls -la /var/run/docker.sock

# 4. Redemarrer l'executor
docker compose restart appwrite-executor appwrite-worker-builds appwrite-worker-functions
```

### Port 80 deja utilise

**Symptome:** `Error starting userland proxy: listen tcp 0.0.0.0:80: bind: address already in use`

**Solutions:**

```bash
# 1. Identifier le processus utilisant le port
sudo lsof -i :80

# 2. Arreter le service (ex: nginx, apache)
sudo systemctl stop nginx
# ou
sudo systemctl stop apache2

# 3. Alternative: modifier les ports dans docker-compose.override.yml
```

### Erreur de certificat SSL

**Symptome:** Erreur HTTPS ou certificat invalide.

**Solutions:**

```bash
# 1. En developpement, desactiver HTTPS
# Dans .env:
_APP_OPTIONS_FORCE_HTTPS=disabled

# 2. Verifier les certificats
docker compose logs appwrite-worker-certificates

# 3. Regenerer les certificats
docker compose restart appwrite-worker-certificates
```

### Commandes de diagnostic

```bash
# Statut complet de l'infrastructure
make status

# Sante de tous les services
make health

# Logs en temps reel
make logs

# Utilisation des ressources
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Espace disque des volumes
docker system df -v

# Verifier la connectivite reseau
docker network inspect fug-network
```

---

## Documentation supplementaire

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | Diagramme des services et flux reseau |
| [Backup](docs/BACKUP.md) | Strategies de sauvegarde et restauration |
| [Monitoring](docs/MONITORING.md) | Configuration Telegraf/InfluxDB/Grafana |
| [Securite](docs/SECURITY.md) | Gestion des secrets et bonnes pratiques |
| [Environnements](docs/ENVIRONMENTS.md) | Configuration dev/test/prod |

---

## Support

En cas de probleme:

1. Consultez les logs: `make logs`
2. Verifiez la sante: `make health`
3. Consultez cette documentation
4. Consultez la [documentation Appwrite](https://appwrite.io/docs)
5. Ouvrez une issue sur le repository du projet

---

*Documentation FUG Infrastructure - Appwrite Self-Hosted*
*Derniere mise a jour: Janvier 2026*
