#!/usr/bin/env bash
# OG fork: one-shot local setup for a fresh clone of opengateone/postiz-app (branch og).
#
#   git clone -b og git@github.com:opengateone/postiz-app.git && cd postiz-app && ./og-setup.sh
#
# Steps (safe to re-run; only schema.prisma is rewritten, .env is never overwritten):
#   1. checks git / node 22 (stops if another version) / pnpm (installs it if missing) / docker
#   2. clones the private modules repo into modules/og (or pulls it if already there)
#   3. merges the module Prisma models into schema.prisma (never commit that file merged)
#   4. creates .env for local dev (random JWT_SECRET, DB / Redis / Temporal of docker-compose.dev.yaml)
#   5. starts Postgres, Redis and Temporal (docker-compose.dev.yaml)
#   6. pnpm install + prisma db push
#   7. AI context: CLAUDE.local.md (imports modules/og/CLAUDE.md) + a pre-commit guard for schema.prisma
#
# Options: --no-docker  --no-install  --ref <branch of the modules repo, default main>
# Env:     OG_MODULES_REPO (default git@github.com:opengateone/postiz-og-modules.git)
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"

DOCKER=1
INSTALL=1
REF=main
while [ $# -gt 0 ]; do
  case "$1" in
    --no-docker) DOCKER=0 ;;
    --no-install) INSTALL=0 ;;
    --ref) REF="${2:?--ref needs a branch}"; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
  shift
done

REPO_SSH="${OG_MODULES_REPO:-git@github.com:opengateone/postiz-og-modules.git}"
REPO_HTTPS="https://github.com/opengateone/postiz-og-modules.git"
SCHEMA=libraries/nestjs-libraries/src/database/prisma/schema.prisma

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR: %s\033[0m\n' "$*"; exit 1; }

# ---------------------------------------------------------------- 1. tools
step "Checking tools"
command -v git >/dev/null || die "git is missing"
command -v node >/dev/null || die "node is missing (need 22.12+ <23, e.g. 'nvm install 22')"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
[ "$NODE_MAJOR" = 22 ] || die "node $(node -v) found, package.json needs >=22.12 <23. Install it with nvm:
       curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
       . ~/.nvm/nvm.sh && nvm install 22 && nvm use 22      (new shells: nvm alias default 22)
       then re-run ./og-setup.sh"
if ! command -v pnpm >/dev/null; then
  warn "pnpm missing, installing pnpm 10.6.1"
  if command -v corepack >/dev/null; then
    corepack enable && corepack prepare pnpm@10.6.1 --activate
  else
    npm i -g pnpm@10.6.1
  fi
  command -v pnpm >/dev/null || die "could not install pnpm: run 'npm i -g pnpm@10.6.1' (node from nvm needs no sudo)"
fi
if [ "$DOCKER" = 1 ]; then
  command -v docker >/dev/null && docker compose version >/dev/null 2>&1 || die "docker + compose v2 needed (or pass --no-docker)"
fi
echo "git $(git --version | cut -d' ' -f3), node $(node -v), pnpm $(pnpm -v)"

# ---------------------------------------------------------------- 2. modules
step "Private modules -> modules/og"
if [ -d modules/og/.git ]; then
  git -C modules/og fetch origin "$REF" && git -C modules/og checkout "$REF" && git -C modules/og pull --ff-only origin "$REF" \
    || warn "could not update modules/og (local changes?), keeping it as is"
elif [ -e modules/og ]; then
  die "modules/og exists but is not a git checkout; move it away and re-run"
else
  git clone -b "$REF" "$REPO_SSH" modules/og 2>/dev/null \
    || git clone -b "$REF" "$REPO_HTTPS" modules/og \
    || die "cannot clone the modules repo. Ask for read access to opengateone/postiz-og-modules
       (SSH key on GitHub, or 'gh auth login' for HTTPS). Without it the fork runs as plain Postiz."
fi
echo "modules/og @ $(git -C modules/og log -1 --format='%h %s')"

# ---------------------------------------------------------------- 3. prisma merge
step "Merging module Prisma models"
node modules/og/scripts/merge-prisma.mjs

# ---------------------------------------------------------------- 4. .env
step ".env for local dev"
if [ -f .env ]; then
  echo ".env exists, left untouched (compare with .env.example and modules/og/AGENTS.md if something is missing)"
else
  (umask 077 && cp .env.example .env)
  # Upserts KEY="value" lines (works the same on macOS and Linux, unlike sed -i).
  node - "$ROOT" <<'NODE'
const fs = require('fs');
const crypto = require('crypto');
const root = process.argv[2];
const file = `${root}/.env`;
let env = fs.readFileSync(file, 'utf8');
const set = (key, value) => {
  const line = `${key}="${value}"`;
  const re = new RegExp(`^#?\\s*${key}=.*$`, 'm');
  env = re.test(env) ? env.replace(re, line) : `${env.trimEnd()}\n${line}\n`;
};
// Same credentials as docker-compose.dev.yaml
set('DATABASE_URL', 'postgresql://postiz-local:postiz-local-pwd@localhost:5432/postiz-db-local');
set('REDIS_URL', 'redis://localhost:6379');
set('TEMPORAL_ADDRESS', 'localhost:7233');
set('JWT_SECRET', crypto.randomBytes(32).toString('hex'));
set('MAIN_URL', 'http://localhost:4200');
set('FRONTEND_URL', 'http://localhost:4200');
set('NEXT_PUBLIC_BACKEND_URL', 'http://localhost:3000');
set('BACKEND_INTERNAL_URL', 'http://localhost:3000');
set('STORAGE_PROVIDER', 'local');
set('UPLOAD_DIRECTORY', `${root}/.og/uploads`);
set('NOT_SECURED', 'true');
set('IS_GENERAL', 'true');
env += `
# --- OG modules (see modules/og/AGENTS.md) ---
# Content Hub: crawling needs an Apify token; the scheduled crawl stays off unless HUB_SYNC_ENABLED=true
APIFY_TOKEN=""
HUB_SYNC_ENABLED="false"
`;
fs.writeFileSync(file, env);
NODE
  chmod 600 .env
  mkdir -p .og/uploads
  echo ".env created (random JWT_SECRET, local storage in .og/uploads)"
fi

# ---------------------------------------------------------------- 5. services
if [ "$DOCKER" = 1 ]; then
  step "Postgres, Redis, Temporal (docker-compose.dev.yaml)"
  docker compose -f docker-compose.dev.yaml up -d postiz-postgres postiz-redis temporal-postgresql temporal-elasticsearch temporal temporal-ui
  printf 'waiting for Postgres'
  ready=0
  for _ in $(seq 1 30); do
    docker exec postiz-postgres pg_isready -q -U postiz-local 2>/dev/null && { ready=1; break; }
    printf '.'; sleep 2
  done
  echo
  [ "$ready" = 1 ] || die "Postgres not ready on :5432 (docker logs postiz-postgres)"
fi

# ---------------------------------------------------------------- 6. deps + schema
if [ "$INSTALL" = 1 ]; then
  step "pnpm install (also runs prisma generate)"
  pnpm install
  step "prisma db push (creates the og_* tables, never touches upstream ones)"
  pnpm run prisma-db-push
fi

# ---------------------------------------------------------------- 7. AI context + guard
step "AI context and commit guard"
if [ ! -f CLAUDE.local.md ]; then
  cat > CLAUDE.local.md <<'MD'
# Local (not committed): OpenGate fork context for Claude Code
@OG-FORK.md
@modules/og/CLAUDE.md
MD
  echo "CLAUDE.local.md created (Claude Code loads it next to CLAUDE.md)"
elif ! grep -q 'modules/og/CLAUDE.md' CLAUDE.local.md; then
  printf '\n@OG-FORK.md\n@modules/og/CLAUDE.md\n' >> CLAUDE.local.md
  echo "CLAUDE.local.md: imports added"
fi

HOOK="$(git rev-parse --git-path hooks)/pre-commit"
if [ ! -f "$HOOK" ]; then
  cat > "$HOOK" <<'SH'
#!/usr/bin/env bash
# OG fork guard (installed by og-setup.sh): never commit schema.prisma with the module models merged in.
f=libraries/nestjs-libraries/src/database/prisma/schema.prisma
if git diff --cached --name-only | grep -qx "$f" && git show ":$f" | grep -q 'OG MODULES'; then
  echo "schema.prisma contains the OG module models. Run: node modules/og/scripts/merge-prisma.mjs --remove && git add $f"
  exit 1
fi
if [ -s .og/rebranded.txt ]; then
  echo "Working tree is rebranded (modules/og/scripts/rebrand.mjs). Run: node modules/og/scripts/rebrand.mjs --remove"
  exit 1
fi
SH
  chmod +x "$HOOK"
  echo "pre-commit guard installed"
elif ! grep -q 'rebranded.txt' "$HOOK"; then
  warn "$HOOK already exists: add the schema.prisma / rebrand checks from og-setup.sh by hand"
fi

step "Done"
cat <<TXT
  pnpm run dev                     # frontend http://localhost:4200, backend http://localhost:3000
  Temporal UI                      http://localhost:8080
  Content Hub                      http://localhost:4200/m/content-hub (after sign-up)

  Module code:   modules/og (own git repo: commit and push there)
  AI docs:       modules/og/AGENTS.md, modules/og/CLAUDE.md, modules/og/docs/
  Update later:  ./og-setup.sh --no-docker   (pulls modules, re-merges Prisma, reinstalls)
TXT
