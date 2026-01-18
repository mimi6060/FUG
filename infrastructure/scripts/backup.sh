#!/bin/bash
# =============================================================================
# FUG Project - Backup Script
# =============================================================================
# Ce script sauvegarde:
# - La base de donnees MariaDB
# - Les volumes Docker Appwrite (uploads, config, certificates, etc.)
# =============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-${PROJECT_DIR}/backups}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="fug-backup-${DATE}"

# Configuration Docker Compose
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
COMPOSE="docker compose -f ${COMPOSE_FILE}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Charger les variables d'environnement
if [ -f "${PROJECT_DIR}/.env" ]; then
    export $(grep -v '^#' "${PROJECT_DIR}/.env" | xargs)
fi

# Variables de base de donnees
DB_USER="${MYSQL_USER:-appwrite}"
DB_PASS="${MYSQL_PASSWORD:-password}"
DB_NAME="${MYSQL_DATABASE:-appwrite}"

# Volumes a sauvegarder
VOLUMES=(
    "fug-appwrite-uploads"
    "fug-appwrite-cache"
    "fug-appwrite-config"
    "fug-appwrite-certificates"
    "fug-appwrite-functions"
    "fug-appwrite-builds"
    "fug-mariadb-data"
    "fug-redis-data"
)

# =============================================================================
# FONCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verifier les prerequis
check_prerequisites() {
    log_info "Verification des prerequis..."

    # Verifier Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker n'est pas installe!"
        exit 1
    fi

    # Verifier que les containers tournent
    if ! $COMPOSE ps --quiet mariadb > /dev/null 2>&1; then
        log_error "Le container MariaDB n'est pas en cours d'execution!"
        log_info "Demarrez les services avec: make up"
        exit 1
    fi

    log_success "Prerequis OK"
}

# Creer le repertoire de backup
create_backup_dir() {
    log_info "Creation du repertoire de backup..."

    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
    mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}/volumes"

    log_success "Repertoire cree: ${BACKUP_DIR}/${BACKUP_NAME}"
}

# Backup de la base de donnees MariaDB
backup_database() {
    log_info "Sauvegarde de la base de donnees MariaDB..."

    local db_backup_file="${BACKUP_DIR}/${BACKUP_NAME}/database.sql"

    # Effectuer le dump
    $COMPOSE exec -T mariadb mysqldump \
        -u"${DB_USER}" \
        -p"${DB_PASS}" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        "${DB_NAME}" > "${db_backup_file}"

    if [ $? -eq 0 ] && [ -s "${db_backup_file}" ]; then
        local size=$(du -h "${db_backup_file}" | cut -f1)
        log_success "Base de donnees sauvegardee: ${db_backup_file} (${size})"
    else
        log_error "Echec de la sauvegarde de la base de donnees!"
        return 1
    fi
}

# Backup d'un volume Docker
backup_volume() {
    local volume_name=$1
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}/volumes/${volume_name}.tar.gz"

    log_info "Sauvegarde du volume: ${volume_name}..."

    # Verifier si le volume existe
    if ! docker volume inspect "${volume_name}" > /dev/null 2>&1; then
        log_warning "Volume non trouve: ${volume_name} (ignore)"
        return 0
    fi

    # Creer le backup du volume
    docker run --rm \
        -v "${volume_name}:/source:ro" \
        -v "${BACKUP_DIR}/${BACKUP_NAME}/volumes:/backup" \
        alpine:latest \
        tar -czf "/backup/${volume_name}.tar.gz" -C /source .

    if [ $? -eq 0 ]; then
        local size=$(du -h "${backup_file}" | cut -f1)
        log_success "Volume sauvegarde: ${volume_name} (${size})"
    else
        log_warning "Echec de la sauvegarde du volume: ${volume_name}"
    fi
}

# Backup de tous les volumes
backup_all_volumes() {
    log_info "Sauvegarde de tous les volumes Docker..."

    for volume in "${VOLUMES[@]}"; do
        backup_volume "$volume"
    done

    log_success "Sauvegarde des volumes terminee"
}

# Creer l'archive finale
create_archive() {
    log_info "Creation de l'archive finale..."

    local archive_file="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

    cd "${BACKUP_DIR}"
    tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"

    if [ $? -eq 0 ]; then
        local size=$(du -h "${archive_file}" | cut -f1)
        log_success "Archive creee: ${archive_file} (${size})"

        # Supprimer le repertoire temporaire
        rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"
    else
        log_error "Echec de la creation de l'archive!"
        return 1
    fi
}

# Nettoyer les anciens backups
cleanup_old_backups() {
    log_info "Nettoyage des backups de plus de ${RETENTION_DAYS} jours..."

    local count=0

    # Trouver et supprimer les anciens fichiers
    while IFS= read -r -d '' file; do
        rm -f "$file"
        count=$((count + 1))
    done < <(find "${BACKUP_DIR}" -name "fug-backup-*.tar.gz" -type f -mtime +${RETENTION_DAYS} -print0 2>/dev/null)

    if [ $count -gt 0 ]; then
        log_success "Supprime ${count} ancien(s) backup(s)"
    else
        log_info "Aucun ancien backup a supprimer"
    fi
}

# Afficher le resume
show_summary() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    RESUME DU BACKUP                           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Backup termine avec succes!${NC}"
    echo ""
    echo "Details:"
    echo "  - Date:     $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  - Fichier:  ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    echo "  - Taille:   $(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)"
    echo ""
    echo "Contenu:"
    echo "  - database.sql (MariaDB)"
    echo "  - volumes/ (Appwrite data)"
    echo ""
    echo -e "${YELLOW}Pour restaurer:${NC}"
    echo "  1. Arreter les services: make down"
    echo "  2. Extraire l'archive: tar -xzf ${BACKUP_NAME}.tar.gz"
    echo "  3. Restaurer la DB: make restore-db BACKUP_FILE=./${BACKUP_NAME}/database.sql"
    echo "  4. Restaurer les volumes manuellement si necessaire"
    echo "  5. Redemarrer: make up"
    echo ""
}

# =============================================================================
# SCRIPT PRINCIPAL
# =============================================================================

main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           FUG Infrastructure - Backup                         ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Repertoire: ${BACKUP_DIR}"
    echo ""

    # Etapes du backup
    check_prerequisites
    create_backup_dir
    backup_database
    backup_all_volumes
    create_archive
    cleanup_old_backups
    show_summary
}

# Gestion des erreurs
trap 'log_error "Backup interrompu!"; exit 1' INT TERM

# Executer le script principal
main "$@"
