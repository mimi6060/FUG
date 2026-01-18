# Architecture Infrastructure FUG

Documentation de l'architecture Docker du projet FUG avec Appwrite Self-Hosted.

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Diagramme des services](#diagramme-des-services)
- [Description des services](#description-des-services)
- [Flux reseau](#flux-reseau)
- [Volumes et persistance](#volumes-et-persistance)
- [Ports exposes](#ports-exposes)
- [Reseau Docker](#reseau-docker)

---

## Vue d'ensemble

L'infrastructure FUG est basee sur **Appwrite Self-Hosted** et comprend:

- **Reverse Proxy**: Traefik pour le routage et le load balancing
- **Backend**: Appwrite (API, Realtime, Workers)
- **Base de donnees**: MariaDB 10.11
- **Cache/Queue**: Redis 7
- **Monitoring**: Telegraf + InfluxDB (optionnel)
- **Outils de dev**: Mailhog, Adminer, Redis Commander

---

## Diagramme des services

```
                                    INFRASTRUCTURE FUG
    ====================================================================================

                                      INTERNET
                                          |
                                          v
    +-----------------------------------------------------------------------------------+
    |                                  TRAEFIK                                          |
    |                             (Reverse Proxy)                                       |
    |                                                                                   |
    |    :80 (HTTP) ----+                                      +---- :8080 (Dashboard)  |
    |    :443 (HTTPS) --+                                      |                        |
    +-------------------|--------------------------------------|------------------------+
                        |                                      |
                        v                                      v
    ====================================================================================
                                    fug-network (172.28.0.0/16)
    ====================================================================================
            |                    |                    |                    |
            v                    v                    v                    v
    +---------------+    +---------------+    +---------------+    +---------------+
    |   APPWRITE    |    |   APPWRITE    |    |    MARIADB    |    |     REDIS     |
    |   (Backend)   |    |   REALTIME    |    |    (Base de   |    |    (Cache)    |
    |               |    |  (WebSocket)  |    |    donnees)   |    |               |
    |   Port: 80    |    |   Port: 80    |    |   Port: 3306  |    |  Port: 6379   |
    +-------+-------+    +---------------+    +-------+-------+    +-------+-------+
            |                                         |                    |
            |                                         |                    |
            +--------------------+--------------------+--------------------+
                                 |
    ====================================================================================
                                WORKERS APPWRITE
    ====================================================================================
            |            |            |            |            |            |
            v            v            v            v            v            v
    +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
    | AUDITS   |  | WEBHOOKS |  | DELETES  |  | DATABASES|  |  BUILDS  |  |  MAILS   |
    | Worker   |  |  Worker  |  |  Worker  |  |  Worker  |  |  Worker  |  |  Worker  |
    +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
            |            |            |            |            |            |
            v            v            v            v            v            v
    +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
    |FUNCTIONS |  |MESSAGING |  |MIGRATIONS|  | CERTIFS  |  |  USAGE   |  |SCHEDULER |
    | Worker   |  |  Worker  |  |  Worker  |  |  Worker  |  |  Worker  |  | Functions|
    +----------+  +----------+  +----------+  +----------+  +----------+  +----------+
                                       |
    ====================================================================================
                                EXECUTOR & MAINTENANCE
    ====================================================================================
                                       |
                        +--------------+---------------+
                        |                              |
                        v                              v
                +---------------+              +---------------+
                |   EXECUTOR    |              |  MAINTENANCE  |
                |  (Functions)  |              |    (Cron)     |
                |               |              |               |
                |   /var/run/   |              |   Cleanup     |
                |  docker.sock  |              |   Routines    |
                +---------------+              +---------------+

    ====================================================================================
                            MONITORING (Optionnel - Profile: monitoring)
    ====================================================================================
                                       |
                        +--------------+---------------+
                        |                              |
                        v                              v
                +---------------+              +---------------+
                |   INFLUXDB    |              |   TELEGRAF    |
                |  (Metriques)  |              |  (Collecteur) |
                |               |              |               |
                |   Port: 8086  |              |   Metriques   |
                +---------------+              |   Docker +    |
                                               |   System      |
                                               +---------------+

    ====================================================================================
                         OUTILS DEVELOPPEMENT (Override - Dev uniquement)
    ====================================================================================
                                       |
            +-------------+------------+-------------+-------------+
            |             |            |             |             |
            v             v            v             v             v
    +----------+   +----------+   +----------+   +----------+   +----------+
    | MAILHOG  |   | ADMINER  |   |  REDIS   |   | APPWRITE |   | MARIADB  |
    |  (SMTP)  |   |   (DB)   |   |COMMANDER |   |  Direct  |   |  Direct  |
    |          |   |          |   |          |   |          |   |          |
    | :1025    |   | :8081    |   | :8082    |   | :9000    |   | :3306    |
    | :8025    |   |          |   |          |   |          |   |          |
    +----------+   +----------+   +----------+   +----------+   +----------+
```

---

## Description des services

### Services principaux

| Service | Image | Role | Dependances |
|---------|-------|------|-------------|
| `traefik` | traefik:2.10 | Reverse proxy, routage, TLS | - |
| `appwrite` | appwrite/appwrite:latest | Backend API principal | mariadb, redis |
| `appwrite-realtime` | appwrite/appwrite:latest | WebSocket server | appwrite |
| `mariadb` | mariadb:10.11 | Base de donnees relationnelle | - |
| `redis` | redis:7-alpine | Cache et queue de messages | - |

### Workers Appwrite

| Worker | Role | Dependances |
|--------|------|-------------|
| `appwrite-worker-audits` | Logs d'audit | appwrite |
| `appwrite-worker-webhooks` | Execution des webhooks | appwrite |
| `appwrite-worker-deletes` | Suppression des ressources | appwrite |
| `appwrite-worker-databases` | Operations sur les bases | appwrite |
| `appwrite-worker-builds` | Build des fonctions | appwrite |
| `appwrite-worker-certificates` | Gestion SSL/TLS | appwrite |
| `appwrite-worker-functions` | Execution des fonctions | appwrite |
| `appwrite-worker-mails` | Envoi d'emails | appwrite |
| `appwrite-worker-messaging` | Notifications push | appwrite |
| `appwrite-worker-migrations` | Migrations de donnees | appwrite |
| `appwrite-worker-usage` | Statistiques d'utilisation | appwrite |

### Services d'execution

| Service | Role | Particularites |
|---------|------|----------------|
| `appwrite-executor` | Execution des fonctions cloud | Acces au Docker socket |
| `appwrite-maintenance` | Nettoyage periodique | Cron job interne |
| `appwrite-scheduler-functions` | Planification des fonctions | Cron |
| `appwrite-scheduler-messages` | Planification des messages | Cron |
| `appwrite-usage` | Agregation des statistiques | Dump periodique |

### Monitoring (Optionnel)

| Service | Image | Role |
|---------|-------|------|
| `influxdb` | influxdb:2.7-alpine | Stockage des metriques |
| `telegraf` | telegraf:1.28-alpine | Collecte des metriques |

### Outils de developpement (Override)

| Service | Image | Role |
|---------|-------|------|
| `mailhog` | mailhog/mailhog:latest | Capture des emails |
| `adminer` | adminer:latest | Interface admin MariaDB |
| `redis-commander` | rediscommander/redis-commander:latest | Interface Redis |

---

## Flux reseau

### Flux entrants (depuis Internet)

```
Client HTTP/HTTPS
       |
       v
   Traefik (:80/:443)
       |
       +---> /v1/* -----------> Appwrite API (:80)
       |
       +---> /v1/realtime ---> Appwrite Realtime (:80)
       |
       +---> /* (static) ----> Appwrite Console (:80)
```

### Flux internes

```
Appwrite API
       |
       +---> Redis (cache/queue)
       |     - Sessions
       |     - Cache de requetes
       |     - File d'attente workers
       |
       +---> MariaDB (persistance)
             - Utilisateurs
             - Documents
             - Configurations

Workers
       |
       +---> Redis (lecture queue)
       |
       +---> MariaDB (lecture/ecriture)
       |
       +---> Services externes (SMTP, S3, etc.)

Executor
       |
       +---> Docker Socket
       |     - Creation containers runtime
       |     - Execution fonctions
       |
       +---> Redis (resultats)
```

### Flux de monitoring

```
Telegraf
       |
       +---> Docker Socket (metriques containers)
       |
       +---> /hostfs/* (metriques systeme)
       |
       +---> Appwrite /v1/health/* (health checks)
       |
       +---> Redis :6379 (metriques Redis)
       |
       +---> MariaDB :3306 (metriques MySQL)
       |
       v
   InfluxDB (:8086)
```

---

## Volumes et persistance

### Volumes de donnees

| Volume | Conteneur | Chemin dans le container | Description |
|--------|-----------|--------------------------|-------------|
| `fug-mariadb-data` | mariadb | /var/lib/mysql | Donnees MariaDB |
| `fug-redis-data` | redis | /data | Donnees Redis (AOF) |
| `fug-appwrite-uploads` | appwrite | /storage/uploads | Fichiers uploades |
| `fug-appwrite-cache` | appwrite | /storage/cache | Cache applicatif |
| `fug-appwrite-config` | appwrite | /storage/config | Configuration |
| `fug-appwrite-certificates` | appwrite | /storage/certificates | Certificats SSL |
| `fug-appwrite-functions` | appwrite | /storage/functions | Code des fonctions |
| `fug-appwrite-builds` | appwrite | /storage/builds | Builds des fonctions |

### Volumes de monitoring

| Volume | Conteneur | Chemin | Description |
|--------|-----------|--------|-------------|
| `fug-influxdb-data` | influxdb | /var/lib/influxdb2 | Donnees InfluxDB |
| `fug-influxdb-config` | influxdb | /etc/influxdb2 | Config InfluxDB |

### Volumes de configuration

| Volume | Conteneur | Chemin | Description |
|--------|-----------|--------|-------------|
| `fug-traefik-certificates` | traefik | /certificates | Certificats Traefik |

### Strategie de persistance

```
CRITIQUE (Backup quotidien obligatoire)
    |
    +-- fug-mariadb-data (Donnees utilisateurs, documents)
    |
    +-- fug-appwrite-uploads (Fichiers uploades)
    |
    +-- fug-appwrite-certificates (Certificats SSL)

IMPORTANT (Backup hebdomadaire recommande)
    |
    +-- fug-appwrite-config (Configuration)
    |
    +-- fug-appwrite-functions (Code des fonctions)
    |
    +-- fug-redis-data (Sessions, cache persistant)

RECONSTRUCTIBLE (Pas de backup necessaire)
    |
    +-- fug-appwrite-cache (Cache regenerable)
    |
    +-- fug-appwrite-builds (Builds regenerables)
    |
    +-- fug-influxdb-data (Metriques - non critique)
```

---

## Ports exposes

### Environnement de developpement

| Port | Service | Protocole | Description |
|------|---------|-----------|-------------|
| 80 | Traefik | HTTP | Point d'entree principal |
| 443 | Traefik | HTTPS | Point d'entree securise |
| 8080 | Traefik | HTTP | Dashboard Traefik |
| 3306 | MariaDB | TCP | Acces direct base de donnees |
| 6379 | Redis | TCP | Acces direct cache |
| 9000 | Appwrite | HTTP | Acces direct API (sans proxy) |
| 8081 | Adminer | HTTP | Interface admin DB |
| 8082 | Redis Commander | HTTP | Interface Redis |
| 1025 | Mailhog | SMTP | Serveur SMTP de test |
| 8025 | Mailhog | HTTP | Interface emails |
| 8086 | InfluxDB | HTTP | API metriques |

### Environnement de production

| Port | Service | Protocole | Description |
|------|---------|-----------|-------------|
| 80 | Traefik | HTTP | Redirection vers HTTPS |
| 443 | Traefik | HTTPS | Point d'entree unique |

### Mapping des ports

```
DEVELOPPEMENT                           PRODUCTION
==============                          ==========

Internet                                Internet
    |                                       |
    v                                       v
+--------+                              +--------+
| :80    | HTTP                         | :80    | HTTP -> Redirect 443
| :443   | HTTPS                        | :443   | HTTPS
| :8080  | Traefik Dashboard            +--------+
+--------+                                  |
    |                                       v
    v                                   Traefik
Internal Access                             |
    |                                       v
    +-- :3306 MariaDB                   [Services internes uniquement]
    +-- :6379 Redis
    +-- :9000 Appwrite Direct
    +-- :8081 Adminer
    +-- :8082 Redis Commander
    +-- :8025 Mailhog Web
    +-- :1025 Mailhog SMTP
    +-- :8086 InfluxDB
```

---

## Reseau Docker

### Configuration du reseau

```yaml
networks:
  fug-network:
    name: fug-network
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
```

### Resolution DNS interne

Tous les services peuvent communiquer entre eux via leur nom de service:

| Hostname | Service | Port interne |
|----------|---------|--------------|
| `traefik` | Traefik | 80, 443, 8080 |
| `appwrite` | Appwrite API | 80 |
| `appwrite-realtime` | Appwrite WebSocket | 80 |
| `mariadb` | MariaDB | 3306 |
| `redis` | Redis | 6379 |
| `influxdb` | InfluxDB | 8086 |
| `mailhog` | Mailhog | 1025, 8025 |

### Isolation reseau

```
fug-network (bridge)
    |
    +-- Tous les services FUG
    |
    +-- Isolation des autres reseaux Docker
    |
    +-- Communication inter-containers via DNS

Runtimes Functions (cree dynamiquement par l'executor)
    |
    +-- Containers des fonctions cloud
    |
    +-- Connecte a fug-network pour acces aux services
```

### Securite reseau

- Seul Traefik est expose vers l'exterieur
- Communication inter-services via le reseau interne Docker
- Pas d'exposition directe de MariaDB/Redis en production
- Les fonctions s'executent dans des containers isoles

---

## Healthchecks

### Configuration des healthchecks

| Service | Endpoint/Commande | Intervalle | Timeout | Retries |
|---------|-------------------|------------|---------|---------|
| Traefik | `traefik healthcheck` | 30s | 10s | 3 |
| MariaDB | `healthcheck.sh --connect --innodb_initialized` | 30s | 10s | 5 |
| Redis | `redis-cli ping` | 30s | 10s | 3 |
| Appwrite | `curl http://localhost/v1/health` | 30s | 10s | 5 |
| InfluxDB | `curl http://localhost:8086/ping` | 30s | 10s | 3 |

### Ordre de demarrage

```
1. mariadb (start_period: 60s)
   |
   +-- Attente healthcheck OK
   |
2. redis (start_period: 10s)
   |
   +-- Attente healthcheck OK
   |
3. traefik (start_period: 10s)
   |
4. appwrite (start_period: 120s)
   |
   +-- Depend de mariadb + redis (service_healthy)
   |
5. appwrite-realtime
   |
   +-- Depend de appwrite (service_healthy)
   |
6. Workers (tous)
   |
   +-- Dependent de appwrite (service_healthy)
   |
7. Monitoring (si profile actif)
   |
   +-- influxdb puis telegraf
```

---

*Documentation Architecture FUG - Janvier 2026*
