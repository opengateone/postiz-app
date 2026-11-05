#!/usr/bin/env bash
# Sets TIKTOK_ADS_APP_ID / TIKTOK_ADS_APP_SECRET (TikTok for Business > My Apps > App Detail) in .env, the secret read hidden,
# then restarts Postiz so it reads the new env. Run in the stack folder (e.g. ~/postiz-og).
set -euo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo ".env missing"; exit 1; }
read -rp "TikTok Ads App ID: " id
read -rsp "TikTok Ads App Secret: " secret; echo
id=$(printf '%s' "$id" | tr -d '[:space:]'); secret=$(printf '%s' "$secret" | tr -d '[:space:]')
case "$id" in '' | *[!0-9]*) echo "App ID chỉ gồm chữ số."; exit 1;; esac
case "$secret" in '' | *[!0-9A-Za-z]*) echo "Secret chỉ gồm chữ và số."; exit 1;; esac
set_var() { if grep -q "^$1=" .env; then sed -i "s|^$1=.*|$1=$2|" .env; else printf '%s=%s\n' "$1" "$2" >> .env; fi; }
set_var TIKTOK_ADS_APP_ID "$id"
set_var TIKTOK_ADS_APP_SECRET "$secret"
unset secret
echo "Đã lưu. Đang khởi động lại Postiz..."
docker compose up -d < /dev/null 2>&1 | tail -3
echo "Xong. Đợi khoảng 30 giây rồi vào Booking KOL/KOC > Cài đặt > TikTok Ads (GMV Max)."
