---
name: og-new-module
description: Create a new OpenGate module in modules/og (Prisma model, Nest backend, page at /m/<slug>, registries, docs) following modules/og/docs/new-module.md. Use when the user asks to add / create / scaffold a new OG module, feature page or screen for the OpenGate Postiz fork.
argument-hint: "<module-slug> [short description]"
---

# New OpenGate module: $ARGUMENTS

1. Read `modules/og/AGENTS.md` (hard rules) and `modules/og/docs/new-module.md` (recipe + templates) in full.
   If `modules/og` is missing, tell the user to run `./og-setup.sh` and stop.
2. Skim `modules/og/content-hub/` (reference implementation) and the two registries.
3. Clarify with the user only what the recipe cannot decide: what the module stores, who can see / change it
   (members vs admins), env settings, background jobs, whether it needs a hook outside the registries
   ("Needs a fork change" in the recipe: stop and propose the fork change first).
4. Build it with the recipe, step by step: prisma -> backend (dto, repository, service, controller, module) ->
   registry.backend.ts -> frontend (types, hooks, page) -> registry.frontend.tsx -> module README + AGENTS.md
   (modules table, current state) + modules/og/README.md.
5. Verify (recipe step 6): merge Prisma, build backend and frontend from the fork root, route answers 401 without
   login. Then run a subagent that compares the new module with content-hub and similar upstream code.
6. Commit in `modules/og` (`feat(<slug>): ...`), run `node modules/og/scripts/merge-prisma.mjs --remove` so the fork
   stays clean. Do not push or deploy without the user's go-ahead.
