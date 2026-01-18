# Monitoring - Infrastructure FUG

Documentation complete pour le monitoring de l'infrastructure FUG avec Telegraf, InfluxDB et Grafana.

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Architecture de monitoring](#architecture-de-monitoring)
- [Configuration Telegraf](#configuration-telegraf)
- [Configuration InfluxDB](#configuration-influxdb)
- [Dashboard Grafana](#dashboard-grafana)
- [Alertes recommandees](#alertes-recommandees)
- [Centralisation des logs](#centralisation-des-logs)
- [Metriques disponibles](#metriques-disponibles)

---

## Vue d'ensemble

Le stack de monitoring FUG utilise:

| Composant | Role | Port |
|-----------|------|------|
| **Telegraf** | Collecte des metriques | - |
| **InfluxDB** | Stockage des metriques | 8086 |
| **Grafana** | Visualisation | 3000 |

### Activation du monitoring

```bash
# Demarrer avec le profile monitoring
make up-monitoring

# Ou directement avec docker compose
docker compose --profile monitoring up -d
```

---

## Architecture de monitoring

```
                          ARCHITECTURE MONITORING
    ===========================================================================

    +-------------+     +-------------+     +-------------+     +-------------+
    |   Docker    |     |   Appwrite  |     |   MariaDB   |     |    Redis    |
    |   Daemon    |     |   /health   |     |   :3306     |     |   :6379     |
    +------+------+     +------+------+     +------+------+     +------+------+
           |                   |                   |                   |
           |                   |                   |                   |
           +-------------------+-------------------+-------------------+
                                         |
                                         v
                               +-------------------+
                               |     TELEGRAF      |
                               |                   |
                               | - Docker metrics  |
                               | - System metrics  |
                               | - HTTP responses  |
                               | - Redis metrics   |
                               | - MySQL metrics   |
                               +--------+----------+
                                        |
                                        v
                               +-------------------+
                               |     INFLUXDB      |
                               |                   |
                               | Bucket: appwrite  |
                               | Retention: 30d    |
                               |                   |
                               +--------+----------+
                                        |
                                        v
                               +-------------------+
                               |     GRAFANA       |
                               |                   |
                               | - Dashboards      |
                               | - Alertes         |
                               |                   |
                               +-------------------+
```

---

## Configuration Telegraf

### Fichier de configuration

Le fichier `telegraf.conf` est monte dans le container Telegraf.

**Configuration globale:**

```toml
[global_tags]
  project = "fug"
  environment = "${_APP_ENV}"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  flush_interval = "10s"
  hostname = "fug-telegraf"
```

### Inputs configures

#### Metriques Docker

```toml
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  container_name_include = ["fug-*"]
  timeout = "5s"
  perdevice = true
```

**Metriques collectees:**
- CPU par container
- Memoire utilisee/limite
- I/O reseau
- I/O disque
- Nombre de processus

#### Metriques systeme

```toml
[[inputs.cpu]]
  percpu = true
  totalcpu = true

[[inputs.mem]]

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "overlay"]

[[inputs.diskio]]

[[inputs.net]]
  interfaces = ["eth*", "en*"]

[[inputs.processes]]

[[inputs.system]]
```

#### Health checks Appwrite

```toml
[[inputs.http_response]]
  urls = ["http://appwrite/v1/health"]
  response_timeout = "5s"
  [inputs.http_response.tags]
    service = "appwrite"
    check = "health"

[[inputs.http_response]]
  urls = ["http://appwrite/v1/health/db"]
  [inputs.http_response.tags]
    service = "appwrite"
    check = "database"

[[inputs.http_response]]
  urls = ["http://appwrite/v1/health/cache"]
  [inputs.http_response.tags]
    service = "appwrite"
    check = "cache"

[[inputs.http_response]]
  urls = ["http://appwrite/v1/health/queue"]
  [inputs.http_response.tags]
    service = "appwrite"
    check = "queue"
```

#### Metriques Redis

```toml
[[inputs.redis]]
  servers = ["tcp://redis:6379"]
  [inputs.redis.tags]
    service = "redis"
```

**Metriques collectees:**
- Connexions actives
- Memoire utilisee
- Operations par seconde
- Cache hit/miss ratio
- Keys expiries

#### Metriques MariaDB

```toml
[[inputs.mysql]]
  servers = ["${MYSQL_USER}:${MYSQL_PASSWORD}@tcp(mariadb:3306)/${MYSQL_DATABASE}"]
  gather_process_list = true
  gather_innodb_metrics = true
  gather_table_io_waits = true
  [inputs.mysql.tags]
    service = "mariadb"
```

**Metriques collectees:**
- Connexions actives
- Queries par seconde
- Buffer pool usage
- Table locks
- Slow queries

### Output InfluxDB

```toml
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "${INFLUXDB_TOKEN}"
  organization = "${INFLUXDB_ORG}"
  bucket = "${INFLUXDB_BUCKET}"
  timeout = "5s"
```

---

## Configuration InfluxDB

### Variables d'environnement

```ini
# Dans .env
INFLUXDB_USERNAME=admin
INFLUXDB_PASSWORD=votre-mot-de-passe-securise
INFLUXDB_ORG=fug
INFLUXDB_BUCKET=appwrite
INFLUXDB_TOKEN=votre-token-secret-genere
```

### Generation du token

```bash
# Generer un token securise
openssl rand -hex 32
```

### Acces a l'interface InfluxDB

- **URL**: http://localhost:8086
- **Organisation**: fug
- **Bucket**: appwrite

### Retention des donnees

Configuration par defaut: 30 jours

```bash
# Modifier la retention via l'API
influx bucket update \
  --id <bucket-id> \
  --retention 720h  # 30 jours
```

### Requetes utiles (Flux)

**CPU moyen par container:**

```flux
from(bucket: "appwrite")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "docker_container_cpu")
  |> filter(fn: (r) => r._field == "usage_percent")
  |> aggregateWindow(every: 5m, fn: mean)
```

**Memoire utilisee:**

```flux
from(bucket: "appwrite")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "docker_container_mem")
  |> filter(fn: (r) => r._field == "usage_percent")
```

**Health check status:**

```flux
from(bucket: "appwrite")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "http_response")
  |> filter(fn: (r) => r._field == "http_response_code")
```

---

## Dashboard Grafana

### Configuration initiale

1. Acceder a http://localhost:3000
2. Login: admin / admin (changer au premier acces)
3. Ajouter la datasource InfluxDB

### Configuration de la datasource

```json
{
  "name": "InfluxDB-FUG",
  "type": "influxdb",
  "url": "http://influxdb:8086",
  "access": "proxy",
  "jsonData": {
    "version": "Flux",
    "organization": "fug",
    "defaultBucket": "appwrite"
  },
  "secureJsonData": {
    "token": "${INFLUXDB_TOKEN}"
  }
}
```

### Dashboard JSON - FUG Infrastructure

```json
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "id": null,
  "links": [],
  "liveNow": false,
  "panels": [
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 90}
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0},
      "id": 1,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        },
        "showThresholdLabels": false,
        "showThresholdMarkers": true
      },
      "pluginVersion": "10.3.0",
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"docker_container_cpu\")\n  |> filter(fn: (r) => r._field == \"usage_percent\")\n  |> filter(fn: (r) => r.container_name == \"fug-appwrite\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "CPU Appwrite",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null},
              {"color": "yellow", "value": 70},
              {"color": "red", "value": 90}
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0},
      "id": 2,
      "options": {
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        }
      },
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"docker_container_mem\")\n  |> filter(fn: (r) => r._field == \"usage_percent\")\n  |> filter(fn: (r) => r.container_name == \"fug-appwrite\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Memoire Appwrite",
      "type": "gauge"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "thresholds"},
          "mappings": [
            {"options": {"200": {"color": "green", "index": 0, "text": "OK"}}, "type": "value"},
            {"options": {"from": 400, "to": 599, "result": {"color": "red", "index": 1, "text": "ERREUR"}}, "type": "range"}
          ],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {"color": "green", "value": null}
            ]
          }
        }
      },
      "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8},
      "id": 3,
      "options": {
        "colorMode": "background",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "reduceOptions": {
          "calcs": ["lastNotNull"],
          "fields": "",
          "values": false
        },
        "textMode": "auto"
      },
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"http_response\")\n  |> filter(fn: (r) => r.check == \"health\")\n  |> filter(fn: (r) => r._field == \"http_response_code\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Health API",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "thresholds"},
          "mappings": [
            {"options": {"200": {"color": "green", "index": 0, "text": "OK"}}, "type": "value"},
            {"options": {"from": 400, "to": 599, "result": {"color": "red", "index": 1, "text": "ERREUR"}}, "type": "range"}
          ]
        }
      },
      "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8},
      "id": 4,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"http_response\")\n  |> filter(fn: (r) => r.check == \"database\")\n  |> filter(fn: (r) => r._field == \"http_response_code\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Health DB",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "thresholds"},
          "mappings": [
            {"options": {"200": {"color": "green", "index": 0, "text": "OK"}}, "type": "value"},
            {"options": {"from": 400, "to": 599, "result": {"color": "red", "index": 1, "text": "ERREUR"}}, "type": "range"}
          ]
        }
      },
      "gridPos": {"h": 4, "w": 6, "x": 12, "y": 8},
      "id": 5,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"http_response\")\n  |> filter(fn: (r) => r.check == \"cache\")\n  |> filter(fn: (r) => r._field == \"http_response_code\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Health Cache",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "color": {"mode": "thresholds"},
          "mappings": [
            {"options": {"200": {"color": "green", "index": 0, "text": "OK"}}, "type": "value"},
            {"options": {"from": 400, "to": 599, "result": {"color": "red", "index": 1, "text": "ERREUR"}}, "type": "range"}
          ]
        }
      },
      "gridPos": {"h": 4, "w": 6, "x": 18, "y": 8},
      "id": 6,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"http_response\")\n  |> filter(fn: (r) => r.check == \"queue\")\n  |> filter(fn: (r) => r._field == \"http_response_code\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Health Queue",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "custom": {
            "lineWidth": 1,
            "fillOpacity": 20
          },
          "unit": "percent"
        }
      },
      "gridPos": {"h": 8, "w": 24, "x": 0, "y": 12},
      "id": 7,
      "options": {
        "legend": {"displayMode": "list", "placement": "bottom"}
      },
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -1h)\n  |> filter(fn: (r) => r._measurement == \"docker_container_cpu\")\n  |> filter(fn: (r) => r._field == \"usage_percent\")\n  |> filter(fn: (r) => r.container_name =~ /fug-.*/)\n  |> aggregateWindow(every: 1m, fn: mean)",
          "refId": "A"
        }
      ],
      "title": "CPU par Container (1h)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "custom": {
            "lineWidth": 1,
            "fillOpacity": 20
          },
          "unit": "decbytes"
        }
      },
      "gridPos": {"h": 8, "w": 24, "x": 0, "y": 20},
      "id": 8,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -1h)\n  |> filter(fn: (r) => r._measurement == \"docker_container_mem\")\n  |> filter(fn: (r) => r._field == \"usage\")\n  |> filter(fn: (r) => r.container_name =~ /fug-.*/)\n  |> aggregateWindow(every: 1m, fn: mean)",
          "refId": "A"
        }
      ],
      "title": "Memoire par Container (1h)",
      "type": "timeseries"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "unit": "decbytes"
        }
      },
      "gridPos": {"h": 8, "w": 12, "x": 0, "y": 28},
      "id": 9,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"redis\")\n  |> filter(fn: (r) => r._field == \"used_memory\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Redis - Memoire Utilisee",
      "type": "stat"
    },
    {
      "datasource": {
        "type": "influxdb",
        "uid": "influxdb-fug"
      },
      "fieldConfig": {
        "defaults": {
          "unit": "short"
        }
      },
      "gridPos": {"h": 8, "w": 12, "x": 12, "y": 28},
      "id": 10,
      "targets": [
        {
          "query": "from(bucket: \"appwrite\")\n  |> range(start: -5m)\n  |> filter(fn: (r) => r._measurement == \"redis\")\n  |> filter(fn: (r) => r._field == \"connected_clients\")\n  |> last()",
          "refId": "A"
        }
      ],
      "title": "Redis - Clients Connectes",
      "type": "stat"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 39,
  "tags": ["fug", "infrastructure", "appwrite"],
  "templating": {"list": []},
  "time": {"from": "now-1h", "to": "now"},
  "timepicker": {},
  "timezone": "browser",
  "title": "FUG Infrastructure",
  "uid": "fug-infrastructure",
  "version": 1
}
```

### Import du dashboard

1. Dans Grafana, aller dans **Dashboards > Import**
2. Coller le JSON ci-dessus
3. Selectionner la datasource InfluxDB
4. Cliquer sur **Import**

---

## Alertes recommandees

### Configuration des alertes Grafana

#### Alerte CPU eleve

```yaml
name: "CPU Appwrite > 80%"
condition: avg(A) > 80
for: 5m
labels:
  severity: warning
annotations:
  summary: "CPU Appwrite eleve"
  description: "Le CPU du container Appwrite depasse 80% depuis 5 minutes"
```

#### Alerte memoire elevee

```yaml
name: "Memoire Appwrite > 90%"
condition: avg(A) > 90
for: 5m
labels:
  severity: critical
annotations:
  summary: "Memoire Appwrite critique"
  description: "La memoire du container Appwrite depasse 90%"
```

#### Alerte health check

```yaml
name: "Health Check Failed"
condition: last(A) != 200
for: 2m
labels:
  severity: critical
annotations:
  summary: "Health check Appwrite echoue"
  description: "L'endpoint /v1/health ne repond pas correctement"
```

#### Alerte Redis memoire

```yaml
name: "Redis Memoire > 200MB"
condition: last(A) > 209715200
for: 10m
labels:
  severity: warning
annotations:
  summary: "Redis memoire elevee"
  description: "Redis utilise plus de 200MB de memoire"
```

### Canaux de notification

**Configuration Slack:**

```yaml
type: slack
settings:
  url: "https://hooks.slack.com/services/xxx/yyy/zzz"
  recipient: "#fug-alerts"
  username: "FUG Monitoring"
```

**Configuration Email:**

```yaml
type: email
settings:
  addresses: "alerts@example.com"
```

---

## Centralisation des logs

### Configuration des logs Docker

Tous les containers utilisent le driver `json-file`:

```yaml
x-logging: &x-logging
  logging:
    driver: json-file
    options:
      max-size: "10m"
      max-file: "3"
```

### Acces aux logs

```bash
# Logs d'un service specifique
docker compose logs -f appwrite

# Logs de tous les services
docker compose logs -f

# Logs avec timestamp
docker compose logs -f --timestamps

# Derniers 100 logs
docker compose logs --tail=100 appwrite
```

### Integration Loki (optionnel)

Pour une centralisation avancee des logs, ajoutez Loki au stack:

```yaml
# docker-compose.override.yml
services:
  loki:
    image: grafana/loki:2.9.0
    container_name: fug-loki
    ports:
      - "3100:3100"
    volumes:
      - loki-data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - fug-network

  promtail:
    image: grafana/promtail:2.9.0
    container_name: fug-promtail
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./promtail-config.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - fug-network

volumes:
  loki-data:
```

---

## Metriques disponibles

### Metriques Docker

| Metrique | Description | Unite |
|----------|-------------|-------|
| `docker_container_cpu.usage_percent` | CPU utilise | % |
| `docker_container_mem.usage` | Memoire utilisee | bytes |
| `docker_container_mem.usage_percent` | Memoire utilisee | % |
| `docker_container_net.rx_bytes` | Donnees recues | bytes |
| `docker_container_net.tx_bytes` | Donnees envoyees | bytes |
| `docker_container_blkio.io_service_bytes_recursive_read` | Lecture disque | bytes |
| `docker_container_blkio.io_service_bytes_recursive_write` | Ecriture disque | bytes |

### Metriques systeme

| Metrique | Description | Unite |
|----------|-------------|-------|
| `cpu.usage_user` | CPU utilisateur | % |
| `cpu.usage_system` | CPU systeme | % |
| `mem.used` | Memoire utilisee | bytes |
| `mem.available` | Memoire disponible | bytes |
| `disk.used` | Espace disque utilise | bytes |
| `disk.free` | Espace disque libre | bytes |

### Metriques Redis

| Metrique | Description | Unite |
|----------|-------------|-------|
| `redis.used_memory` | Memoire utilisee | bytes |
| `redis.connected_clients` | Clients connectes | count |
| `redis.instantaneous_ops_per_sec` | Operations/sec | ops/s |
| `redis.keyspace_hits` | Cache hits | count |
| `redis.keyspace_misses` | Cache misses | count |
| `redis.expired_keys` | Cles expirees | count |

### Metriques MySQL/MariaDB

| Metrique | Description | Unite |
|----------|-------------|-------|
| `mysql.threads_connected` | Connexions actives | count |
| `mysql.queries` | Total requetes | count |
| `mysql.slow_queries` | Requetes lentes | count |
| `mysql.innodb_buffer_pool_read_requests` | Lectures buffer | count |
| `mysql.innodb_buffer_pool_pages_free` | Pages libres | count |

### Metriques HTTP (Health checks)

| Metrique | Description | Unite |
|----------|-------------|-------|
| `http_response.http_response_code` | Code HTTP | code |
| `http_response.response_time` | Temps de reponse | ms |
| `http_response.content_length` | Taille reponse | bytes |

---

## Commandes utiles

```bash
# Verifier que Telegraf collecte des donnees
docker compose logs telegraf | tail -20

# Requete test InfluxDB
curl -H "Authorization: Token $INFLUXDB_TOKEN" \
  "http://localhost:8086/api/v2/query?org=fug" \
  --data-urlencode 'query=from(bucket:"appwrite") |> range(start:-5m) |> limit(n:10)'

# Verifier la retention InfluxDB
influx bucket list --org fug

# Exporter les dashboards Grafana
curl -H "Authorization: Bearer $GRAFANA_API_KEY" \
  http://localhost:3000/api/dashboards/uid/fug-infrastructure \
  > dashboard-export.json
```

---

*Documentation Monitoring FUG - Janvier 2026*
