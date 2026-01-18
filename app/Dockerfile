# =============================================================================
# FUG App - Dockerfile Multi-Stage (Production)
# =============================================================================
# Build: docker build -t fug-app:latest .
# Run:   docker run -p 80:80 fug-app:latest
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build - Flutter SDK
# -----------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

# Arguments de build
ARG FLUTTER_BUILD_MODE=release
ARG APPWRITE_ENDPOINT=http://localhost/v1
ARG APPWRITE_PROJECT_ID=fug

# Variables d'environnement pour le build
ENV APPWRITE_ENDPOINT=${APPWRITE_ENDPOINT}
ENV APPWRITE_PROJECT_ID=${APPWRITE_PROJECT_ID}

WORKDIR /app

# Copier les fichiers de dependances d'abord (cache Docker)
COPY pubspec.yaml pubspec.lock* ./

# Installer les dependances Flutter
RUN flutter pub get

# Copier le reste du code source
COPY . .

# Build de l'application Flutter pour le web
RUN flutter build web --${FLUTTER_BUILD_MODE} \
    --dart-define=APPWRITE_ENDPOINT=${APPWRITE_ENDPOINT} \
    --dart-define=APPWRITE_PROJECT_ID=${APPWRITE_PROJECT_ID}

# -----------------------------------------------------------------------------
# Stage 2: Serve - Nginx Alpine
# -----------------------------------------------------------------------------
FROM nginx:1.25-alpine AS production

# Labels
LABEL maintainer="FUG Team"
LABEL description="FUG - Find Urban Gatherings - Flutter Web App"
LABEL version="1.0.0"

# Installer curl pour les healthchecks
RUN apk add --no-cache curl

# Supprimer la config nginx par defaut
RUN rm -rf /etc/nginx/conf.d/default.conf

# Copier la configuration nginx personnalisee
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copier les fichiers build depuis le stage precedent
COPY --from=build /app/build/web /usr/share/nginx/html

# Creer un utilisateur non-root pour la securite
RUN addgroup -g 1001 -S nginx-fug && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginx-fug -g nginx-fug nginx-fug && \
    chown -R nginx-fug:nginx-fug /usr/share/nginx/html && \
    chown -R nginx-fug:nginx-fug /var/cache/nginx && \
    chown -R nginx-fug:nginx-fug /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx-fug:nginx-fug /var/run/nginx.pid

# Port expose
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Demarrer nginx
CMD ["nginx", "-g", "daemon off;"]
