# Plane - Gestion des Stories FUG

## Accès

- **URL**: http://localhost:8088
- **Premier lancement**: Créer un compte admin

## Commandes

```bash
# Démarrer
cd infrastructure/plane/plane-app
docker compose --env-file plane.env up -d

# Arrêter
docker compose --env-file plane.env down

# Voir les logs
docker compose --env-file plane.env logs -f

# Statut
docker compose --env-file plane.env ps
```

## Configuration

- Port HTTP: 8088 (configurable dans `plane.env`)
- Port HTTPS: 8443
- Base de données: PostgreSQL interne
- Stockage: MinIO interne

## Intégration avec FUG

Plane est utilisé pour gérer:
- Les **Epics** (E1-E6 du backlog)
- Les **User Stories** (US-001 à US-034)
- Les **Sprints** de développement
- Le suivi de la **QA**

## Structure recommandée

1. **Workspace**: FUG
2. **Project**: MVP v1.0
3. **Modules**:
   - Epic 1: Gestion des comptes
   - Epic 2: Gestion des profils
   - Epic 3: Réseau social
   - Epic 4: Gestion des FUG
   - Epic 5: Notifications
   - Epic 6: Gamification
   - QA: Tests et validation
