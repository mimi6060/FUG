#!/bin/bash
# Configure OAuth providers in Appwrite
# Usage: ./configure-oauth.sh [--env development|production]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV="${1:-development}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✔${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✘${NC} $1"; }

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FUG - OAuth Provider Configuration${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo ""

# Load environment
if [ -f "$SCRIPT_DIR/../migrations/.env" ]; then
    source "$SCRIPT_DIR/../migrations/.env"
    log_info "Loaded environment from migrations/.env"
elif [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
    log_info "Loaded environment from .env"
else
    log_error "No .env file found"
    exit 1
fi

# Verify required variables
if [ -z "$APPWRITE_ENDPOINT" ] || [ -z "$APPWRITE_PROJECT_ID" ] || [ -z "$APPWRITE_API_KEY" ]; then
    log_error "Missing required environment variables"
    echo "Required: APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY"
    exit 1
fi

log_info "Endpoint: $APPWRITE_ENDPOINT"
log_info "Project:  $APPWRITE_PROJECT_ID"
echo ""

# Function to configure an OAuth provider
configure_provider() {
    local provider=$1
    local app_id=$2
    local secret=$3
    local enabled=${4:-true}

    log_info "Configuring $provider..."

    response=$(curl -s -w "\n%{http_code}" -X PATCH \
        "$APPWRITE_ENDPOINT/projects/$APPWRITE_PROJECT_ID/oauth2" \
        -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
        -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"provider\": \"$provider\",
            \"appId\": \"$app_id\",
            \"secret\": \"$secret\",
            \"enabled\": $enabled
        }")

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "200" ]; then
        log_success "$provider configured successfully"
        return 0
    else
        log_error "Failed to configure $provider (HTTP $http_code)"
        echo "$body" | head -5
        return 1
    fi
}

# ============================================
# Google OAuth Configuration
# ============================================
echo -e "\n${YELLOW}── Google OAuth ──${NC}"

if [ -f "$SCRIPT_DIR/.google-credentials" ]; then
    source "$SCRIPT_DIR/.google-credentials"

    if [ -n "$GOOGLE_CLIENT_ID" ] && [ -n "$GOOGLE_CLIENT_SECRET" ]; then
        configure_provider "google" "$GOOGLE_CLIENT_ID" "$GOOGLE_CLIENT_SECRET"
    else
        log_warn "Google credentials incomplete, skipping"
    fi
else
    log_warn "No .google-credentials file found"
    log_info "Create it with:"
    echo "    cat > $SCRIPT_DIR/.google-credentials << 'EOF'"
    echo "    GOOGLE_CLIENT_ID=your_client_id"
    echo "    GOOGLE_CLIENT_SECRET=your_secret"
    echo "    EOF"
fi

# ============================================
# Apple OAuth Configuration
# ============================================
echo -e "\n${YELLOW}── Apple OAuth ──${NC}"

if [ -f "$SCRIPT_DIR/.apple-credentials" ]; then
    source "$SCRIPT_DIR/.apple-credentials"

    if [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_KEY_ID" ] && [ -n "$APPLE_SERVICE_ID" ] && [ -n "$APPLE_PRIVATE_KEY" ]; then
        # Apple requires a composite secret: teamId:keyId:privateKey
        # The appId is the Services ID (not the App ID)

        # Encode private key for JSON
        ENCODED_KEY=$(echo "$APPLE_PRIVATE_KEY" | sed 's/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

        # Apple secret format for Appwrite
        APPLE_SECRET="${APPLE_TEAM_ID}:${APPLE_KEY_ID}:${ENCODED_KEY}"

        configure_provider "apple" "$APPLE_SERVICE_ID" "$APPLE_SECRET"
    else
        log_warn "Apple credentials incomplete, skipping"
        log_info "Required: APPLE_TEAM_ID, APPLE_KEY_ID, APPLE_SERVICE_ID, APPLE_PRIVATE_KEY"
    fi
else
    log_warn "No .apple-credentials file found"
    log_info "See APPLE_SIGNIN_SETUP.md for instructions"
fi

# ============================================
# Summary
# ============================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Configuration Complete${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo ""
log_info "To verify, check Appwrite Console → Auth → Settings → OAuth2 Providers"
echo ""
