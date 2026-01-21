#!/bin/bash
# Import FUG stories into Plane

API_KEY="plane_api_efb329a1bef9492995648b9ee92e939a"
PROJECT_ID="f110c685-ede4-4756-8e41-8cb39bb316f3"
BASE_URL="http://localhost:8088/api/v1/workspaces/fug/projects/$PROJECT_ID"

# States
STATE_BACKLOG="cd62817e-581b-47bd-b8eb-0486aff77ca3"
STATE_TODO="ea7339fb-b9ec-4a10-a49c-53fc3e8bc795"
STATE_DONE="f1b62e61-f55a-4b14-a80b-03c3adee9d77"

# Modules (Epics)
MODULE_E1="ee939f80-dcbe-4058-b833-c328f936f3d7"
MODULE_E2="c9acd278-b70e-4b27-9f45-8f8bea200c58"
MODULE_E3="6bd16713-ce68-4929-94cd-55670669d834"
MODULE_E4="b856183d-a2b1-4863-8ea7-a16dd84d2006"
MODULE_E5="3545a093-59a0-43fa-915a-19b80fed1f6d"
MODULE_E6="387961a1-d638-4dd0-97de-041a37657947"
MODULE_QA="b20f1269-d49c-42e2-920c-64d759f1e0c1"

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

echo "=== EPIC 1 - Gestion des comptes ==="
create_issue "US-001: Inscription par email" "Formulaire email/password avec validation, email de vérification" "$STATE_DONE" "urgent" "$MODULE_E1"
create_issue "US-002: Inscription OAuth (Google/Apple)" "OAuth integration - UI présente, backend TODO" "$STATE_TODO" "high" "$MODULE_E1"
create_issue "US-003: Connexion utilisateur" "Login email/password + OAuth + Remember me" "$STATE_DONE" "urgent" "$MODULE_E1"
create_issue "US-004: Réinitialisation mot de passe" "Envoi email reset, formulaire nouveau password" "$STATE_DONE" "urgent" "$MODULE_E1"
create_issue "US-005: Déconnexion" "Bouton logout, suppression token, redirection" "$STATE_DONE" "urgent" "$MODULE_E1"
create_issue "US-006: Suppression de compte" "RGPD - délai 30j, confirmation, email" "$STATE_BACKLOG" "high" "$MODULE_E1"

echo ""
echo "=== EPIC 2 - Gestion des profils ==="
create_issue "US-007: Création profil initial" "Pseudo unique, date naissance, ville, photo, bio" "$STATE_DONE" "urgent" "$MODULE_E2"
create_issue "US-008: Modification du profil" "Edition tous champs sauf date naissance" "$STATE_DONE" "urgent" "$MODULE_E2"
create_issue "US-009: Gestion photo de profil" "Upload galerie/camera, crop, compression, modération" "$STATE_DONE" "urgent" "$MODULE_E2"
create_issue "US-010: Préférences boissons" "Multi-select catégories, niveau expertise" "$STATE_DONE" "medium" "$MODULE_E2"
create_issue "US-011: Profil public" "Vue comme les autres voient" "$STATE_DONE" "medium" "$MODULE_E2"

echo ""
echo "=== EPIC 3 - Réseau social ==="
create_issue "US-012: Recherche utilisateurs" "Recherche par pseudo, autocomplétion, filtres" "$STATE_DONE" "urgent" "$MODULE_E3"
create_issue "US-013: Suivre un utilisateur" "Bouton follow, notification, compteur" "$STATE_DONE" "urgent" "$MODULE_E3"
create_issue "US-014: Ne plus suivre" "Unfollow immédiat sans notification" "$STATE_DONE" "urgent" "$MODULE_E3"
create_issue "US-015: Liste followers/abonnements" "Onglets avec pagination" "$STATE_DONE" "medium" "$MODULE_E3"
create_issue "US-016: Bloquer utilisateur" "Block/unblock, liste bloqués" "$STATE_DONE" "medium" "$MODULE_E3"

echo ""
echo "=== EPIC 4 - Gestion des FUG ==="
create_issue "US-017: Créer un FUG" "Formulaire 4 étapes: info, date, lieu, options" "$STATE_DONE" "urgent" "$MODULE_E4"
create_issue "US-018: Carte des FUG" "flutter_map, markers, clusters, filtres" "$STATE_DONE" "urgent" "$MODULE_E4"
create_issue "US-019: Détails d'un FUG" "Info complète, organisateur, participants" "$STATE_DONE" "urgent" "$MODULE_E4"
create_issue "US-020: Rejoindre FUG public" "Bouton rejoindre, notification organisateur" "$STATE_TODO" "urgent" "$MODULE_E4"
create_issue "US-021: Demander rejoindre FUG privé" "Demande avec message, statut attente" "$STATE_BACKLOG" "urgent" "$MODULE_E4"
create_issue "US-022: Gérer demandes participation" "Liste demandes, accepter/refuser" "$STATE_BACKLOG" "urgent" "$MODULE_E4"
create_issue "US-023: Inviter utilisateurs" "Selection followers, envoi invitations" "$STATE_BACKLOG" "medium" "$MODULE_E4"
create_issue "US-024: Annuler participation" "Bouton annuler, notification, place libérée" "$STATE_BACKLOG" "urgent" "$MODULE_E4"
create_issue "US-025: Annuler FUG (organisateur)" "Motif obligatoire, notification participants" "$STATE_TODO" "urgent" "$MODULE_E4"
create_issue "US-026: Historique FUG" "Mes FUG passés/à venir" "$STATE_DONE" "medium" "$MODULE_E4"

echo ""
echo "=== EPIC 5 - Notifications ==="
create_issue "US-027: Notifications push" "FCM/APNs, tous types événements" "$STATE_BACKLOG" "urgent" "$MODULE_E5"
create_issue "US-028: Centre notifications in-app" "Liste, badge, mark as read" "$STATE_DONE" "urgent" "$MODULE_E5"
create_issue "US-029: Paramètres notifications" "Toggle par type, désactivation globale" "$STATE_BACKLOG" "medium" "$MODULE_E5"
create_issue "US-030: Rappel avant FUG" "Push 24h et 1h avant" "$STATE_BACKLOG" "medium" "$MODULE_E5"

echo ""
echo "=== EPIC 6 - Gamification ==="
create_issue "US-031: Système de badges" "Badges auto, notification, affichage profil" "$STATE_TODO" "medium" "$MODULE_E6"
create_issue "US-032: Statistiques personnelles" "FUG count, followers, graphiques" "$STATE_DONE" "medium" "$MODULE_E6"
create_issue "US-033: Niveaux et progression" "XP system, paliers, barre progression" "$STATE_TODO" "medium" "$MODULE_E6"
create_issue "US-034: Classement (Post-MVP)" "Leaderboard hebdo/mensuel" "$STATE_BACKLOG" "low" "$MODULE_E6"

echo ""
echo "=== QA - Tests et Validation ==="
create_issue "QA-001: Tests Auth Flow" "Tests unitaires AuthRepository, widgets login/register" "$STATE_BACKLOG" "high" "$MODULE_QA"
create_issue "QA-002: Tests Profile" "Tests ProfileRepository, widgets profile/edit" "$STATE_BACKLOG" "high" "$MODULE_QA"
create_issue "QA-003: Tests Social" "Tests SocialRepository, follow/unfollow/block" "$STATE_BACKLOG" "high" "$MODULE_QA"
create_issue "QA-004: Tests Events" "Tests EventRepository, création, carte, géoloc" "$STATE_BACKLOG" "high" "$MODULE_QA"
create_issue "QA-005: Tests Notifications" "Tests NotificationRepository, screen" "$STATE_BACKLOG" "medium" "$MODULE_QA"
create_issue "QA-006: Tests E2E" "Parcours complets inscription, FUG, follow" "$STATE_BACKLOG" "high" "$MODULE_QA"

echo ""
echo "=== Import terminé ==="
