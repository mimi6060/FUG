#!/bin/bash
# ============================================================================
# FUG - Appwrite Bootstrap Script
# ============================================================================
#
# Automated setup for fresh Appwrite installations.
# Creates project, admin user, database, and runs all migrations.
#
# Usage: ./bootstrap.sh [--env development|staging|production]
#
# The admin password is generated randomly and displayed ONCE at the end.
# SAVE IT SECURELY - it will not be shown again!
#
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/../migrations"

# Parse arguments
ENV="development"
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENV="$2"
            shift 2
            ;;
        --env=*)
            ENV="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ============================================================================
# Configuration
# ============================================================================

# Admin account - email is fixed, password is generated
ADMIN_EMAIL="fous.toi.une.guinze@gmail.com"

# Project configuration (can be overridden by environment)
PROJECT_NAME="${PROJECT_NAME:-FUG}"
PROJECT_ID="${PROJECT_ID:-fug}"
DATABASE_ID="${DATABASE_ID:-fug-db}"
DATABASE_NAME="${DATABASE_NAME:-FUG Database}"

# Appwrite endpoint based on environment
case $ENV in
    development)
        APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-http://localhost:9000/v1}"
        ;;
    staging)
        APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-https://staging.fug-app.com/v1}"
        ;;
    production)
        APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-https://api.fug-app.com/v1}"
        ;;
    *)
        echo "Unknown environment: $ENV"
        exit 1
        ;;
esac

# ============================================================================
# Colors and logging
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# ============================================================================
# Password Generation
# ============================================================================

generate_secure_password() {
    # Generate 24-character secure password
    # Using /dev/urandom for cryptographic randomness
    local charset='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*'
    local password=""
    local length=24

    for i in $(seq 1 $length); do
        local random_byte=$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')
        local index=$((random_byte % ${#charset}))
        password="${password}${charset:$index:1}"
    done

    echo "$password"
}

# ============================================================================
# Main Script
# ============================================================================

echo ""
echo -e "${BLUE}${BOLD}======================================================${NC}"
echo -e "${BLUE}${BOLD}  FUG - Appwrite Bootstrap${NC}"
echo -e "${BLUE}${BOLD}======================================================${NC}"
echo ""
echo -e "${CYAN}Environment:${NC} $ENV"
echo -e "${CYAN}Endpoint:${NC}    $APPWRITE_ENDPOINT"
echo -e "${CYAN}Project ID:${NC}  $PROJECT_ID"
echo ""

# ============================================================================
# Step 1: Check Appwrite is running
# ============================================================================

log_step "Checking Appwrite health..."

HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$APPWRITE_ENDPOINT/health" 2>/dev/null || echo "000")

if [ "$HEALTH_RESPONSE" = "000" ]; then
    log_error "Cannot connect to Appwrite at $APPWRITE_ENDPOINT"
    log_info "Make sure Appwrite is running: cd infrastructure && docker-compose up -d"
    exit 1
fi

log_success "Appwrite is running"

# ============================================================================
# Step 2: Check if project already exists
# ============================================================================

log_step "Checking if project exists..."

# Try to access the project endpoint
PROJECT_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
    "$APPWRITE_ENDPOINT/databases" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "Content-Type: application/json" 2>/dev/null || echo "000")

if [ "$PROJECT_CHECK" = "401" ] || [ "$PROJECT_CHECK" = "200" ]; then
    log_warn "Project '$PROJECT_ID' may already exist"
    echo ""
    echo -e "${YELLOW}If the project exists, you can run migrations directly:${NC}"
    echo "  cd infrastructure/migrations && node migrate.js up --env=$ENV"
    echo ""
    read -p "Continue with bootstrap anyway? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        log_info "Aborted."
        exit 0
    fi
fi

# ============================================================================
# Step 3: Generate admin password
# ============================================================================

log_step "Generating secure admin password..."

ADMIN_PASSWORD=$(generate_secure_password)

log_success "Password generated (will be shown at the end)"

# ============================================================================
# Step 4: Check for existing admin or create session
# ============================================================================

log_step "Setting up admin account..."

# Try to create a new account first
ACCOUNT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/account" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -d "{
        \"userId\": \"unique()\",
        \"email\": \"$ADMIN_EMAIL\",
        \"password\": \"$ADMIN_PASSWORD\",
        \"name\": \"FUG Admin\"
    }" 2>/dev/null)

HTTP_CODE=$(echo "$ACCOUNT_RESPONSE" | tail -n1)
ACCOUNT_BODY=$(echo "$ACCOUNT_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    log_success "Admin account created: $ADMIN_EMAIL"
    ACCOUNT_CREATED=true
elif [ "$HTTP_CODE" = "409" ]; then
    log_warn "Admin account already exists"
    echo ""
    echo -e "${YELLOW}The admin account already exists. Enter the existing password to continue:${NC}"
    read -s -p "Existing admin password: " EXISTING_PASSWORD
    echo ""
    ADMIN_PASSWORD="$EXISTING_PASSWORD"
    ACCOUNT_CREATED=false
else
    log_error "Failed to create admin account (HTTP $HTTP_CODE)"
    echo "$ACCOUNT_BODY" | head -5
    exit 1
fi

# Create session with admin credentials
log_step "Creating admin session..."

SESSION_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/account/sessions/email" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -d "{
        \"email\": \"$ADMIN_EMAIL\",
        \"password\": \"$ADMIN_PASSWORD\"
    }" 2>/dev/null)

HTTP_CODE=$(echo "$SESSION_RESPONSE" | tail -n1)
SESSION_BODY=$(echo "$SESSION_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "201" ]; then
    log_error "Failed to create admin session (HTTP $HTTP_CODE)"
    echo "$SESSION_BODY" | head -5
    exit 1
fi

# Extract session secret
SESSION_SECRET=$(echo "$SESSION_BODY" | grep -o '"secret":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$SESSION_SECRET" ]; then
    log_error "Could not extract session secret"
    exit 1
fi

log_success "Admin session created"

# ============================================================================
# Step 5: Create project
# ============================================================================

log_step "Creating project: $PROJECT_NAME..."

PROJECT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/projects" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -H "Cookie: a_session_console=$SESSION_SECRET" \
    -d "{
        \"projectId\": \"$PROJECT_ID\",
        \"name\": \"$PROJECT_NAME\",
        \"teamId\": \"unique()\",
        \"region\": \"default\"
    }" 2>/dev/null)

HTTP_CODE=$(echo "$PROJECT_RESPONSE" | tail -n1)
PROJECT_BODY=$(echo "$PROJECT_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    log_success "Project created: $PROJECT_ID"
elif [ "$HTTP_CODE" = "409" ]; then
    log_warn "Project already exists, continuing..."
else
    log_error "Failed to create project (HTTP $HTTP_CODE)"
    echo "$PROJECT_BODY" | head -5
    exit 1
fi

# ============================================================================
# Step 6: Create API key for migrations
# ============================================================================

log_step "Creating API key for migrations..."

APIKEY_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/projects/$PROJECT_ID/keys" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: console" \
    -H "Cookie: a_session_console=$SESSION_SECRET" \
    -d "{
        \"name\": \"FUG Migrations Key - $(date +%Y%m%d)\",
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
            \"users.write\",
            \"buckets.read\",
            \"buckets.write\",
            \"files.read\",
            \"files.write\"
        ]
    }" 2>/dev/null)

HTTP_CODE=$(echo "$APIKEY_RESPONSE" | tail -n1)
APIKEY_BODY=$(echo "$APIKEY_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    API_KEY=$(echo "$APIKEY_BODY" | grep -o '"secret":"[^"]*"' | cut -d'"' -f4)
    log_success "API key created"
else
    log_warn "Could not create API key (HTTP $HTTP_CODE)"
    log_info "You may need to create one manually in the Appwrite console"
    API_KEY=""
fi

# ============================================================================
# Step 7: Create database
# ============================================================================

log_step "Creating database: $DATABASE_NAME..."

DB_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$APPWRITE_ENDPOINT/databases" \
    -H "Content-Type: application/json" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "X-Appwrite-Key: $API_KEY" \
    -d "{
        \"databaseId\": \"$DATABASE_ID\",
        \"name\": \"$DATABASE_NAME\"
    }" 2>/dev/null)

HTTP_CODE=$(echo "$DB_RESPONSE" | tail -n1)
DB_BODY=$(echo "$DB_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    log_success "Database created: $DATABASE_ID"
elif [ "$HTTP_CODE" = "409" ]; then
    log_warn "Database already exists, continuing..."
else
    log_error "Failed to create database (HTTP $HTTP_CODE)"
    echo "$DB_BODY" | head -5
    exit 1
fi

# ============================================================================
# Step 8: Generate .env file for migrations
# ============================================================================

log_step "Generating migrations .env file..."

ENV_FILE="$MIGRATIONS_DIR/.env"

cat > "$ENV_FILE" << EOF
# FUG Migrations - Environment Configuration
# Generated by bootstrap.sh on $(date)
# Environment: $ENV

# Appwrite Configuration
APPWRITE_ENDPOINT=$APPWRITE_ENDPOINT
APPWRITE_PROJECT_ID=$PROJECT_ID
APPWRITE_API_KEY=$API_KEY

# Database
DATABASE_ID=$DATABASE_ID
EOF

log_success "Created $ENV_FILE"

# ============================================================================
# Step 9: Run migrations
# ============================================================================

log_step "Running database migrations..."

if [ -n "$API_KEY" ]; then
    cd "$MIGRATIONS_DIR"

    if node migrate.js up --env="$ENV"; then
        log_success "Migrations completed"
    else
        log_error "Some migrations failed"
    fi

    cd "$SCRIPT_DIR"
else
    log_warn "Skipping migrations (no API key)"
    echo "  Run manually: cd $MIGRATIONS_DIR && node migrate.js up --env=$ENV"
fi

# ============================================================================
# Step 10: Configure OAuth (if credentials provided)
# ============================================================================

if [ -n "$GOOGLE_CLIENT_ID" ] || [ -n "$APPLE_CLIENT_ID" ]; then
    log_step "OAuth credentials detected, configuring providers..."
    # OAuth is now configured via migration 014_oauth_providers
    log_info "OAuth providers will be configured by migrations"
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}  Bootstrap Complete!${NC}"
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo ""
echo -e "${CYAN}Project Configuration:${NC}"
echo "  Project ID:   $PROJECT_ID"
echo "  Database ID:  $DATABASE_ID"
echo "  Endpoint:     $APPWRITE_ENDPOINT"
echo "  Environment:  $ENV"
echo ""
echo -e "${CYAN}Admin Account:${NC}"
echo "  Email:        $ADMIN_EMAIL"

if [ "$ACCOUNT_CREATED" = true ]; then
    echo ""
    echo -e "${YELLOW}${BOLD}======================================================${NC}"
    echo -e "${YELLOW}${BOLD}  ADMIN PASSWORD (SAVE THIS NOW!)${NC}"
    echo -e "${YELLOW}${BOLD}======================================================${NC}"
    echo ""
    echo -e "  ${BOLD}$ADMIN_PASSWORD${NC}"
    echo ""
    echo -e "${RED}${BOLD}  WARNING: This password will NOT be shown again!${NC}"
    echo -e "${RED}${BOLD}  Save it in a secure password manager immediately!${NC}"
    echo -e "${YELLOW}${BOLD}======================================================${NC}"
fi

echo ""
echo -e "${CYAN}API Key:${NC}"
if [ -n "$API_KEY" ]; then
    echo "  Saved to: $ENV_FILE"
else
    echo "  Not created - create manually in Appwrite console"
fi

echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo "  1. Save the admin password securely"
echo "  2. Update app/lib/core/config/appwrite_config.dart with project ID"
echo "  3. Configure OAuth providers (see setup/*.md docs)"
echo "  4. Run the Flutter app: cd app && flutter run"
echo ""
