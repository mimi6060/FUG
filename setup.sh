#!/bin/bash

# =============================================================================
# FUG Project - Setup Script
# =============================================================================
# Script de setup complet du projet FUG
# Usage: ./setup.sh [dev|test|prod]
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-dev}

# Project directories
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$PROJECT_ROOT/infrastructure"
APP_DIR="$PROJECT_ROOT/app"
FUNCTIONS_DIR="$PROJECT_ROOT/functions"
MIGRATIONS_DIR="$INFRA_DIR/migrations"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${PURPLE}=============================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}=============================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is not installed"
        return 1
    fi
}

check_version() {
    local cmd=$1
    local min_version=$2
    local current_version=$3

    if [ "$(printf '%s\n' "$min_version" "$current_version" | sort -V | head -n1)" = "$min_version" ]; then
        print_success "$cmd version $current_version (>= $min_version)"
        return 0
    else
        print_error "$cmd version $current_version is below minimum $min_version"
        return 1
    fi
}

# =============================================================================
# Prerequisites Check
# =============================================================================

check_prerequisites() {
    print_header "Checking Prerequisites"

    local all_ok=true

    # Docker
    print_step "Checking Docker..."
    if check_command docker; then
        docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        check_version "Docker" "24.0.0" "$docker_version" || all_ok=false
    else
        all_ok=false
    fi

    # Docker Compose
    print_step "Checking Docker Compose..."
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        check_version "Docker Compose" "2.20.0" "$compose_version" || all_ok=false
    else
        print_error "Docker Compose is not installed"
        all_ok=false
    fi

    # Node.js
    print_step "Checking Node.js..."
    if check_command node; then
        node_version=$(node --version | sed 's/v//')
        check_version "Node.js" "18.0.0" "$node_version" || all_ok=false
    else
        all_ok=false
    fi

    # npm
    print_step "Checking npm..."
    if check_command npm; then
        npm_version=$(npm --version)
        check_version "npm" "9.0.0" "$npm_version" || all_ok=false
    else
        all_ok=false
    fi

    # Flutter
    print_step "Checking Flutter..."
    if check_command flutter; then
        flutter_version=$(flutter --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        check_version "Flutter" "3.16.0" "$flutter_version" || all_ok=false
    else
        all_ok=false
    fi

    # Git
    print_step "Checking Git..."
    if check_command git; then
        git_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        check_version "Git" "2.40.0" "$git_version" || all_ok=false
    else
        all_ok=false
    fi

    if [ "$all_ok" = false ]; then
        print_error "Some prerequisites are missing or outdated. Please install them before continuing."
        exit 1
    fi

    print_success "All prerequisites are met!"
}

# =============================================================================
# Git Submodules
# =============================================================================

setup_submodules() {
    print_header "Setting up Git Submodules"

    cd "$PROJECT_ROOT"

    if [ -f ".gitmodules" ]; then
        print_step "Initializing submodules..."
        git submodule init

        print_step "Updating submodules..."
        git submodule update --recursive

        print_success "Submodules configured"
    else
        print_info "No submodules found"
    fi
}

# =============================================================================
# Environment Configuration
# =============================================================================

setup_environment() {
    print_header "Configuring Environment: $ENVIRONMENT"

    # Infrastructure .env
    if [ ! -f "$INFRA_DIR/.env" ]; then
        print_step "Creating infrastructure .env file..."
        cp "$INFRA_DIR/.env.example" "$INFRA_DIR/.env"

        # Customize based on environment
        case $ENVIRONMENT in
            dev)
                print_info "Configuring for development..."
                sed -i.bak 's/NODE_ENV=.*/NODE_ENV=development/' "$INFRA_DIR/.env" 2>/dev/null || \
                sed -i '' 's/NODE_ENV=.*/NODE_ENV=development/' "$INFRA_DIR/.env"
                ;;
            test)
                print_info "Configuring for testing..."
                sed -i.bak 's/NODE_ENV=.*/NODE_ENV=test/' "$INFRA_DIR/.env" 2>/dev/null || \
                sed -i '' 's/NODE_ENV=.*/NODE_ENV=test/' "$INFRA_DIR/.env"
                ;;
            prod)
                print_info "Configuring for production..."
                sed -i.bak 's/NODE_ENV=.*/NODE_ENV=production/' "$INFRA_DIR/.env" 2>/dev/null || \
                sed -i '' 's/NODE_ENV=.*/NODE_ENV=production/' "$INFRA_DIR/.env"
                print_warning "Remember to update production secrets in .env!"
                ;;
        esac

        rm -f "$INFRA_DIR/.env.bak"
        print_success "Infrastructure .env created"
    else
        print_info "Infrastructure .env already exists"
    fi

    # Migrations .env
    if [ ! -f "$MIGRATIONS_DIR/.env" ]; then
        print_step "Creating migrations .env file..."
        if [ -f "$MIGRATIONS_DIR/.env.example" ]; then
            cp "$MIGRATIONS_DIR/.env.example" "$MIGRATIONS_DIR/.env"
            print_success "Migrations .env created"
        fi
    else
        print_info "Migrations .env already exists"
    fi

    # Scripts .env
    if [ ! -f "$INFRA_DIR/scripts/.env" ]; then
        print_step "Creating scripts .env file..."
        if [ -f "$INFRA_DIR/scripts/.env.example" ]; then
            cp "$INFRA_DIR/scripts/.env.example" "$INFRA_DIR/scripts/.env"
            print_success "Scripts .env created"
        fi
    else
        print_info "Scripts .env already exists"
    fi
}

# =============================================================================
# Docker Setup
# =============================================================================

start_docker() {
    print_header "Starting Docker Services"

    cd "$INFRA_DIR"

    print_step "Pulling Docker images..."
    docker compose pull

    print_step "Starting containers..."
    if [ "$ENVIRONMENT" = "dev" ]; then
        # Start with override for development
        if [ -f "docker-compose.override.yml" ]; then
            docker compose -f docker-compose.yml -f docker-compose.override.yml up -d
        else
            docker compose up -d
        fi
    else
        docker compose up -d
    fi

    print_success "Docker containers started"

    # Show running containers
    print_info "Running containers:"
    docker compose ps
}

# =============================================================================
# Wait for Appwrite
# =============================================================================

wait_for_appwrite() {
    print_header "Waiting for Appwrite"

    cd "$INFRA_DIR"

    if [ -f "scripts/wait-for-appwrite.sh" ]; then
        print_step "Executing wait script..."
        chmod +x scripts/wait-for-appwrite.sh
        ./scripts/wait-for-appwrite.sh
    else
        print_step "Waiting for Appwrite to be ready..."

        local max_attempts=60
        local attempt=1

        while [ $attempt -le $max_attempts ]; do
            if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/v1/health 2>/dev/null | grep -q "200"; then
                print_success "Appwrite is ready!"
                return 0
            fi

            echo -ne "\r${YELLOW}Waiting... ($attempt/$max_attempts)${NC}"
            sleep 5
            ((attempt++))
        done

        echo ""
        print_error "Appwrite did not become ready in time"
        return 1
    fi
}

# =============================================================================
# Database Migrations
# =============================================================================

run_migrations() {
    print_header "Running Database Migrations"

    cd "$MIGRATIONS_DIR"

    print_step "Installing migration dependencies..."
    npm install

    print_step "Running migrations for $ENVIRONMENT..."
    case $ENVIRONMENT in
        dev)
            npm run migrate:dev
            ;;
        test)
            npm run migrate:test
            ;;
        prod)
            npm run migrate:prod
            ;;
    esac

    print_success "Migrations completed"
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_dependencies() {
    print_header "Installing Dependencies"

    # Infrastructure scripts
    print_step "Installing infrastructure scripts dependencies..."
    cd "$INFRA_DIR/scripts"
    npm install
    print_success "Infrastructure scripts dependencies installed"

    # Functions
    print_step "Installing functions dependencies..."
    for func_dir in "$FUNCTIONS_DIR"/*/; do
        if [ -f "$func_dir/package.json" ]; then
            func_name=$(basename "$func_dir")
            print_info "Installing $func_name..."
            cd "$func_dir"
            npm install
        fi
    done
    print_success "Functions dependencies installed"

    # Flutter app
    print_step "Installing Flutter dependencies..."
    cd "$APP_DIR"
    flutter pub get
    print_success "Flutter dependencies installed"

    # Generate Dart files
    print_step "Generating Dart files..."
    flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true
    print_success "Dart files generated"
}

# =============================================================================
# Display URLs
# =============================================================================

display_urls() {
    print_header "Service URLs"

    echo -e "${CYAN}Appwrite Console:${NC}    http://localhost:8080"
    echo -e "${CYAN}Appwrite API:${NC}        http://localhost:8080/v1"
    echo -e "${CYAN}Grafana:${NC}             http://localhost:3001"
    echo -e "${CYAN}InfluxDB:${NC}            http://localhost:8086"
    echo ""

    if [ "$ENVIRONMENT" = "dev" ]; then
        echo -e "${YELLOW}Development Tips:${NC}"
        echo "  - Run 'flutter run' in the app/ directory to start the mobile app"
        echo "  - Run 'docker compose logs -f' in infrastructure/ to see logs"
        echo "  - Access Appwrite Console to manage your project"
        echo ""
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    print_header "FUG Project Setup - Environment: $ENVIRONMENT"

    echo -e "${CYAN}Project Root:${NC} $PROJECT_ROOT"
    echo ""

    # Validate environment
    case $ENVIRONMENT in
        dev|test|prod)
            print_info "Setting up for $ENVIRONMENT environment"
            ;;
        *)
            print_error "Invalid environment: $ENVIRONMENT"
            echo "Usage: $0 [dev|test|prod]"
            exit 1
            ;;
    esac

    # Run setup steps
    check_prerequisites
    setup_submodules
    setup_environment
    install_dependencies
    start_docker
    wait_for_appwrite
    run_migrations
    display_urls

    print_header "Setup Complete!"

    echo -e "${GREEN}FUG project is ready for $ENVIRONMENT!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review and update .env files with your configuration"
    echo "  2. Access Appwrite Console at http://localhost:8080"
    echo "  3. Run 'cd app && flutter run' to start the mobile app"
    echo ""
}

# Run main function
main
