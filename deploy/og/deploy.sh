#!/usr/bin/env bash
# Usage: ./deploy.sh [image-tag]   e.g. ./deploy.sh v2.25.1-og.3
# Backs up Postgres, switches POSTIZ_IMAGE (if a tag is given), pulls and restarts Postiz.
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo ".env missing (copy .env.example)"; exit 1; }
set -a; . ./.env; set +a

mkdir -p backups
if docker compose ps --status running postiz-postgres | grep -q postiz-postgres; then
  file="backups/postiz_$(date +%Y%m%d_%H%M%S).sql.gz"
  docker compose exec -T postiz-postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$file"
  echo "backup: $file"
fi

if [ "${1:-}" != "" ]; then
  image="${POSTIZ_IMAGE%:*}:$1"
  sed -i.bak "s|^POSTIZ_IMAGE=.*|POSTIZ_IMAGE=$image|" .env && rm -f .env.bak
  echo "image: $image"
fi

docker compose pull postiz
docker compose up -d
docker compose ps
