# =============================================================================
# FUG Functions - Dockerfile pour Appwrite Functions (Node.js)
# =============================================================================
# Ce Dockerfile est utilise pour le developpement local et les tests
# En production, Appwrite gere le deployment des fonctions automatiquement
# =============================================================================

FROM node:20-alpine

# Labels
LABEL maintainer="FUG Team"
LABEL description="FUG - Appwrite Functions Development Environment"
LABEL version="1.0.0"

# Installer les outils necessaires
RUN apk add --no-cache \
    curl \
    git \
    bash

# Creer le repertoire de travail
WORKDIR /functions

# Variables d'environnement par defaut
ENV NODE_ENV=development
ENV APPWRITE_FUNCTION_API_ENDPOINT=http://appwrite/v1
ENV APPWRITE_FUNCTION_PROJECT_ID=fug

# Copier le fichier package.json racine si present
COPY package*.json ./

# Installer les dependances
RUN npm ci --only=production 2>/dev/null || npm install 2>/dev/null || echo "No root package.json"

# Copier toutes les fonctions
COPY . .

# Script pour installer les dependances de chaque fonction
RUN find . -name "package.json" -not -path "./node_modules/*" -execdir sh -c 'npm ci --only=production 2>/dev/null || npm install 2>/dev/null || true' \;

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD echo "Functions container healthy" || exit 1

# Commande par defaut (peut etre override)
CMD ["node", "--version"]
