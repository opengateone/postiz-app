# OpenGate fork of Postiz

Fork of [gitroomhq/postiz-app](https://github.com/gitroomhq/postiz-app) (AGPL-3.0) with the
OpenGate additions (Content Hub, ...). Branch **`og`** is ours; `main` mirrors upstream.

## Remotes
- `origin`   = `git@github.com:opengateone/postiz-app.git` (push here)
- `upstream` = `https://github.com/gitroomhq/postiz-app.git` (fetch only, push disabled)

## Rules (keep upstream merges painless)
1. Our code lives in its own folders:
   - `apps/frontend/src/components/og/**`, `apps/frontend/src/app/(app)/(site)/content-hub/**`
   - `apps/backend/src/api/routes/og/**`
   - `libraries/nestjs-libraries/src/og/**`
   - `apps/orchestrator/src/og/**` (Temporal workflows / activities)
2. Upstream files we touch, a few lines each, marked `// OG:`:
   - `apps/frontend/src/components/layout/top.menu.tsx` (menu item)
   - `apps/backend/src/api/api.module.ts` (controllers)
   - `libraries/nestjs-libraries/src/database/prisma/schema.prisma` (our models at the end, section `// --- OG ---`)
   - orchestrator module registering our workflows
3. Never alter upstream tables or columns; link with `organizationId`.
4. Never reformat / rename upstream files. Do not edit upstream workflows; ours are `og-*.yml`.
5. Follow upstream `CLAUDE.md` (DTO >> Controller >> Service >> Repository, pnpm, Tailwind 3).

## Sync with upstream
```bash
git fetch upstream --tags
git checkout -b sync/<tag> og
git merge <tag>                      # e.g. v2.26.0; rerere remembers resolved conflicts
pnpm install && pnpm run build       # + our tests
git push -u origin sync/<tag>        # CI builds an image -> deploy Staging
# Staging OK -> merge sync/<tag> into og -> deploy Production
```
Sync every 2-4 weeks; read the upstream release notes first (breaking changes happen, e.g. Temporal in v2.12).

## Image and deploy
- CI: `.github/workflows/og-image.yml` on every push to `og` (and tags `og-*`):
  - `ghcr.io/opengateone/postiz-app:og-<sha>`
  - `ghcr.io/opengateone/postiz-app:<upstream-tag>-og.<run>`
  - `ghcr.io/opengateone/postiz-app:og-latest`
- Server: `docker compose -f docker-compose.yaml -f docker-compose.og.yaml up -d`, with
  `POSTIZ_IMAGE=<pinned tag>` in `.env`. Roll back = previous tag + `up -d`.
- Back up Postgres before every image change (schema may change):
  `docker compose exec postiz-postgres pg_dump -U postiz-user postiz-db-local > backup_$(date +%F).sql`

## License
AGPL-3.0: people using this modified version over the network must be able to get its source.
Keep this repository public (or link the source in the app).
