# =============================================================================
# FUG Project - Infrastructure Makefile
# =============================================================================
# Commandes pour gerer l'infrastructure Docker Appwrite + Flutter App
# Usage: make <target>
# =============================================================================

# Configuration
COMPOSE_FILE := docker-compose.yml
COMPOSE_OVERRIDE := docker-compose.override.yml
COMPOSE_FULL := docker-compose.full.yml
COMPOSE := docker compose
PROJECT_NAME := fug

# Couleurs pour les messages
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
MAGENTA := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# =============================================================================
# CIBLES PRINCIPALES
# =============================================================================
.PHONY: help up down logs init setup clean backup restart status ps shell \
        up-prod up-monitoring pull build health env check-env \
        db-shell redis-cli backup-db restore-db prune \
        app-build app-dev app-prod app-logs app-shell app-stop \
        functions-build functions-dev functions-test functions-logs \
        all all-dev all-prod full

# Cible par defaut
.DEFAULT_GOAL := help

## help: Afficher cette aide
help:
	@echo ""
	@echo "$(BLUE)╔═══════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║           FUG Infrastructure - Commandes Disponibles                  ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)=== STACK COMPLETE ===$(NC)"
	@echo "  make all             Demarrer TOUT (Appwrite + App dev)"
	@echo "  make all-dev         Demarrer tout en mode developpement"
	@echo "  make all-prod        Demarrer tout en mode production"
	@echo "  make full            Demarrer la stack complete (docker-compose.full.yml)"
	@echo ""
	@echo "$(GREEN)=== APPWRITE (Backend) ===$(NC)"
	@echo "  make up              Demarrer Appwrite (dev)"
	@echo "  make up-prod         Demarrer Appwrite (production)"
	@echo "  make up-monitoring   Demarrer avec monitoring (InfluxDB + Telegraf)"
	@echo "  make down            Arreter tous les services"
	@echo "  make restart         Redemarrer tous les services"
	@echo ""
	@echo "$(MAGENTA)=== FLUTTER APP ===$(NC)"
	@echo "  make app-build       Build l'image Docker Flutter (production)"
	@echo "  make app-dev         Demarrer l'app Flutter en mode dev (hot reload)"
	@echo "  make app-prod        Demarrer l'app Flutter en production"
	@echo "  make app-logs        Voir les logs de l'app Flutter"
	@echo "  make app-shell       Ouvrir un shell dans le container Flutter"
	@echo "  make app-stop        Arreter uniquement l'app Flutter"
	@echo ""
	@echo "$(YELLOW)=== FUNCTIONS (Serverless) ===$(NC)"
	@echo "  make functions-build Build l'image Docker des functions"
	@echo "  make functions-dev   Demarrer l'env de dev des functions"
	@echo "  make functions-test  Executer les tests des functions"
	@echo "  make functions-logs  Voir les logs des functions"
	@echo ""
	@echo "$(GREEN)=== INITIALISATION ===$(NC)"
	@echo "  make init            Initialisation complete (up + wait + setup)"
	@echo "  make setup           Configurer Appwrite (base de donnees, etc.)"
	@echo "  make env             Creer le fichier .env depuis .env.example"
	@echo "  make check-env       Verifier la configuration .env"
	@echo ""
	@echo "$(GREEN)=== MONITORING & DEBUG ===$(NC)"
	@echo "  make status          Afficher le statut des containers"
	@echo "  make ps              Alias pour status"
	@echo "  make logs            Afficher les logs en temps reel"
	@echo "  make logs-appwrite   Logs Appwrite uniquement"
	@echo "  make logs-db         Logs MariaDB uniquement"
	@echo "  make health          Verifier la sante des services"
	@echo ""
	@echo "$(GREEN)=== ACCES AUX SERVICES ===$(NC)"
	@echo "  make shell           Ouvrir un shell dans le container Appwrite"
	@echo "  make db-shell        Ouvrir un shell MySQL dans MariaDB"
	@echo "  make redis-cli       Ouvrir le CLI Redis"
	@echo ""
	@echo "$(GREEN)=== BACKUP & MAINTENANCE ===$(NC)"
	@echo "  make backup          Sauvegarder la base de donnees et volumes"
	@echo "  make backup-db       Sauvegarder uniquement la base de donnees"
	@echo "  make restore-db      Restaurer la base de donnees"
	@echo "  make clean           Arreter et supprimer volumes (DANGER)"
	@echo "  make prune           Nettoyer les ressources Docker inutilisees"
	@echo "  make pull            Mettre a jour les images Docker"
	@echo ""
	@echo "$(CYAN)=== URLs de developpement ===$(NC)"
	@echo "  - Appwrite Console:   http://localhost"
	@echo "  - Appwrite API:       http://localhost/v1"
	@echo "  - Flutter App (dev):  http://localhost:8080"
	@echo "  - Flutter App (prod): http://app.localhost"
	@echo "  - Traefik Dashboard:  http://localhost:8080"
	@echo "  - Adminer (DB):       http://localhost:8081"
	@echo "  - Redis Commander:    http://localhost:8082"
	@echo "  - Mailhog (emails):   http://localhost:8025"
	@echo ""

# =============================================================================
# DEMARRAGE & ARRET
# =============================================================================

## up: Demarrer tous les services en mode dev
up: check-env
	@echo "$(GREEN)>>> Demarrage des services FUG...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)>>> Services demarres avec succes!$(NC)"
	@make status

## up-prod: Demarrer en mode production (sans override)
up-prod: check-env
	@echo "$(GREEN)>>> Demarrage en mode PRODUCTION...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)>>> Services demarres en production!$(NC)"
	@make status

## up-monitoring: Demarrer avec le stack de monitoring
up-monitoring: check-env
	@echo "$(GREEN)>>> Demarrage avec monitoring...$(NC)"
	@$(COMPOSE) --profile monitoring up -d
	@echo "$(GREEN)>>> Services + Monitoring demarres!$(NC)"
	@make status

## down: Arreter tous les services
down:
	@echo "$(YELLOW)>>> Arret des services FUG...$(NC)"
	@$(COMPOSE) down
	@echo "$(GREEN)>>> Services arretes.$(NC)"

## restart: Redemarrer tous les services
restart:
	@echo "$(YELLOW)>>> Redemarrage des services FUG...$(NC)"
	@$(COMPOSE) restart
	@echo "$(GREEN)>>> Services redemarres!$(NC)"
	@make status

# =============================================================================
# INITIALISATION
# =============================================================================

## init: Initialisation complete du projet
init: env up
	@echo "$(BLUE)>>> Attente du demarrage d'Appwrite...$(NC)"
	@sleep 10
	@./scripts/wait-for-appwrite.sh
	@echo "$(GREEN)>>> Appwrite est pret!$(NC)"
	@echo ""
	@echo "$(BLUE)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    INITIALISATION TERMINEE                    ║$(NC)"
	@echo "$(BLUE)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)Appwrite est accessible sur:$(NC)"
	@echo "  - Console:  http://localhost"
	@echo "  - API:      http://localhost/v1"
	@echo ""
	@echo "$(YELLOW)Prochaines etapes:$(NC)"
	@echo "  1. Ouvrez http://localhost dans votre navigateur"
	@echo "  2. Creez votre compte administrateur"
	@echo "  3. Configurez votre premier projet"
	@echo ""

## setup: Configurer Appwrite via scripts
setup:
	@echo "$(BLUE)>>> Configuration d'Appwrite...$(NC)"
	@if [ -d "scripts" ] && [ -f "scripts/package.json" ]; then \
		npm --prefix scripts install; \
		npm --prefix scripts run setup; \
	else \
		echo "$(YELLOW)>>> Scripts de setup non trouves. Configuration manuelle requise.$(NC)"; \
	fi

## env: Creer le fichier .env depuis .env.example
env:
	@if [ ! -f .env ]; then \
		echo "$(BLUE)>>> Creation du fichier .env...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN)>>> Fichier .env cree. Pensez a modifier les valeurs!$(NC)"; \
	else \
		echo "$(YELLOW)>>> Le fichier .env existe deja.$(NC)"; \
	fi

## check-env: Verifier que le fichier .env existe et est configure
check-env:
	@if [ ! -f .env ]; then \
		echo "$(RED)>>> ERREUR: Fichier .env manquant!$(NC)"; \
		echo "$(YELLOW)>>> Executez 'make env' pour le creer.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)>>> Configuration .env OK$(NC)"

# =============================================================================
# MONITORING & DEBUG
# =============================================================================

## status: Afficher le statut des containers
status:
	@echo "$(BLUE)>>> Statut des services FUG:$(NC)"
	@$(COMPOSE) ps -a

## ps: Alias pour status
ps: status

## logs: Afficher les logs en temps reel
logs:
	@$(COMPOSE) logs -f

## logs-appwrite: Logs Appwrite uniquement
logs-appwrite:
	@$(COMPOSE) logs -f appwrite

## logs-db: Logs MariaDB uniquement
logs-db:
	@$(COMPOSE) logs -f mariadb

## health: Verifier la sante des services
health:
	@echo "$(BLUE)>>> Verification de la sante des services...$(NC)"
	@echo ""
	@echo "MariaDB:"
	@$(COMPOSE) exec -T mariadb healthcheck.sh --connect --innodb_initialized 2>/dev/null && \
		echo "  $(GREEN)OK$(NC)" || echo "  $(RED)KO$(NC)"
	@echo ""
	@echo "Redis:"
	@$(COMPOSE) exec -T redis redis-cli ping 2>/dev/null && \
		echo "  $(GREEN)OK$(NC)" || echo "  $(RED)KO$(NC)"
	@echo ""
	@echo "Appwrite API:"
	@curl -sf http://localhost/v1/health > /dev/null 2>&1 && \
		echo "  $(GREEN)OK$(NC)" || echo "  $(RED)KO$(NC)"
	@echo ""

# =============================================================================
# ACCES AUX SERVICES
# =============================================================================

## shell: Ouvrir un shell dans le container Appwrite
shell:
	@$(COMPOSE) exec appwrite sh

## db-shell: Ouvrir un shell MySQL dans MariaDB
db-shell:
	@$(COMPOSE) exec mariadb mysql -u$${MYSQL_USER:-appwrite} -p$${MYSQL_PASSWORD:-password} $${MYSQL_DATABASE:-appwrite}

## redis-cli: Ouvrir le CLI Redis
redis-cli:
	@$(COMPOSE) exec redis redis-cli

# =============================================================================
# BACKUP & MAINTENANCE
# =============================================================================

## backup: Sauvegarder la base de donnees et volumes
backup:
	@echo "$(BLUE)>>> Lancement du backup complet...$(NC)"
	@./scripts/backup.sh
	@echo "$(GREEN)>>> Backup termine!$(NC)"

## backup-db: Sauvegarder uniquement la base de donnees
backup-db:
	@echo "$(BLUE)>>> Backup de la base de donnees...$(NC)"
	@mkdir -p backups
	@$(COMPOSE) exec -T mariadb mysqldump -u$${MYSQL_USER:-appwrite} -p$${MYSQL_PASSWORD:-password} $${MYSQL_DATABASE:-appwrite} > backups/db-$$(date +%Y%m%d-%H%M%S).sql
	@echo "$(GREEN)>>> Backup DB termine: backups/db-$$(date +%Y%m%d-%H%M%S).sql$(NC)"

## restore-db: Restaurer la base de donnees (BACKUP_FILE=path/to/file.sql)
restore-db:
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)>>> ERREUR: Specifiez BACKUP_FILE=path/to/file.sql$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)>>> Restauration de la base de donnees depuis $(BACKUP_FILE)...$(NC)"
	@$(COMPOSE) exec -T mariadb mysql -u$${MYSQL_USER:-appwrite} -p$${MYSQL_PASSWORD:-password} $${MYSQL_DATABASE:-appwrite} < $(BACKUP_FILE)
	@echo "$(GREEN)>>> Restauration terminee!$(NC)"

## clean: Arreter et supprimer les volumes (DANGER!)
clean:
	@echo "$(RED)>>> ATTENTION: Cette action va supprimer TOUTES les donnees!$(NC)"
	@echo "$(RED)>>> Appuyez sur Ctrl+C pour annuler, ou attendez 5 secondes...$(NC)"
	@sleep 5
	@$(COMPOSE) down -v
	@docker system prune -f
	@echo "$(GREEN)>>> Nettoyage termine.$(NC)"

## prune: Nettoyer les ressources Docker inutilisees
prune:
	@echo "$(YELLOW)>>> Nettoyage des ressources Docker inutilisees...$(NC)"
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)>>> Nettoyage termine.$(NC)"

## pull: Mettre a jour les images Docker
pull:
	@echo "$(BLUE)>>> Mise a jour des images Docker...$(NC)"
	@$(COMPOSE) pull
	@echo "$(GREEN)>>> Images mises a jour. Executez 'make restart' pour appliquer.$(NC)"

## build: Reconstruire les images (si Dockerfile custom)
build:
	@echo "$(BLUE)>>> Construction des images...$(NC)"
	@$(COMPOSE) build
	@echo "$(GREEN)>>> Construction terminee.$(NC)"

# =============================================================================
# STACK COMPLETE (Appwrite + App)
# =============================================================================

## all: Demarrer TOUT (Appwrite + App en dev)
all: check-env up app-dev
	@echo ""
	@echo "$(GREEN)╔═══════════════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║                    STACK FUG COMPLETE DEMARREE                        ║$(NC)"
	@echo "$(GREEN)╚═══════════════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "  - Appwrite Console:   http://localhost"
	@echo "  - Flutter App (dev):  http://localhost:8080"
	@echo ""

## all-dev: Demarrer tout en mode developpement complet
all-dev: check-env
	@echo "$(GREEN)>>> Demarrage de la stack complete en mode DEV...$(NC)"
	@$(COMPOSE) --profile dev up -d
	@echo "$(GREEN)>>> Stack DEV demarree!$(NC)"
	@make status

## all-prod: Demarrer tout en mode production
all-prod: check-env
	@echo "$(GREEN)>>> Demarrage de la stack complete en mode PRODUCTION...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FILE) --profile app up -d
	@echo "$(GREEN)>>> Stack PRODUCTION demarree!$(NC)"
	@make status

## full: Demarrer avec docker-compose.full.yml
full: check-env
	@echo "$(GREEN)>>> Demarrage de la stack FULL...$(NC)"
	@$(COMPOSE) -f $(COMPOSE_FULL) up -d
	@echo "$(GREEN)>>> Stack FULL demarree!$(NC)"
	@make status

# =============================================================================
# FLUTTER APP
# =============================================================================

## app-build: Build l'image Docker Flutter pour la production
app-build:
	@echo "$(MAGENTA)>>> Build de l'image Flutter (production)...$(NC)"
	@docker build -t fug-app:latest ../app
	@echo "$(GREEN)>>> Image fug-app:latest construite!$(NC)"

## app-build-dev: Build l'image Docker Flutter pour le dev
app-build-dev:
	@echo "$(MAGENTA)>>> Build de l'image Flutter (dev)...$(NC)"
	@docker build -f ../app/Dockerfile.dev -t fug-app:dev ../app
	@echo "$(GREEN)>>> Image fug-app:dev construite!$(NC)"

## app-dev: Demarrer l'app Flutter en mode developpement (hot reload)
app-dev: check-env
	@echo "$(MAGENTA)>>> Demarrage de Flutter en mode DEV...$(NC)"
	@$(COMPOSE) --profile app-dev up -d fug-app-dev
	@echo ""
	@echo "$(GREEN)>>> Flutter App disponible sur: http://localhost:8080$(NC)"
	@echo "$(YELLOW)>>> Hot reload active - les modifications sont automatiquement rechargees$(NC)"
	@echo ""

## app-prod: Demarrer l'app Flutter en mode production
app-prod: check-env app-build
	@echo "$(MAGENTA)>>> Demarrage de Flutter en mode PRODUCTION...$(NC)"
	@$(COMPOSE) --profile app up -d fug-app-web
	@echo ""
	@echo "$(GREEN)>>> Flutter App disponible sur: http://app.localhost$(NC)"
	@echo ""

## app-logs: Voir les logs de l'app Flutter
app-logs:
	@$(COMPOSE) logs -f fug-app-dev fug-app-web 2>/dev/null || $(COMPOSE) logs -f fug-app-dev

## app-shell: Ouvrir un shell dans le container Flutter
app-shell:
	@$(COMPOSE) exec fug-app-dev sh 2>/dev/null || $(COMPOSE) exec fug-app-web sh

## app-stop: Arreter uniquement l'app Flutter
app-stop:
	@echo "$(YELLOW)>>> Arret de l'app Flutter...$(NC)"
	@$(COMPOSE) stop fug-app-dev fug-app-web 2>/dev/null || true
	@echo "$(GREEN)>>> App Flutter arretee.$(NC)"

## app-restart: Redemarrer l'app Flutter
app-restart:
	@echo "$(YELLOW)>>> Redemarrage de l'app Flutter...$(NC)"
	@$(COMPOSE) restart fug-app-dev 2>/dev/null || $(COMPOSE) restart fug-app-web
	@echo "$(GREEN)>>> App Flutter redemarree.$(NC)"

# =============================================================================
# APPWRITE FUNCTIONS
# =============================================================================

## functions-build: Build l'image Docker des functions
functions-build:
	@echo "$(YELLOW)>>> Build de l'image Functions...$(NC)"
	@docker build -t fug-functions:latest ../functions
	@echo "$(GREEN)>>> Image fug-functions:latest construite!$(NC)"

## functions-build-dev: Build l'image Docker des functions (dev)
functions-build-dev:
	@echo "$(YELLOW)>>> Build de l'image Functions (dev)...$(NC)"
	@docker build -f ../functions/Dockerfile.dev -t fug-functions:dev ../functions
	@echo "$(GREEN)>>> Image fug-functions:dev construite!$(NC)"

## functions-dev: Demarrer l'environnement de dev des functions
functions-dev: check-env
	@echo "$(YELLOW)>>> Demarrage de l'env Functions en mode DEV...$(NC)"
	@$(COMPOSE) --profile functions-dev up -d fug-functions-dev
	@echo "$(GREEN)>>> Environnement Functions DEV demarre!$(NC)"
	@echo "$(YELLOW)>>> Utilisez 'make functions-shell' pour acceder au container$(NC)"

## functions-shell: Ouvrir un shell dans le container Functions
functions-shell:
	@$(COMPOSE) exec fug-functions-dev sh

## functions-test: Executer les tests des functions
functions-test:
	@echo "$(YELLOW)>>> Execution des tests Functions...$(NC)"
	@$(COMPOSE) exec fug-functions-dev npm test 2>/dev/null || \
		docker run --rm -v $$(pwd)/../functions:/functions -w /functions node:20-alpine npm test
	@echo "$(GREEN)>>> Tests termines!$(NC)"

## functions-logs: Voir les logs des functions
functions-logs:
	@$(COMPOSE) logs -f fug-functions-dev

## functions-stop: Arreter le container Functions
functions-stop:
	@echo "$(YELLOW)>>> Arret des Functions...$(NC)"
	@$(COMPOSE) stop fug-functions-dev 2>/dev/null || true
	@echo "$(GREEN)>>> Functions arretees.$(NC)"

## functions-install: Installer les dependances de toutes les functions
functions-install:
	@echo "$(YELLOW)>>> Installation des dependances Functions...$(NC)"
	@cd ../functions && npm run install:all
	@echo "$(GREEN)>>> Dependances installees!$(NC)"
