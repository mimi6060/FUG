#!/bin/bash
# Bootstrap Appwrite for FUG project
# Creates project, database, and runs all migrations
# Usage: ./bootstrap-appwrite.sh [--env development|production]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/../migrations"
ENV="${1:-development}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✔${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✘${NC} $1"; }
log_step() { echo -e "${CYAN}→${NC} $1"; }

echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  FUG - Appwrite Bootstrap${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo ""

# ============================================
# Configuration
# ============================================

# Default values (can be overridden by environment)
APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-http://localhost:9000/v1}"
PROJECT_NAME="${PROJECT_NAME:-FUG}"
PROJECT_ID="${PROJECT_ID:-fug-$(date +%s)}"
DATABASE_ID="${DATABASE_ID:-fug-db}"
DATABASE_NAME="${DATABASE_NAME:-FUG Database}"

# Check if we have admin credentials
if [ -z "$APPWRITE_ADMIN_EMAIL" ] || [ -z "$APPWRITE_ADMIN_PASSWORD" ]; then
    echo -e "${YELLOW}Appwrite Admin Credentials Required${NC}"
    echo ""
    read -p "Admin Email: " APPWRITE_ADMIN_EMAIL
    read -s -p "Admin Password: " APPWRITE_ADMIN_PASSWORD
    echo ""
fi

log_info "Environment: $ENV"
log_info "Endpoint: $APPWRITE_ENDPOINT"
echo ""

# ============================================
# Step 1: Create Admin Session
# ============================================
log_step "Creating admin session..."

SESSION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/account/sessions/email" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -d "{
        \"email\": \"$APPWRITE_ADMIN_EMAIL\",
        \"password\": \"$APPWRITE_ADMIN_PASSWORD\"
    }")

HTTP_CODE=$(echo "$SESSION_RESPONSE" | tail -n1)
SESSION_BODY=$(echo "$SESSION_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "201" ]; then
    log_error "Failed to create admin session (HTTP $HTTP_CODE)"
    echo "$SESSION_BODY"
    exit 1
fi

# Extract session cookie
SESSION_ID=$(echo "$SESSION_BODY" | grep -o '"secret":"[^"]*"' | cut -d'"' -f4)
log_success "Admin session created"

# ============================================
# Step 2: Create Project
# ============================================
log_step "Creating project: $PROJECT_NAME..."

PROJECT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/projects" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -H "Cookie: a_session_console=$SESSION_ID" \
    -d "{
        \"projectId\": \"$PROJECT_ID\",
        \"name\": \"$PROJECT_NAME\",
        \"teamId\": \"unique()\",
        \"region\": \"default\"
    }")

HTTP_CODE=$(echo "$PROJECT_RESPONSE" | tail -n1)
PROJECT_BODY=$(echo "$PROJECT_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    PROJECT_ID=$(echo "$PROJECT_BODY" | grep -o '"$id":"[^"]*"' | head -1 | cut -d'"' -f4)
    log_success "Project created: $PROJECT_ID"
elif [ "$HTTP_CODE" = "409" ]; then
    log_warn "Project already exists, continuing..."
else
    log_error "Failed to create project (HTTP $HTTP_CODE)"
    echo "$PROJECT_BODY"
    exit 1
fi

# ============================================
# Step 3: Create API Key
# ============================================
log_step "Creating API key..."

APIKEY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/projects/$PROJECT_ID/keys" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -H "Cookie: a_session_console=$SESSION_ID" \
    -d "{
        \"name\": \"FUG Migrations Key\",
        \"scopes\": [
            \"databases.read\",
            \"databases.write\",
            \"collections.read\",
            \"collections.write\",
            \"attributes.read\",
            \"attributes.write\",
            \"indexes.read\",
            \"indexes.write\",
            \"documents.read\",
            \"documents.write\",
            \"users.read\",
            \"users.write\"
        ]
    }")

HTTP_CODE=$(echo "$APIKEY_RESPONSE" | tail -n1)
APIKEY_BODY=$(echo "$APIKEY_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    API_KEY=$(echo "$APIKEY_BODY" | grep -o '"secret":"[^"]*"' | cut -d'"' -f4)
    log_success "API key created"
else
    log_warn "Could not create API key (HTTP $HTTP_CODE), you may need to create one manually"
    API_KEY=""
fi

# ============================================
# Step 4: Create Database
# ============================================
log_step "Creating database: $DATABASE_NAME..."

DB_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/databases" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "Cookie: a_session_console=$SESSION_ID" \
    -d "{
        \"databaseId\": \"$DATABASE_ID\",
        \"name\": \"$DATABASE_NAME\"
    }")

HTTP_CODE=$(echo "$DB_RESPONSE" | tail -n1)
DB_BODY=$(echo "$DB_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    log_success "Database created: $DATABASE_ID"
elif [ "$HTTP_CODE" = "409" ]; then
    log_warn "Database already exists, continuing..."
else
    log_error "Failed to create database (HTTP $HTTP_CODE)"
    echo "$DB_BODY"
    exit 1
fi

# ============================================
# Step 5: Generate .env file for migrations
# ============================================
log_step "Generating migrations .env file..."

ENV_FILE="$MIGRATIONS_DIR/.env"

cat > "$ENV_FILE" << EOF
# FUG Migrations - Environment Configuration
# Generated by bootstrap-appwrite.sh on $(date)

# Appwrite Configuration
APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID=$PROJECT_ID
APPWRITE_API_KEY=$API_KEY

# Database
DATABASE_ID=$DATABASE_ID
EOF

log_success "Created $ENV_FILE"

# ============================================
# Step 6: Run Migrations
# ============================================
log_step "Running database migrations..."

cd "$MIGRATIONS_DIR"

if [ -n "$API_KEY" ]; then
    node migrate.js up --env=$ENV
    log_success "Migrations completed"
else
    log_warn "Skipping migrations (no API key). Run manually after creating an API key:"
    echo "    cd $MIGRATIONS_DIR && node migrate.js up --env=$ENV"
fi

# ============================================
# Step 7: Configure OAuth (optional)
# ============================================
if [ -f "$SCRIPT_DIR/.google-credentials" ] || [ -f "$SCRIPT_DIR/.apple-credentials" ]; then
    log_step "Configuring OAuth providers..."
    cd "$SCRIPT_DIR"
    bash configure-oauth.sh
fi

# ============================================
# Summary
# ============================================
echo ""
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Bootstrap Complete!${NC}"
echo -e "${BLUE}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Project Configuration:${NC}"
echo "  Project ID:  $PROJECT_ID"
echo "  Database ID: $DATABASE_ID"
echo "  Endpoint:    $APPWRITE_ENDPOINT"
echo ""
if [ -n "$API_KEY" ]; then
    echo -e "${CYAN}API Key:${NC}"
    echo "  $API_KEY"
    echo ""
    log_warn "Save this API key securely - it won't be shown again!"
fi
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Update app/lib/core/config/appwrite_config.dart with the project ID"
echo "  2. Configure OAuth providers (see setup/*.md docs)"
echo "  3. Run the Flutter app: cd app && flutter run"
echo ""
