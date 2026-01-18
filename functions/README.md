# FUG - Appwrite Functions

Ce dossier contient les Appwrite Functions pour le projet FUG (French Underground Gaming).

## Structure du projet

```
functions/
├── README.md
├── follow-user/           # Gestion du suivi d'utilisateurs
│   ├── package.json
│   └── src/
│       └── main.js
├── join-event/            # Inscription aux événements
│   ├── package.json
│   └── src/
│       └── main.js
├── create-event/          # Création d'événements
│   ├── package.json
│   └── src/
│       └── main.js
└── gamification/          # Système de gamification
    ├── package.json
    └── src/
        └── main.js
```

## Fonctions disponibles

### 1. follow-user

Gère le suivi entre utilisateurs.

**Fonctionnalités:**
- Crée la relation follower/following
- Met à jour les compteurs d'abonnés
- Notifie l'utilisateur suivi
- Attribue des points de gamification

**Payload:**
```json
{
  "followerId": "user_id_1",
  "followingId": "user_id_2"
}
```

**Points attribués:**
- Follower: +5 points
- Following (celui qui est suivi): +10 points

---

### 2. join-event

Gère l'inscription aux événements.

**Fonctionnalités:**
- Vérifie la disponibilité (limite de participants)
- Ajoute le participant à l'événement
- Notifie l'organisateur et les participants existants
- Attribue des points et vérifie les milestones

**Payload:**
```json
{
  "userId": "user_id",
  "eventId": "event_id"
}
```

**Points attribués:**
- Participant: +15 points
- Organisateur: +5 points par nouveau participant
- Bonus milestone 10 participants: +25 points (organisateur)
- Bonus milestone 50 participants: +50 points (organisateur)

---

### 3. create-event

Gère la création d'événements.

**Fonctionnalités:**
- Valide les données de l'événement
- Crée l'événement dans la base de données
- Notifie tous les followers du créateur
- Attribue des points et bonus

**Payload:**
```json
{
  "organizerId": "user_id",
  "title": "Titre de l'événement",
  "description": "Description détaillée...",
  "startDate": "2024-12-01T18:00:00Z",
  "endDate": "2024-12-01T23:00:00Z",
  "location": "Paris, France",
  "latitude": 48.8566,
  "longitude": 2.3522,
  "category": "gaming",
  "maxParticipants": 50,
  "imageUrl": "https://...",
  "tags": ["gaming", "esport"]
}
```

**Catégories valides:**
- `gaming`, `esport`, `tournament`, `lan_party`, `streaming`, `meetup`, `workshop`, `conference`, `other`

**Points attribués:**
- Création: +25 points
- Premier événement: +50 points bonus
- 5ème événement: +100 points bonus
- 10ème événement: +200 points bonus

---

### 4. gamification

Système complet de gamification.

**Actions disponibles:**

#### check_achievements
Vérifie et attribue les badges à un utilisateur.
```json
{
  "action": "check_achievements",
  "userId": "user_id"
}
```

#### calculate_leaderboard
Calcule et met à jour le classement.
```json
{
  "action": "calculate_leaderboard",
  "period": "weekly"
}
```
Périodes: `daily`, `weekly`, `monthly`, `all_time`

#### award_badge
Attribue manuellement un badge.
```json
{
  "action": "award_badge",
  "userId": "user_id",
  "badgeId": "early_adopter"
}
```

#### get_user_stats
Récupère les statistiques complètes d'un utilisateur.
```json
{
  "action": "get_user_stats",
  "userId": "user_id"
}
```

#### get_badges
Liste tous les badges disponibles.
```json
{
  "action": "get_badges"
}
```

**Badges disponibles:**

| Badge | Nom | Condition |
|-------|-----|-----------|
| first_event | Premier Pas | 1 événement rejoint |
| event_enthusiast | Enthousiaste | 10 événements rejoints |
| event_veteran | Vétéran | 50 événements rejoints |
| event_creator | Organisateur | 1 événement créé |
| event_master | Maître Organisateur | 10 événements créés |
| event_legend | Légende | 25 événements créés |
| social_butterfly | Papillon Social | 10 followers |
| influencer | Influenceur | 100 followers |
| community_star | Star de la Communauté | 500 followers |
| level_5 | Apprenti | Niveau 5 |
| level_10 | Expert | Niveau 10 |
| level_25 | Maître | Niveau 25 |
| early_adopter | Early Adopter | Attribution manuelle |
| community_helper | Aide de la Communauté | Attribution manuelle |

---

## Variables d'environnement

Configurez ces variables dans chaque function via la console Appwrite ou le CLI:

| Variable | Description | Exemple |
|----------|-------------|---------|
| `APPWRITE_FUNCTION_API_ENDPOINT` | URL de l'API Appwrite | `https://cloud.appwrite.io/v1` |
| `APPWRITE_FUNCTION_PROJECT_ID` | ID du projet | `fug-project-id` |
| `APPWRITE_API_KEY` | Clé API avec permissions nécessaires | `your-api-key` |
| `DATABASE_ID` | ID de la base de données | `fug-database` |
| `NODE_ENV` | Environnement (development/production) | `production` |

### Permissions requises pour la clé API

La clé API doit avoir les scopes suivants:
- `databases.read`
- `databases.write`

---

## Déploiement avec Appwrite CLI

### Prérequis

1. Installer le CLI Appwrite:
```bash
npm install -g appwrite-cli
```

2. Se connecter:
```bash
appwrite login
```

3. Initialiser le projet (si pas déjà fait):
```bash
appwrite init project
```

### Déployer une function

1. Aller dans le dossier de la function:
```bash
cd functions/follow-user
```

2. Installer les dépendances:
```bash
npm install
```

3. Créer la function sur Appwrite:
```bash
appwrite functions create \
  --functionId "follow-user" \
  --name "Follow User" \
  --runtime "node-18.0" \
  --execute "users" \
  --entrypoint "src/main.js"
```

4. Déployer le code:
```bash
appwrite functions createDeployment \
  --functionId "follow-user" \
  --entrypoint "src/main.js" \
  --code "."
```

### Déployer toutes les functions

Script bash pour déployer toutes les functions:

```bash
#!/bin/bash

FUNCTIONS=("follow-user" "join-event" "create-event" "gamification")

for func in "${FUNCTIONS[@]}"; do
  echo "Deploying $func..."
  cd functions/$func
  npm install
  appwrite functions createDeployment \
    --functionId "$func" \
    --entrypoint "src/main.js" \
    --code "."
  cd ../..
done

echo "All functions deployed!"
```

### Configurer les variables d'environnement

```bash
appwrite functions createVariable \
  --functionId "follow-user" \
  --key "DATABASE_ID" \
  --value "fug-database"
```

---

## Triggers configurés

### Webhooks recommandés

| Function | Event/Trigger | Description |
|----------|---------------|-------------|
| follow-user | HTTP POST | Appelé lors d'un clic "Suivre" |
| join-event | HTTP POST | Appelé lors d'une inscription |
| create-event | HTTP POST | Appelé lors de la création |
| gamification | Scheduled (CRON) | Leaderboard: `0 0 * * *` (quotidien) |
| gamification | HTTP POST | Check achievements: sur demande |

### Configuration des triggers via CLI

```bash
# Trigger schedulé pour le leaderboard (tous les jours à minuit)
appwrite functions createSchedule \
  --functionId "gamification" \
  --schedule "0 0 * * *"
```

---

## Collections requises

Assurez-vous que ces collections existent dans votre base de données:

- `users` - Utilisateurs
- `events` - Événements
- `event_participants` - Participants aux événements
- `followers` - Relations de suivi
- `notifications` - Notifications
- `gamification` - Données de gamification
- `leaderboard` - Classements

---

## Développement local

### Tester une function localement

1. Créer un fichier `.env` dans le dossier de la function:
```env
APPWRITE_FUNCTION_API_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_FUNCTION_PROJECT_ID=your-project-id
APPWRITE_API_KEY=your-api-key
DATABASE_ID=fug-database
NODE_ENV=development
```

2. Créer un fichier de test `test.js`:
```javascript
import main from './src/main.js';

const mockReq = {
  body: JSON.stringify({
    followerId: 'user1',
    followingId: 'user2'
  })
};

const mockRes = {
  json: (data, status = 200) => {
    console.log('Status:', status);
    console.log('Response:', JSON.stringify(data, null, 2));
    return mockRes;
  }
};

const mockLog = console.log;
const mockError = console.error;

main({ req: mockReq, res: mockRes, log: mockLog, error: mockError });
```

3. Exécuter:
```bash
node --env-file=.env test.js
```

---

## Gestion des erreurs

Toutes les functions retournent un format standardisé:

**Succès:**
```json
{
  "success": true,
  "data": { ... }
}
```

**Erreur:**
```json
{
  "success": false,
  "error": "Description de l'erreur",
  "details": "Détails (uniquement en développement)"
}
```

**Codes HTTP:**
- `200` - Succès
- `400` - Erreur de validation
- `404` - Ressource non trouvée
- `409` - Conflit (relation existe déjà, etc.)
- `500` - Erreur serveur

---

## Support

Pour toute question ou problème, contactez l'équipe FUG.
