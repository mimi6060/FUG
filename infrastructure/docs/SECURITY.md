# Securite - Infrastructure FUG

Documentation complete sur la securite de l'infrastructure FUG avec Appwrite Self-Hosted.

## Table des matieres

- [Vue d'ensemble](#vue-densemble)
- [Gestion des secrets](#gestion-des-secrets)
- [Rotation des cles](#rotation-des-cles)
- [Firewall et ports](#firewall-et-ports)
- [Configuration HTTPS/TLS](#configuration-httpstls)
- [Rate limiting Appwrite](#rate-limiting-appwrite)
- [Audit logs](#audit-logs)
- [Bonnes pratiques](#bonnes-pratiques)
- [Checklist de securite](#checklist-de-securite)

---

## Vue d'ensemble

### Niveaux de securite

| Niveau | Environnement | Description |
|--------|---------------|-------------|
| Minimal | Developpement | Protection de base, debug active |
| Standard | Test | Protection intermediaire |
| Renforce | Production | Protection maximale, HTTPS obligatoire |

### Composants de securite

```
COUCHES DE SECURITE
====================

[Internet]
    |
    v
+-------------------+
| FIREWALL          | <-- UFW / iptables
| Ports 80, 443     |
+-------------------+
    |
    v
+-------------------+
| TRAEFIK           | <-- TLS termination
| - HTTPS           |     Rate limiting
| - Certificats     |     Headers securite
+-------------------+
    |
    v
+-------------------+
| APPWRITE          | <-- Authentification
| - Auth            |     Autorisation
| - Rate limiting   |     Validation
| - Audit logs      |
+-------------------+
    |
    v
+-------------------+
| DONNEES           | <-- Chiffrement
| - MariaDB         |     Acces controle
| - Redis           |
| - Volumes         |
+-------------------+
```

---

## Gestion des secrets

### Secrets critiques

| Secret | Variable | Criticite | Rotation |
|--------|----------|-----------|----------|
| Cle OpenSSL | `_APP_OPENSSL_KEY_V1` | CRITIQUE | Annuel |
| Secret Executor | `_APP_EXECUTOR_SECRET` | CRITIQUE | Semestriel |
| Mot de passe DB Root | `MYSQL_ROOT_PASSWORD` | CRITIQUE | Annuel |
| Mot de passe DB User | `MYSQL_PASSWORD` | HAUTE | Semestriel |
| Token InfluxDB | `INFLUXDB_TOKEN` | MOYENNE | Annuel |

### Generation des secrets

```bash
# Cle OpenSSL (128 bits minimum)
openssl rand -hex 64

# Secret Executor (256 bits)
openssl rand -hex 32

# Mot de passe securise
openssl rand -base64 32 | tr -d '=' | head -c 32

# Token API
openssl rand -hex 48
```

### Stockage des secrets

#### Methode 1: Fichier .env (Developpement uniquement)

```ini
# .env - NE JAMAIS COMMITER
_APP_OPENSSL_KEY_V1=abc123...
_APP_EXECUTOR_SECRET=def456...
MYSQL_ROOT_PASSWORD=ghi789...
```

**Securisation du fichier:**

```bash
# Permissions restrictives
chmod 600 .env

# Ajouter au .gitignore
echo ".env" >> .gitignore

# Verifier qu'il n'est pas suivi
git status --ignored | grep .env
```

#### Methode 2: Variables d'environnement systeme (Recommande)

```bash
# Ajouter dans /etc/environment ou ~/.bashrc
export _APP_OPENSSL_KEY_V1="votre-cle-secrete"
export _APP_EXECUTOR_SECRET="votre-secret"
export MYSQL_ROOT_PASSWORD="votre-mot-de-passe"

# Recharger
source ~/.bashrc
```

#### Methode 3: Docker Secrets (Production)

```bash
# Creer les secrets
echo "votre-cle-secrete" | docker secret create app_openssl_key -
echo "votre-secret" | docker secret create executor_secret -

# Utilisation dans docker-compose.yml
services:
  appwrite:
    secrets:
      - app_openssl_key
      - executor_secret
    environment:
      _APP_OPENSSL_KEY_V1_FILE: /run/secrets/app_openssl_key

secrets:
  app_openssl_key:
    external: true
  executor_secret:
    external: true
```

#### Methode 4: HashiCorp Vault (Enterprise)

```bash
# Stocker dans Vault
vault kv put secret/fug/appwrite \
    openssl_key="votre-cle" \
    executor_secret="votre-secret"

# Recuperer dans les scripts
vault kv get -field=openssl_key secret/fug/appwrite
```

### Fichiers sensibles a proteger

```bash
# Fichiers a NE JAMAIS commiter
.env
.env.*
!.env.example
*.pem
*.key
*.p12
credentials.json
secrets/
```

---

## Rotation des cles

### Procedure de rotation OpenSSL Key

**ATTENTION**: Cette operation impacte les donnees chiffrees existantes.

```bash
#!/bin/bash
# rotate-openssl-key.sh

echo "=== ROTATION CLE OPENSSL ==="
echo "ATTENTION: Sauvegarder avant de continuer!"
read -p "Continuer? [y/N] " confirm
[ "$confirm" != "y" ] && exit 0

# 1. Sauvegarder l'ancienne cle
OLD_KEY=$(grep _APP_OPENSSL_KEY_V1 .env | cut -d= -f2)
echo "OLD_KEY: $OLD_KEY" >> .keys-backup-$(date +%Y%m%d).txt

# 2. Generer nouvelle cle
NEW_KEY=$(openssl rand -hex 64)

# 3. Backup complet
make backup

# 4. Arreter les services
make down

# 5. Mettre a jour la cle (garder l'ancienne pour migration)
# Appwrite supporte plusieurs cles pour la migration
sed -i "s/_APP_OPENSSL_KEY_V1=.*/_APP_OPENSSL_KEY_V1=$NEW_KEY/" .env
echo "_APP_OPENSSL_KEY_V2=$OLD_KEY" >> .env

# 6. Redemarrer
make up

# 7. Verifier le fonctionnement
make health

echo "=== ROTATION TERMINEE ==="
echo "Nouvelle cle: $NEW_KEY"
```

### Procedure de rotation mot de passe DB

```bash
#!/bin/bash
# rotate-db-password.sh

NEW_PASSWORD=$(openssl rand -base64 24 | tr -d '=')

# 1. Se connecter a MariaDB
docker compose exec mariadb mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
ALTER USER 'appwrite'@'%' IDENTIFIED BY '$NEW_PASSWORD';
FLUSH PRIVILEGES;
EOF

# 2. Mettre a jour .env
sed -i "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=$NEW_PASSWORD/" .env
sed -i "s/_APP_DB_PASS=.*/_APP_DB_PASS=$NEW_PASSWORD/" .env

# 3. Redemarrer Appwrite
docker compose restart appwrite

# 4. Verifier
make health
```

### Calendrier de rotation

| Secret | Frequence | Prochaine rotation |
|--------|-----------|-------------------|
| Cle OpenSSL | 12 mois | YYYY-MM-DD |
| Secret Executor | 6 mois | YYYY-MM-DD |
| Mot de passe DB | 6 mois | YYYY-MM-DD |
| Tokens API | 3 mois | YYYY-MM-DD |

---

## Firewall et ports

### Configuration UFW (Ubuntu)

```bash
# Installation
sudo apt install ufw

# Regles de base
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH (adapter le port si different)
sudo ufw allow 22/tcp comment 'SSH'

# HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Activer le firewall
sudo ufw enable

# Verifier le statut
sudo ufw status verbose
```

### Configuration iptables (Avance)

```bash
#!/bin/bash
# firewall-rules.sh

# Reset
iptables -F
iptables -X

# Politique par defaut
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Connexions etablies
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Docker (reseau interne)
iptables -A INPUT -i docker0 -j ACCEPT
iptables -A INPUT -i br-+ -j ACCEPT

# Sauvegarder
iptables-save > /etc/iptables/rules.v4
```

### Ports par environnement

#### Production

| Port | Direction | Service | Status |
|------|-----------|---------|--------|
| 22 | Entrant | SSH | Ouvert (IP restreintes) |
| 80 | Entrant | HTTP | Ouvert (redirect 443) |
| 443 | Entrant | HTTPS | Ouvert |
| 3306 | - | MariaDB | FERME |
| 6379 | - | Redis | FERME |
| 8080 | - | Traefik | FERME |

#### Developpement

| Port | Direction | Service | Status |
|------|-----------|---------|--------|
| 80 | Entrant | HTTP | Ouvert |
| 443 | Entrant | HTTPS | Ouvert |
| 3306 | Entrant | MariaDB | Ouvert (local) |
| 6379 | Entrant | Redis | Ouvert (local) |
| 8080 | Entrant | Traefik | Ouvert |
| 8081 | Entrant | Adminer | Ouvert |
| 8082 | Entrant | Redis Commander | Ouvert |
| 8025 | Entrant | Mailhog | Ouvert |

---

## Configuration HTTPS/TLS

### Certificats Let's Encrypt (Production)

**Configuration Traefik pour ACME:**

```yaml
# docker-compose.prod.yml
services:
  traefik:
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      # Let's Encrypt
      - --certificatesresolvers.letsencrypt.acme.httpchallenge=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
      - --certificatesresolvers.letsencrypt.acme.email=admin@example.com
      - --certificatesresolvers.letsencrypt.acme.storage=/certificates/acme.json
      # Redirection HTTP -> HTTPS
      - --entrypoints.web.http.redirections.entrypoint.to=websecure
      - --entrypoints.web.http.redirections.entrypoint.scheme=https
    labels:
      - "traefik.http.routers.appwrite-secure.tls.certresolver=letsencrypt"
```

### Headers de securite

**Configuration Traefik:**

```yaml
# Middleware securite
labels:
  - "traefik.http.middlewares.security-headers.headers.stsSeconds=31536000"
  - "traefik.http.middlewares.security-headers.headers.stsIncludeSubdomains=true"
  - "traefik.http.middlewares.security-headers.headers.stsPreload=true"
  - "traefik.http.middlewares.security-headers.headers.forceSTSHeader=true"
  - "traefik.http.middlewares.security-headers.headers.contentTypeNosniff=true"
  - "traefik.http.middlewares.security-headers.headers.browserXssFilter=true"
  - "traefik.http.middlewares.security-headers.headers.referrerPolicy=strict-origin-when-cross-origin"
  - "traefik.http.middlewares.security-headers.headers.frameDeny=true"
```

### Variables Appwrite HTTPS

```ini
# Production
_APP_OPTIONS_FORCE_HTTPS=enabled
_APP_DOMAIN=votre-domaine.com
_APP_DOMAIN_TARGET=votre-domaine.com
```

### Verification du certificat

```bash
# Verifier le certificat
openssl s_client -connect votre-domaine.com:443 -servername votre-domaine.com

# Verifier l'expiration
echo | openssl s_client -connect votre-domaine.com:443 2>/dev/null | \
    openssl x509 -noout -dates

# Test SSL Labs
# https://www.ssllabs.com/ssltest/analyze.html?d=votre-domaine.com
```

---

## Rate limiting Appwrite

### Configuration Appwrite

```ini
# Activer la protection anti-abus
_APP_OPTIONS_ABUSE=enabled

# Limites GraphQL
_APP_GRAPHQL_MAX_BATCH_SIZE=10
_APP_GRAPHQL_MAX_COMPLEXITY=250
_APP_GRAPHQL_MAX_DEPTH=3

# Limites de stockage
_APP_STORAGE_LIMIT=30000000           # 30MB par fichier
_APP_STORAGE_PREVIEW_LIMIT=20000000   # 20MB pour previews

# Limites fonctions
_APP_FUNCTIONS_SIZE_LIMIT=30000000    # 30MB code
_APP_FUNCTIONS_TIMEOUT=900            # 15 minutes
_APP_FUNCTIONS_BUILD_TIMEOUT=900      # 15 minutes
```

### Rate limiting Traefik

```yaml
# Middleware rate limit
labels:
  # Limite globale: 100 req/s avec burst de 50
  - "traefik.http.middlewares.ratelimit.ratelimit.average=100"
  - "traefik.http.middlewares.ratelimit.ratelimit.burst=50"
  - "traefik.http.middlewares.ratelimit.ratelimit.period=1s"
  # Appliquer au router
  - "traefik.http.routers.appwrite.middlewares=ratelimit"
```

### Limites recommandees par endpoint

| Endpoint | Limite | Burst | Periode |
|----------|--------|-------|---------|
| `/v1/account` | 30 | 10 | 1min |
| `/v1/databases` | 100 | 50 | 1min |
| `/v1/storage` | 50 | 20 | 1min |
| `/v1/functions` | 20 | 10 | 1min |
| `/v1/graphql` | 30 | 10 | 1min |

---

## Audit logs

### Logs Appwrite

Appwrite genere automatiquement des logs d'audit pour:
- Connexions/deconnexions
- Creation/modification de ressources
- Acces aux documents
- Execution de fonctions
- Erreurs d'authentification

### Configuration de retention

```ini
# Retention des logs d'audit (14 jours par defaut)
_APP_MAINTENANCE_RETENTION_AUDIT=1209600

# Retention des logs d'abus (24h)
_APP_MAINTENANCE_RETENTION_ABUSE=86400
```

### Acces aux logs

```bash
# Logs Docker
docker compose logs appwrite-worker-audits

# Exporter les logs
docker compose logs --no-color appwrite > appwrite-logs-$(date +%Y%m%d).log
```

### Centralisation des logs

**Configuration pour envoi vers Syslog:**

```yaml
# docker-compose.yml
x-logging: &x-logging
  logging:
    driver: syslog
    options:
      syslog-address: "tcp://syslog-server:514"
      tag: "fug-{{.Name}}"
```

### Alertes sur evenements securite

Evenements a monitorer:
- Echecs d'authentification repetes (> 5 en 1min)
- Tentatives d'acces non autorise
- Modifications de permissions
- Creation de nouveaux administrateurs
- Acces depuis nouvelles IPs

---

## Bonnes pratiques

### Principe du moindre privilege

```ini
# Restreindre l'acces console
_APP_CONSOLE_WHITELIST_ROOT=enabled
_APP_CONSOLE_WHITELIST_EMAILS=admin@example.com
_APP_CONSOLE_WHITELIST_IPS=192.168.1.0/24
```

### Isolation des environnements

- Separer dev/test/prod physiquement
- Utiliser des credentials differents par environnement
- Ne jamais copier des donnees prod vers dev

### Mises a jour de securite

```bash
# Verifier les mises a jour des images
docker compose pull

# Mettre a jour Appwrite
make pull
make down
make up

# Verifier les CVE
docker scan appwrite/appwrite:latest
```

### Sauvegarde et recuperation

- Backups chiffres
- Test de restauration mensuel
- Procedure de recuperation documentee

---

## Checklist de securite

### Pre-deploiement

- [ ] Secrets generes avec `openssl rand`
- [ ] Fichier `.env` non commite (`.gitignore`)
- [ ] Permissions fichier `.env` restrictives (600)
- [ ] Variables production differentes de dev
- [ ] Mots de passe uniques par service

### Configuration

- [ ] `_APP_OPTIONS_FORCE_HTTPS=enabled` (prod)
- [ ] `_APP_OPTIONS_ABUSE=enabled` (prod)
- [ ] Whitelist console configuree
- [ ] Rate limiting active
- [ ] Certificats SSL valides

### Reseau

- [ ] Firewall configure (UFW/iptables)
- [ ] Seuls ports 80/443 exposes (prod)
- [ ] SSH avec cle uniquement
- [ ] Pas d'acces direct a MariaDB/Redis (prod)

### Monitoring

- [ ] Logs centralises
- [ ] Alertes configurees
- [ ] Monitoring des echecs auth
- [ ] Scan vulnerabilites periodique

### Maintenance

- [ ] Calendrier de rotation des cles
- [ ] Procedure de mise a jour documentee
- [ ] Backups testes
- [ ] Plan de recuperation valide

### Audit annuel

- [ ] Revue des acces
- [ ] Revue des permissions
- [ ] Test de penetration
- [ ] Mise a jour documentation

---

## Contacts securite

En cas d'incident de securite:

1. Isoler le systeme affecte
2. Collecter les logs
3. Contacter l'equipe securite
4. Documenter l'incident
5. Post-mortem et correctifs

---

*Documentation Securite FUG - Janvier 2026*
