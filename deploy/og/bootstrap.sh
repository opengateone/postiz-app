#!/usr/bin/env bash
# First install: create .env with random secrets, then deploy.
# Usage: ./bootstrap.sh <public-url> [image]
#   ./bootstrap.sh http://203.0.113.10:4007          # test over HTTP on the IP (opens port 4007)
#   ./bootstrap.sh https://post.example.com          # behind an HTTPS reverse proxy
set -euo pipefail
cd "$(dirname "$0")"
url="${1:?public url, e.g. http://<server-ip>:4007}"; url="${url%/}"
[ -f .env ] && { echo ".env already exists, not overwriting. Use ./deploy.sh"; exit 1; }
cp .env.example .env && chmod 600 .env
set_env() { sed -i "s|^$1=.*|$1=$2|" .env; }
set_env MAIN_URL "$url"
set_env FRONTEND_URL "$url"
set_env NEXT_PUBLIC_BACKEND_URL "$url/api"
set_env JWT_SECRET "$(openssl rand -hex 32)"
set_env POSTGRES_PASSWORD "$(openssl rand -hex 24)"
set_env TEMPORAL_DB_PASSWORD "$(openssl rand -hex 24)"
[ -n "${2:-}" ] && set_env POSTIZ_IMAGE "$2"
if [[ "$url" == http://* ]]; then
  set_env POSTIZ_BIND 0.0.0.0
  set_env NOT_SECURED true
  echo "WARNING: plain HTTP test mode (port open, NOT_SECURED=true). Social OAuth needs HTTPS."
fi
echo ".env created (secrets generated, file mode 600)"
./deploy.sh
