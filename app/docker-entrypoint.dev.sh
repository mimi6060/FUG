#!/bin/bash
# =============================================================================
# FUG App - Script d'entree Docker pour le developpement
# =============================================================================

set -e

echo "========================================"
echo "  FUG Flutter Development Environment"
echo "========================================"
echo ""

# Verifier si les dependances sont installees
if [ -f "pubspec.yaml" ]; then
    echo "[INFO] Verification des dependances Flutter..."
    flutter pub get
    echo "[OK] Dependances installees"
else
    echo "[WARNING] pubspec.yaml non trouve. Assurez-vous de monter le volume correctement."
fi

echo ""
echo "[INFO] Demarrage du serveur Flutter Web..."
echo "[INFO] Port: ${FLUTTER_WEB_PORT:-8080}"
echo "[INFO] Appwrite Endpoint: ${APPWRITE_ENDPOINT:-http://localhost/v1}"
echo ""
echo "========================================"
echo "  Application disponible sur:"
echo "  http://localhost:${FLUTTER_WEB_PORT:-8080}"
echo "========================================"
echo ""

# Executer la commande passee en argument
exec "$@"
