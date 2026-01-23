# =============================================================================
# FUG - Makefile
# =============================================================================
# Prérequis: fug-backend doit être démarré
#   cd /home/knabo/dev/fug-backend && make dev
# =============================================================================

.PHONY: help dev test stop logs shell check-backend

.DEFAULT_GOAL := help

# Couleurs
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
CYAN := \033[0;36m
NC := \033[0m

## help: Afficher cette aide
help:
	@echo ""
	@echo "$(CYAN)╔═══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║              FUG - Commandes Disponibles                       ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Prérequis: fug-backend doit être démarré$(NC)"
	@echo "  cd /home/knabo/dev/fug-backend && make dev"
	@echo ""
	@echo "$(GREEN)=== DÉVELOPPEMENT ===$(NC)"
	@echo "  make dev             Démarrer l'app Flutter en mode dev"
	@echo "  make test            Lancer les tests Flutter"
	@echo "  make stop            Arrêter l'app"
	@echo "  make logs            Voir les logs"
	@echo "  make shell           Ouvrir un shell dans le container"
	@echo ""
	@echo "$(GREEN)=== VÉRIFICATION ===$(NC)"
	@echo "  make check-backend   Vérifier que fug-backend tourne"
	@echo ""

## check-backend: Vérifier que fug-backend est démarré
check-backend:
	@echo "$(YELLOW)>>> Vérification de fug-backend...$(NC)"
	@curl -s http://localhost/v1/health/version > /dev/null 2>&1 && \
		echo "$(GREEN)>>> fug-backend OK$(NC)" || \
		(echo "$(RED)>>> fug-backend n'est pas démarré!$(NC)" && \
		 echo "$(YELLOW)>>> Lancez: cd /home/knabo/dev/fug-backend && make dev$(NC)" && exit 1)

## dev: Démarrer l'app Flutter en mode développement
dev: check-backend
	@echo "$(GREEN)>>> Démarrage de l'app Flutter...$(NC)"
	docker compose up -d fug-app-dev
	@echo "$(GREEN)>>> App disponible sur http://localhost:8080$(NC)"

## test: Lancer les tests Flutter
test: check-backend
	@echo "$(YELLOW)>>> Lancement des tests Flutter...$(NC)"
	docker compose run --rm fug-app-test

## stop: Arrêter l'app
stop:
	@echo "$(YELLOW)>>> Arrêt de l'app...$(NC)"
	docker compose down

## logs: Voir les logs
logs:
	docker compose logs -f fug-app-dev

## shell: Ouvrir un shell dans le container
shell:
	docker compose exec fug-app-dev /bin/bash
