# Deploy the OpenGate Postiz fork

Server needs Docker + Compose v2, 4 vCPU / 8 GB RAM recommended, and a domain with HTTPS.

## First install
```bash
# copy this folder (deploy/og) to the server, e.g. /opt/postiz-og
cd /opt/postiz-og
cp .env.example .env && chmod 600 .env       # fill URLs + secrets (openssl rand -hex 32)
./ghcr-login.sh                               # once: classic token with read:packages (the image holds the private modules)
./deploy.sh og-latest                         # pulls the image and starts everything
```
Open `https://<domain>`, create the admin account, then set `DISABLE_REGISTRATION=true` and run `./deploy.sh` again.

## HTTPS reverse proxy (Postiz listens on 127.0.0.1:4007)
Caddy:
```
post.example.com {
    reverse_proxy 127.0.0.1:4007
}
```
Nginx: `proxy_pass http://127.0.0.1:4007;` with `client_max_body_size 1g;` and WebSocket headers
(`Upgrade`, `Connection`) on the server block.

## Update / roll back
The server never builds: GitHub Actions (`.github/workflows/og-image.yml`) builds the image with the private modules and
pushes it to GHCR on every push to `og`, every push to `postiz-og-modules` `main` (its `build-image.yml` starts the
fork workflow) or a manual run. The run summary prints the deploy command.
```bash
./deploy.sh v2.25.1-og.42     # pull (stops here if it fails) -> backup DB -> switch POSTIZ_IMAGE -> up -d -> prune dangling
./deploy.sh v2.25.1-og.41     # roll back to the previous image (restore the DB backup if the schema changed)
```
Tags: `og-<fork sha>-m<modules sha>`, `<upstream>-og.<run>`, `og-latest`. Pin a tag in production.
CI secrets: `OG_MODULES_TOKEN` in the fork (read the modules repo; without it the workflow fails instead of pushing a plain
Postiz image) and `OG_CI_TOKEN` in the modules repo (start the fork workflow).

## Useful
```bash
docker compose logs -f postiz
docker compose --profile tools up -d temporal-ui    # Temporal UI on 127.0.0.1:8080 (SSH tunnel to view)
gunzip -c backups/<file>.sql.gz | docker compose exec -T postiz-postgres psql -U $POSTGRES_USER $POSTGRES_DB   # restore
ssh -N -L 5432:127.0.0.1:5432 <server>             # Postgres on 127.0.0.1:${POSTGRES_PORT:-5432} of the server; DB tools connect to localhost:5432
```
