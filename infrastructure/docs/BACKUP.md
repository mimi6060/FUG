# Strategie de Backup - Infrastructure FUG

Documentation complete pour la sauvegarde et la restauration de l'infrastructure FUG.

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Strategie de backup](#strategie-de-backup)
- [Backup MariaDB](#backup-mariadb)
- [Backup des volumes](#backup-des-volumes)
- [Backup automatique](#backup-automatique)
- [Restauration](#restauration)
- [Tests de restauration](#tests-de-restauration)
- [Retention et archivage](#retention-et-archivage)

---

## Vue d'ensemble

### Donnees a sauvegarder

| Categorie | Donnees | Criticite | Frequence |
|-----------|---------|-----------|-----------|
| Base de donnees | MariaDB (utilisateurs, documents, config) | CRITIQUE | Quotidien |
| Fichiers | Uploads utilisateurs | CRITIQUE | Quotidien |
| Configuration | Appwrite config, certificats | HAUTE | Hebdomadaire |
| Fonctions | Code source des fonctions | MOYENNE | Hebdomadaire |
| Cache | Redis, cache Appwrite | FAIBLE | Non necessaire |

### RPO et RTO

| Metrique | Objectif | Description |
|----------|----------|-------------|
| **RPO** (Recovery Point Objective) | 24 heures | Perte de donnees maximale acceptable |
| **RTO** (Recovery Time Objective) | 4 heures | Temps de restauration maximal |

---

## Strategie de backup

### Backup quotidien (automatique)

- **Heure**: 03:00 UTC
- **Contenu**:
  - Dump complet MariaDB
  - Snapshot des volumes critiques
- **Retention**: 7 jours

### Backup hebdomadaire (automatique)

- **Jour**: Dimanche 02:00 UTC
- **Contenu**:
  - Dump complet MariaDB
  - Tous les volumes Appwrite
  - Configuration complete
- **Retention**: 4 semaines

### Backup mensuel (recommande)

- **Jour**: Premier dimanche du mois
- **Contenu**:
  - Backup hebdomadaire complet
  - Export vers stockage externe (S3, GCS, etc.)
- **Retention**: 12 mois

---

## Backup MariaDB

### Backup manuel rapide

```bash
# Backup via Makefile
make backup-db
```

Cette commande cree un fichier `backups/db-YYYYMMDD-HHMMSS.sql`.

### Backup manuel detaille

```bash
# Se placer dans le repertoire infrastructure
cd /path/to/FUG/infrastructure

# Creer le repertoire de backup
mkdir -p backups

# Effectuer le dump
docker compose exec -T mariadb mysqldump \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    appwrite > backups/db-$(date +%Y%m%d-%H%M%S).sql

# Verifier le fichier
ls -la backups/
```

### Options de dump recommandees

| Option | Description |
|--------|-------------|
| `--single-transaction` | Dump coherent sans verrouiller les tables |
| `--routines` | Inclure les procedures stockees |
| `--triggers` | Inclure les triggers |
| `--events` | Inclure les evenements MySQL |
| `--quick` | Moins de memoire pour gros volumes |
| `--compress` | Compression pendant le transfert |

### Backup compresse

```bash
# Dump compresse avec gzip
docker compose exec -T mariadb mysqldump \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    --single-transaction \
    appwrite | gzip > backups/db-$(date +%Y%m%d-%H%M%S).sql.gz

# Dump compresse avec zstd (plus rapide)
docker compose exec -T mariadb mysqldump \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    --single-transaction \
    appwrite | zstd > backups/db-$(date +%Y%m%d-%H%M%S).sql.zst
```

---

## Backup des volumes

### Backup d'un volume specifique

```bash
# Backup du volume uploads
docker run --rm \
    -v fug-appwrite-uploads:/source:ro \
    -v $(pwd)/backups:/backup \
    alpine:latest \
    tar -czf /backup/uploads-$(date +%Y%m%d-%H%M%S).tar.gz -C /source .
```

### Backup de tous les volumes

```bash
# Utiliser le script de backup
./scripts/backup.sh
```

Le script effectue:
1. Dump de la base de donnees
2. Backup de tous les volumes Docker
3. Creation d'une archive unique
4. Nettoyage des anciens backups

### Liste des volumes a sauvegarder

```bash
# Volumes critiques (obligatoire)
CRITICAL_VOLUMES=(
    "fug-appwrite-uploads"      # Fichiers utilisateurs
    "fug-appwrite-certificates" # Certificats SSL
    "fug-mariadb-data"         # Base de donnees
)

# Volumes importants (recommande)
IMPORTANT_VOLUMES=(
    "fug-appwrite-config"      # Configuration
    "fug-appwrite-functions"   # Code des fonctions
    "fug-redis-data"          # Sessions/cache persistant
)

# Volumes regenerables (optionnel)
OPTIONAL_VOLUMES=(
    "fug-appwrite-cache"      # Cache applicatif
    "fug-appwrite-builds"     # Builds des fonctions
)
```

### Verification des volumes

```bash
# Lister tous les volumes FUG
docker volume ls | grep fug

# Inspecter un volume
docker volume inspect fug-appwrite-uploads

# Verifier la taille d'un volume
docker run --rm \
    -v fug-appwrite-uploads:/data \
    alpine:latest \
    du -sh /data
```

---

## Backup automatique

### Configuration du script backup.sh

Le script `scripts/backup.sh` gere les backups automatiques.

**Variables de configuration:**

```bash
# Dans .env ou en variable d'environnement
BACKUP_DIR=./backups           # Repertoire de destination
BACKUP_RETENTION_DAYS=7        # Retention en jours
```

### Planification avec cron

```bash
# Ouvrir crontab
crontab -e

# Backup quotidien a 3h00
0 3 * * * cd /path/to/FUG/infrastructure && ./scripts/backup.sh >> /var/log/fug-backup.log 2>&1

# Backup hebdomadaire le dimanche a 2h00
0 2 * * 0 cd /path/to/FUG/infrastructure && BACKUP_RETENTION_DAYS=28 ./scripts/backup.sh >> /var/log/fug-backup.log 2>&1
```

### Planification avec systemd (recommande)

**Service: /etc/systemd/system/fug-backup.service**

```ini
[Unit]
Description=FUG Infrastructure Backup
After=docker.service

[Service]
Type=oneshot
User=root
WorkingDirectory=/path/to/FUG/infrastructure
ExecStart=/path/to/FUG/infrastructure/scripts/backup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Timer: /etc/systemd/system/fug-backup.timer**

```ini
[Unit]
Description=FUG Backup Timer

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
```

**Activation:**

```bash
# Activer le timer
sudo systemctl daemon-reload
sudo systemctl enable fug-backup.timer
sudo systemctl start fug-backup.timer

# Verifier le statut
sudo systemctl status fug-backup.timer
sudo systemctl list-timers | grep fug
```

### Export vers stockage externe

**Script d'export S3:**

```bash
#!/bin/bash
# export-s3.sh - Exporter les backups vers S3

BACKUP_DIR="/path/to/FUG/infrastructure/backups"
S3_BUCKET="s3://mon-bucket-backup/fug/"
DATE=$(date +%Y%m%d)

# Trouver le dernier backup
LATEST_BACKUP=$(ls -t ${BACKUP_DIR}/fug-backup-*.tar.gz | head -1)

if [ -f "$LATEST_BACKUP" ]; then
    # Upload vers S3
    aws s3 cp "$LATEST_BACKUP" "${S3_BUCKET}$(basename $LATEST_BACKUP)"

    # Nettoyer les vieux backups sur S3 (garder 30 jours)
    aws s3 ls "$S3_BUCKET" | \
        while read -r line; do
            create_date=$(echo $line | awk '{print $1}')
            file_name=$(echo $line | awk '{print $4}')
            create_ts=$(date -d "$create_date" +%s)
            current_ts=$(date +%s)
            older_than=$((current_ts - 2592000)) # 30 jours
            if [[ $create_ts -lt $older_than ]]; then
                aws s3 rm "${S3_BUCKET}${file_name}"
            fi
        done

    echo "Backup exporte: $LATEST_BACKUP"
else
    echo "Aucun backup trouve!"
    exit 1
fi
```

---

## Restauration

### Restauration de la base de donnees

```bash
# Methode 1: Via Makefile
make restore-db BACKUP_FILE=./backups/db-20260118-030000.sql

# Methode 2: Commande directe
docker compose exec -T mariadb mysql \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    appwrite < ./backups/db-20260118-030000.sql

# Methode 3: Fichier compresse
gunzip < backups/db-20260118-030000.sql.gz | \
    docker compose exec -T mariadb mysql \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    appwrite
```

### Restauration d'un volume

```bash
# 1. Arreter les services qui utilisent le volume
docker compose stop appwrite appwrite-executor

# 2. Supprimer l'ancien volume
docker volume rm fug-appwrite-uploads

# 3. Recreer le volume
docker volume create fug-appwrite-uploads

# 4. Restaurer les donnees
docker run --rm \
    -v fug-appwrite-uploads:/target \
    -v $(pwd)/backups:/backup:ro \
    alpine:latest \
    tar -xzf /backup/fug-appwrite-uploads.tar.gz -C /target

# 5. Redemarrer les services
docker compose start appwrite appwrite-executor
```

### Restauration complete

**Procedure de restauration complete:**

```bash
#!/bin/bash
# restore-full.sh - Restauration complete de l'infrastructure

BACKUP_FILE="$1"
BACKUP_DIR="./restore-temp"

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file.tar.gz>"
    exit 1
fi

echo "=== RESTAURATION COMPLETE FUG ==="
echo "Fichier: $BACKUP_FILE"
echo ""
read -p "ATTENTION: Cela va REMPLACER toutes les donnees. Continuer? [y/N] " confirm
if [ "$confirm" != "y" ]; then
    echo "Annule."
    exit 0
fi

# 1. Arreter tous les services
echo ">>> Arret des services..."
docker compose down

# 2. Extraire le backup
echo ">>> Extraction du backup..."
mkdir -p "$BACKUP_DIR"
tar -xzf "$BACKUP_FILE" -C "$BACKUP_DIR"

# 3. Identifier le dossier extrait
BACKUP_NAME=$(ls "$BACKUP_DIR" | head -1)

# 4. Supprimer les anciens volumes
echo ">>> Suppression des anciens volumes..."
docker volume rm fug-mariadb-data fug-appwrite-uploads fug-appwrite-config \
    fug-appwrite-certificates fug-appwrite-functions fug-redis-data 2>/dev/null

# 5. Recreer les volumes
echo ">>> Recreation des volumes..."
docker volume create fug-mariadb-data
docker volume create fug-appwrite-uploads
docker volume create fug-appwrite-config
docker volume create fug-appwrite-certificates
docker volume create fug-appwrite-functions
docker volume create fug-redis-data

# 6. Restaurer les volumes
echo ">>> Restauration des volumes..."
for vol_file in "$BACKUP_DIR/$BACKUP_NAME/volumes/"*.tar.gz; do
    vol_name=$(basename "$vol_file" .tar.gz)
    echo "  - $vol_name"
    docker run --rm \
        -v "$vol_name:/target" \
        -v "$(pwd)/$BACKUP_DIR/$BACKUP_NAME/volumes:/backup:ro" \
        alpine:latest \
        tar -xzf "/backup/$(basename $vol_file)" -C /target
done

# 7. Demarrer les services de base
echo ">>> Demarrage de MariaDB..."
docker compose up -d mariadb
sleep 30

# 8. Restaurer la base de donnees
echo ">>> Restauration de la base de donnees..."
docker compose exec -T mariadb mysql \
    -u appwrite \
    -p"$MYSQL_PASSWORD" \
    appwrite < "$BACKUP_DIR/$BACKUP_NAME/database.sql"

# 9. Demarrer tous les services
echo ">>> Demarrage complet..."
docker compose up -d

# 10. Nettoyage
echo ">>> Nettoyage..."
rm -rf "$BACKUP_DIR"

# 11. Verification
echo ">>> Verification..."
sleep 60
make health

echo ""
echo "=== RESTAURATION TERMINEE ==="
echo "Verifiez que tous les services fonctionnent correctement."
```

---

## Tests de restauration

### Test de restauration mensuel (recommande)

Procedure de test a executer chaque mois:

```bash
#!/bin/bash
# test-restore.sh - Test de restauration sur environnement isole

# 1. Creer un environnement de test isole
echo ">>> Creation de l'environnement de test..."
export COMPOSE_PROJECT_NAME=fug-test
export COMPOSE_FILE=docker-compose.yml

# Modifier les ports pour eviter les conflits
# (utiliser un docker-compose.test.yml avec des ports differents)

# 2. Demarrer l'environnement vide
docker compose -p fug-test up -d mariadb redis
sleep 30

# 3. Restaurer le dernier backup
LATEST_BACKUP=$(ls -t ./backups/fug-backup-*.tar.gz | head -1)
echo ">>> Test avec: $LATEST_BACKUP"

# 4. Extraire et restaurer (procedure simplifiee)
# ...

# 5. Verifier les donnees
echo ">>> Verification des donnees..."
docker compose -p fug-test exec -T mariadb mysql \
    -u appwrite -p"$MYSQL_PASSWORD" \
    -e "SELECT COUNT(*) FROM appwrite._metadata;" appwrite

# 6. Nettoyer l'environnement de test
echo ">>> Nettoyage..."
docker compose -p fug-test down -v

echo ">>> Test de restauration termine!"
```

### Checklist de verification post-restauration

- [ ] MariaDB repond aux requetes
- [ ] Redis contient des donnees
- [ ] L'API Appwrite repond (`/v1/health`)
- [ ] Les utilisateurs peuvent se connecter
- [ ] Les documents sont accessibles
- [ ] Les fichiers uploades sont presents
- [ ] Les fonctions s'executent correctement
- [ ] Les certificats SSL sont valides

---

## Retention et archivage

### Politique de retention

| Type de backup | Retention | Stockage |
|----------------|-----------|----------|
| Quotidien | 7 jours | Local |
| Hebdomadaire | 4 semaines | Local + Externe |
| Mensuel | 12 mois | Externe uniquement |
| Annuel | 7 ans | Archive froide |

### Nettoyage automatique

Le script `backup.sh` nettoie automatiquement les anciens backups selon la variable `BACKUP_RETENTION_DAYS`.

**Nettoyage manuel:**

```bash
# Supprimer les backups de plus de 7 jours
find ./backups -name "fug-backup-*.tar.gz" -type f -mtime +7 -delete

# Verifier l'espace utilise
du -sh ./backups/
```

### Verification de l'integrite

```bash
# Verifier l'integrite d'une archive
gzip -t backups/fug-backup-20260118-030000.tar.gz && echo "OK" || echo "CORROMPU"

# Lister le contenu sans extraire
tar -tzf backups/fug-backup-20260118-030000.tar.gz

# Calculer le checksum
sha256sum backups/fug-backup-*.tar.gz > backups/checksums.sha256

# Verifier les checksums
sha256sum -c backups/checksums.sha256
```

---

## Recommandations

### Bonnes pratiques

1. **Tester les restaurations** - Au minimum une fois par mois
2. **Chiffrer les backups** - Surtout pour le stockage externe
3. **Diversifier les emplacements** - Local + Cloud + Site distant
4. **Monitorer les backups** - Alertes en cas d'echec
5. **Documenter les procedures** - Instructions claires pour l'equipe

### Chiffrement des backups

```bash
# Chiffrer un backup avec GPG
gpg --symmetric --cipher-algo AES256 \
    backups/fug-backup-20260118-030000.tar.gz

# Dechiffrer
gpg --decrypt backups/fug-backup-20260118-030000.tar.gz.gpg \
    > backups/fug-backup-20260118-030000.tar.gz
```

### Alertes de monitoring

Configurer des alertes pour:
- Echec du backup quotidien
- Espace disque backup < 20%
- Aucun backup depuis 48h
- Checksum invalide

---

*Documentation Backup FUG - Janvier 2026*
