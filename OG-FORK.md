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
   - `modules/og/branding/`: name, logos, favicons; `node modules/og/scripts/rebrand.mjs` swaps the Postiz name / logos /
     postiz.com links in the working tree at build time (CI does it; `--remove` restores the upstream files)
2. Hooks in upstream files, a few lines each, marked `OG fork`:
   - `tsconfig.base.json`: alias `@og/*` -> `modules/og/*`, fallback `modules/og-empty/*`
   - `apps/backend/src/api/api.module.ts`: imports / controllers from `@og/registry.backend`
   - `apps/frontend/src/components/layout/top.menu.tsx`: `...ogMenuItems`
   - `apps/frontend/tailwind.config.cjs`: `../../modules/og/**` in `content`
   - `apps/frontend/next.config.js` + `Dockerfile.dev`: `OG_SKIP_TYPECHECK=true` in the image build skips next build's
     type check (its memory peak killed builds on the 8 GB server); run `tsc` before committing instead
   - `apps/frontend/src/components/media/media.component.tsx`: category filter of the media library
     (`ogMediaCategories`, component `components/og/og.media.categories.tsx`)
   - `apps/frontend/src/app/(app)/(site)/analytics/page.tsx`: `<OgAnalytics>` tabs around `PlatformAnalytics`
     (`ogAnalyticsTabs`, component `components/og/og.analytics.tsx`)
   - `apps/backend/src/services/auth/auth.service.ts` (`loginOrRegisterProvider`, `checkExists`, `ogLocalAccount`): with `DISABLE_REGISTRATION=true`,
     a Google / provider sign-in with no linked account uses the LOCAL account with the same email (accounts created by
     an admin in `modules/og/accounts`); without one the sign-in is still refused. `OG_SINGLE_WORKSPACE=true`: no new
     workspace after the first (`canRegister`), and a new provider account from a team invite sent to its email joins
     only the inviting workspace (`OG_INVITED_MEMBERS` from `modules/og/accounts`, `@Optional`)
   - `apps/backend/src/api/routes/users.controller.ts` (`deleteAccount`, `getDeleteAccountInfo`) +
     `apps/frontend/src/components/settings/delete-account.component.tsx`: `OG_SINGLE_WORKSPACE=true` turns off
     "Delete account" (403, button hidden), since deleting the owner deletes the shared workspace and drops its members
   - `README.md`: OpenGate install block at the top (`<!-- OG fork -->` ... `<!-- /OG fork -->`)
   - new files: `apps/frontend/src/app/(app)/(site)/m/[...slug]/page.tsx`, `apps/frontend/src/components/og/`, `og-setup.sh`,
     `.claude/skills/og-new-module/` (Claude Code skill: new module from `modules/og/docs/new-module.md`)
3. Never alter upstream tables or columns; link with `organizationId`. Never commit the merged `schema.prisma`
   or rebranded files (pre-commit hook from `og-setup.sh` blocks both).
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
Servers never build images (a build on the 8 GB `og` host ran it out of memory twice): GitHub Actions builds, servers pull.
- CI: `postiz-og-modules/.github/workflows/build-image.yml`, on every push to the modules `main` and by hand
  (`gh workflow run build-image.yml -R opengateone/postiz-og-modules [-f fork_ref=<branch|sha>]`, needed after a
  fork-only change). It checks out this public fork (`og`) and the modules into `modules/og`, merges the Prisma models,
  rebrands, builds `Dockerfile.dev` and pushes the private package `ghcr.io/opengateone/postiz-og` with the modules
  repo's own `GITHUB_TOKEN` (no extra secret):
  - `og-<fork sha>-m<modules sha>`, `<upstream-tag>-og.<run>` (printed in the run summary as the deploy command), `og-latest`
- `.github/workflows/og-image.yml` here is manual only (plain Postiz with `allow_plain`, or an OG build into
  `ghcr.io/opengateone/postiz-app` if secret `OG_MODULES_TOKEN` is ever set).
- Server (`deploy/og/`): `./ghcr-login.sh` once (classic token, `read:packages`: the package is private because the
  image holds the private modules), then `./deploy.sh <tag>`: pull (nothing changes if it fails) -> `pg_dump` backup ->
  `POSTIZ_IMAGE=<image>` in `.env` -> `up -d` -> prune dangling images. Roll back = `./deploy.sh <previous tag>`.

## License
AGPL-3.0. Our modules are built into this image, so they are covered too: the source (fork + modules) is owed to
people who use this Postiz over the network and ask for it. It does not have to be published to everyone, so the
modules repo stays private. Do not give the app to outside users without being ready to hand them the source.
