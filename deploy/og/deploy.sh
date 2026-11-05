#!/usr/bin/env bash
# Usage: ./deploy.sh [image-tag | full-image]   e.g. ./deploy.sh v2.25.1-og.42   or   ./deploy.sh og-latest
# Images are built by GitHub Actions (postiz-og-modules: build-image.yml) and pulled here: the server never builds.
# Pulls the image first (nothing changes if that fails), backs up Postgres, switches POSTIZ_IMAGE, restarts Postiz.
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo ".env missing (copy .env.example)"; exit 1; }
set -a; . ./.env; set +a

DEFAULT_REPO=ghcr.io/opengateone/postiz-og
image="${POSTIZ_IMAGE:-$DEFAULT_REPO:og-latest}"
if [ "${1:-}" != "" ]; then
  case "$1" in
    */*) image="$1" ;;
    *)
      # a locally built image (no registry in its name) switches to the GHCR repository
      repo="${POSTIZ_IMAGE%:*}"
      case "$repo" in */*) ;; *) repo="$DEFAULT_REPO" ;; esac
      image="$repo:$1"
      ;;
  esac
fi

# private package: run ./ghcr-login.sh once on the server
docker pull "$image" || { echo "pull failed for $image (logged in to ghcr.io? see ./ghcr-login.sh)"; exit 1; }

mkdir -p backups
if docker compose ps --status running postiz-postgres | grep -q postiz-postgres; then
  file="backups/postiz_$(date +%Y%m%d_%H%M%S).sql.gz"
  docker compose exec -T postiz-postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" < /dev/null | gzip > "$file"
  echo "backup: $file"
fi

if [ "$image" != "${POSTIZ_IMAGE:-}" ]; then
  echo "previous image: ${POSTIZ_IMAGE:-none} (roll back: ./deploy.sh ${POSTIZ_IMAGE:-<tag>})"
  sed -i.bak "s|^POSTIZ_IMAGE=.*|POSTIZ_IMAGE=$image|" .env && rm -f .env.bak
  grep -q '^POSTIZ_IMAGE=' .env || echo "POSTIZ_IMAGE=$image" >> .env
  echo "image: $image"
fi
# the old value was exported with the rest of .env above and would win over the file in compose
export POSTIZ_IMAGE="$image"

docker compose up -d < /dev/null
docker compose ps
# old images are ~5 GB each: keep the running one and the tagged ones, drop the dangling layers
docker image prune -f > /dev/null || true
