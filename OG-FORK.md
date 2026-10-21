# OpenGate fork of Postiz

Fork of [gitroomhq/postiz-app](https://github.com/gitroomhq/postiz-app) (AGPL-3.0) with the
OpenGate additions (Content Hub, ...). Branch **`og`** is ours; `main` mirrors upstream.

## Remotes
- `origin`   = `git@github.com:opengateone/postiz-app.git` (push here)
- `upstream` = `https://github.com/gitroomhq/postiz-app.git` (fetch only, push disabled)

## Rules (keep upstream merges painless)
1. Our features live in the **private** repo `opengateone/postiz-og-modules`, checked out at `modules/og/`
   (gitignored here). `modules/og-empty/` is the fallback: without the private repo the fork builds as plain Postiz.
   - `modules/og/registry.backend.ts`: Nest modules + controllers (`ogBackendModules`, `ogAuthenticatedControllers`, `ogPublicControllers`)
   - `modules/og/registry.frontend.tsx`: sidebar items (`ogMenuItems`) + pages (`ogPages`, served at `/m/<slug>`)
   - `modules/og/<module>/prisma/*.prisma`: models, merged into the Postiz schema at build time by
     `node modules/og/scripts/merge-prisma.mjs` (CI does it; `--remove` restores the upstream schema)
2. Hooks in upstream files, a few lines each, marked `OG fork`:
   - `tsconfig.base.json`: alias `@og/*` -> `modules/og/*`, fallback `modules/og-empty/*`
   - `apps/backend/src/api/api.module.ts`: imports / controllers from `@og/registry.backend`
   - `apps/frontend/src/components/layout/top.menu.tsx`: `...ogMenuItems`
   - `apps/frontend/tailwind.config.cjs`: `../../modules/og/**` in `content`
   - `README.md`: OpenGate install block at the top (`<!-- OG fork -->` ... `<!-- /OG fork -->`)
   - new files: `apps/frontend/src/app/(app)/(site)/m/[...slug]/page.tsx`, `apps/frontend/src/components/og/`, `og-setup.sh`,
     `.claude/skills/og-new-module/` (Claude Code skill: new module from `modules/og/docs/new-module.md`)
3. Never alter upstream tables or columns; link with `organizationId`. Never commit the merged `schema.prisma`.
4. Never reformat / rename upstream files. Do not edit upstream workflows; ours are `og-*.yml`.
5. Follow upstream `CLAUDE.md` (DTO >> Controller >> Service >> Repository, pnpm, Tailwind 3).

## Local dev with the modules
```bash
git clone -b og git@github.com:opengateone/postiz-app.git && cd postiz-app
./og-setup.sh            # modules/og clone, Prisma merge, .env, docker-compose.dev services, pnpm install, db push
pnpm run dev             # http://localhost:4200
```
`og-setup.sh` is safe to re-run (`--no-docker`, `--no-install`, `--ref <modules branch>`): it pulls the modules and
re-merges Prisma, never overwrites `.env`. It also creates `CLAUDE.local.md` (gitignored, imports `OG-FORK.md` and
`modules/og/CLAUDE.md` for Claude Code) and a pre-commit hook that refuses a merged `schema.prisma`.
AI context for the modules: `modules/og/AGENTS.md`, `modules/og/docs/`.

Manual equivalent: `git clone git@github.com:opengateone/postiz-og-modules.git modules/og`,
`node modules/og/scripts/merge-prisma.mjs`, `pnpm install`; before committing in the fork run
`node modules/og/scripts/merge-prisma.mjs --remove`.

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
- CI: `.github/workflows/og-image.yml` on every push to `og` (and tags `og-*`). It checks out
  `opengateone/postiz-og-modules` (secret `OG_MODULES_TOKEN`: fine-grained token, Contents read-only on that repo;
  branch from variable `OG_MODULES_REF`, default `main`) and merges the Prisma models. Pushing the modules repo does
  not build: re-run the workflow (Actions > OG Build Image > Run workflow).
  - `ghcr.io/opengateone/postiz-app:og-<sha>`
  - `ghcr.io/opengateone/postiz-app:<upstream-tag>-og.<run>`
  - `ghcr.io/opengateone/postiz-app:og-latest`
- Server: `docker compose -f docker-compose.yaml -f docker-compose.og.yaml up -d`, with
  `POSTIZ_IMAGE=<pinned tag>` in `.env`. Roll back = previous tag + `up -d`.
- Back up Postgres before every image change (schema may change):
  `docker compose exec postiz-postgres pg_dump -U postiz-user postiz-db-local > backup_$(date +%F).sql`

## License
AGPL-3.0. Our modules are built into this image, so they are covered too: the source (fork + modules) is owed to
people who use this Postiz over the network and ask for it. It does not have to be published to everyone, so the
modules repo stays private. Do not give the app to outside users without being ready to hand them the source.
