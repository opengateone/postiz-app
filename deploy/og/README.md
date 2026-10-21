# Deploy the OpenGate Postiz fork

Server needs Docker + Compose v2, 4 vCPU / 8 GB RAM recommended, and a domain with HTTPS.

## First install
```bash
# copy this folder (deploy/og) to the server, e.g. /opt/postiz-og
cd /opt/postiz-og
cp .env.example .env && chmod 600 .env       # fill URLs + secrets (openssl rand -hex 32)
echo <github-token-read:packages> | docker login ghcr.io -u <github-user> --password-stdin   # only if the package is private
./deploy.sh                                   # pulls the image in POSTIZ_IMAGE and starts everything
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
```bash
./deploy.sh v2.25.1-og.4      # backup DB -> switch tag -> pull -> up -d
./deploy.sh v2.25.1-og.3      # roll back to the previous image (restore the DB backup if the schema changed)
```
Tags come from the GitHub Actions run (`og-<sha>`, `<upstream>-og.<run>`, `og-latest`). Pin a tag in production.

## Useful
```bash
docker compose logs -f postiz
docker compose --profile tools up -d temporal-ui    # Temporal UI on 127.0.0.1:8080 (SSH tunnel to view)
gunzip -c backups/<file>.sql.gz | docker compose exec -T postiz-postgres psql -U $POSTGRES_USER $POSTGRES_DB   # restore
```
