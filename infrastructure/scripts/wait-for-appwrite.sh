#!/bin/bash
# =============================================================================
# FUG Project - Wait for Appwrite Script
# =============================================================================
# Ce script attend que Appwrite soit completement operationnel
# en verifiant le health check endpoint /v1/health
# =============================================================================

set -e

# Configuration
APPWRITE_HOST="${APPWRITE_HOST:-localhost}"
APPWRITE_PORT="${APPWRITE_PORT:-80}"
MAX_RETRIES="${MAX_RETRIES:-60}"
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"
HEALTH_ENDPOINT="/v1/health"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL de sante
HEALTH_URL="http://${APPWRITE_HOST}:${APPWRITE_PORT}${HEALTH_ENDPOINT}"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Attente du demarrage d'Appwrite                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  - Host:     ${APPWRITE_HOST}"
echo "  - Port:     ${APPWRITE_PORT}"
echo "  - Endpoint: ${HEALTH_ENDPOINT}"
echo "  - Timeout:  $((MAX_RETRIES * RETRY_INTERVAL)) secondes"
echo ""

# Fonction pour verifier la sante
check_health() {
    local response
    local http_code

    # Effectuer la requete et capturer le code HTTP
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "${HEALTH_URL}" 2>/dev/null)

    if [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour verifier la sante complete
check_full_health() {
    local response

    response=$(curl -s "${HEALTH_URL}" 2>/dev/null)

    if [ -z "$response" ]; then
        return 1
    fi

    # Verifier que la reponse contient les indicateurs de sante
    if echo "$response" | grep -q '"status"'; then
        return 0
    else
        return 1
    fi
}

# Fonction pour afficher la progression
show_progress() {
    local current=$1
    local max=$2
    local percent=$((current * 100 / max))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %3d%% (%d/%d)" "$percent" "$current" "$max"
}

# Boucle principale d'attente
echo -e "${YELLOW}>>> Verification de la disponibilite d'Appwrite...${NC}"
echo ""

retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    if check_health; then
        echo ""
        echo ""
        echo -e "${GREEN}>>> Appwrite est operationnel!${NC}"
        echo ""

        # Verification complete de la sante
        echo -e "${BLUE}>>> Verification complete de la sante...${NC}"

        if check_full_health; then
            echo -e "${GREEN}>>> Tous les services sont prets!${NC}"

            # Afficher les details de sante
            echo ""
            echo -e "${BLUE}Statut de sante:${NC}"
            curl -s "${HEALTH_URL}" 2>/dev/null | python3 -m json.tool 2>/dev/null || \
                curl -s "${HEALTH_URL}" 2>/dev/null
            echo ""

            exit 0
        else
            echo -e "${YELLOW}>>> Appwrite repond mais certains services peuvent ne pas etre prets.${NC}"
            exit 0
        fi
    fi

    retry_count=$((retry_count + 1))
    show_progress $retry_count $MAX_RETRIES

    sleep $RETRY_INTERVAL
done

echo ""
echo ""
echo -e "${RED}>>> ERREUR: Appwrite n'a pas demarre dans le temps imparti!${NC}"
echo ""
echo -e "${YELLOW}Conseils de depannage:${NC}"
echo "  1. Verifiez que Docker est en cours d'execution"
echo "  2. Verifiez les logs: docker compose logs appwrite"
echo "  3. Verifiez les logs MariaDB: docker compose logs mariadb"
echo "  4. Verifiez les logs Redis: docker compose logs redis"
echo "  5. Augmentez MAX_RETRIES si necessaire"
echo ""
echo -e "${YELLOW}Commandes utiles:${NC}"
echo "  - docker compose ps"
echo "  - docker compose logs -f"
echo "  - make status"
echo ""

exit 1
