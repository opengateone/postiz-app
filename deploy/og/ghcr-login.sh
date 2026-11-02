#!/usr/bin/env bash
# One-time: lets this server pull the private image ghcr.io/opengateone/postiz-app.
# Token: GitHub > Settings > Developer settings > Personal access tokens (classic), scope read:packages only.
# The token is read hidden and handed to docker on stdin; it is never written to a file here
# (docker keeps the login in ~/.docker/config.json).
set -euo pipefail
read -rp "GitHub username: " user
read -rsp "Token (read:packages): " token; echo
[ -n "$user" ] && [ -n "$token" ] || { echo "username and token are required"; exit 1; }
printf '%s' "$token" | docker login ghcr.io -u "$user" --password-stdin
