#!/bin/bash
# Import Modernisation 2026 stories into Plane

API_KEY="plane_api_efb329a1bef9492995648b9ee92e939a"
PROJECT_ID="f110c685-ede4-4756-8e41-8cb39bb316f3"
BASE_URL="http://localhost:8088/api/v1/workspaces/fug/projects/$PROJECT_ID"

# States
STATE_BACKLOG="cd62817e-581b-47bd-b8eb-0486aff77ca3"
STATE_TODO="ea7339fb-b9ec-4a10-a49c-53fc3e8bc795"

# Module E0
MODULE_E0="03be4327-84cb-4d23-b9c3-90cfade321f5"

# Priority: 1=urgent, 2=high, 3=medium, 4=low, 0=none

create_issue() {
    local name="$1"
    local desc="$2"
    local state="$3"
    local priority="$4"
    local module="$5"

    # Create issue
    ISSUE_ID=$(curl -s -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
      -d "{\"name\": \"$name\", \"description_html\": \"<p>$desc</p>\", \"state\": \"$state\", \"priority\": \"$priority\"}" \
      "$BASE_URL/issues/" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    # Add to module if specified
    if [ -n "$module" ] && [ -n "$ISSUE_ID" ]; then
        curl -s -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" \
          -d "{\"issues\": [\"$ISSUE_ID\"]}" \
          "$BASE_URL/modules/$module/issues/" > /dev/null
    fi

    echo "$name -> $ISSUE_ID"
}

echo "=== Phase 1: Conformité & Obligations Légales (CRITIQUE) ==="

create_issue "MOD-001: Conformité RGPD Complète" \
  "Consentement explicite, droit à l'oubli (US-006), export données, politique confidentialité. Feature: MOD-001-rgpd-compliance.md" \
  "$STATE_TODO" "urgent" "$MODULE_E0"

create_issue "MOD-001-A: Écran de consentement RGPD" \
  "Écran au premier lancement avec cases à cocher pour données essentielles, analytics, marketing" \
  "$STATE_TODO" "urgent" "$MODULE_E0"

create_issue "MOD-001-B: Export des données (portabilité)" \
  "Bouton dans paramètres pour exporter toutes les données en JSON/ZIP" \
  "$STATE_TODO" "high" "$MODULE_E0"

create_issue "MOD-002: Apple Sign-In" \
  "OBLIGATOIRE App Store. Bouton Sign in with Apple, OAuth2, gestion email relay. Feature: MOD-002-apple-signin.md" \
  "$STATE_TODO" "urgent" "$MODULE_E0"

create_issue "MOD-003: Conformité DSA" \
  "Point de contact, CGU claires, signalement contenu, modération transparente. Feature: MOD-003-dsa-compliance.md" \
  "$STATE_TODO" "high" "$MODULE_E0"

create_issue "MOD-003-A: Système de signalement contenu" \
  "Bouton Signaler sur événements et profils, catégories, suivi du signalement" \
  "$STATE_TODO" "high" "$MODULE_E0"

create_issue "MOD-003-B: Workflow de modération" \
  "Notification modération, raison explicite, mécanisme d'appel" \
  "$STATE_BACKLOG" "high" "$MODULE_E0"

echo ""
echo "=== Phase 2: Mise à Jour Technique ==="

create_issue "MOD-004: Versions OS Minimales" \
  "Mettre à jour: Android 10+ (API 29), iOS 14+. pubspec.yaml, build.gradle, Podfile. Feature: MOD-004-os-versions.md" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-005: Reformulation Marketing" \
  "Nouveau pitch, lexique modernisé, messages modération alcool. Feature: MOD-005-branding-update.md" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-006: Politique de Confidentialité" \
  "Page in-app complète, PDF téléchargeable, revue juridique. Feature: MOD-006-privacy-policy.md" \
  "$STATE_TODO" "high" "$MODULE_E0"

echo ""
echo "=== Phase 3: Nouvelles Fonctionnalités (V2) ==="

create_issue "MOD-007: Intégrations Modernes" \
  "Partage WhatsApp, Instagram Stories, export calendrier. Feature: MOD-007-modern-integrations.md" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-007-A: Partage WhatsApp" \
  "Deep link partage événement via WhatsApp" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-007-B: Export Calendrier" \
  "Ajouter FUG au calendrier natif iOS/Android" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-008: IA et Recommandations" \
  "Modération auto images, recommandations événements, matching social. Feature: MOD-008-ai-features.md" \
  "$STATE_BACKLOG" "low" "$MODULE_E0"

create_issue "MOD-008-A: Modération automatique images" \
  "Google Vision ou AWS Rekognition pour détecter contenu inapproprié" \
  "$STATE_BACKLOG" "medium" "$MODULE_E0"

create_issue "MOD-009: Monétisation Éthique" \
  "FUG Premium, partenariats bars. Post-MVP. Feature: MOD-009-monetization.md" \
  "$STATE_BACKLOG" "low" "$MODULE_E0"

echo ""
echo "=== Stories Spec existantes - Mise à jour ==="

# SPEC-002 à SPEC-008 déjà créées, on va les mettre à jour avec les bonnes priorités
echo "Stories SPEC déjà créées dans la session précédente"

echo ""
echo "=== Import terminé ==="
echo "Total: 16 nouvelles stories créées dans E0 - Modernisation Spec 2026"
