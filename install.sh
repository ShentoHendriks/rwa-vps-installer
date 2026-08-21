#!/usr/bin/env bash
set -Eeuo pipefail
DOMAIN="" EMAIL="" REPOSITORY="${PANEL_REPOSITORY:-https://github.com/ShentoHendriks/rwa-vps-panel.git}" GITHUB_TOKEN="${PANEL_GITHUB_TOKEN:-}"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
while [[ $# -gt 0 ]]; do case "$1" in --domain) DOMAIN="$2"; shift 2;; --email) EMAIL="$2"; shift 2;; --repository) REPOSITORY="$2"; shift 2;; *) echo "Usage: sudo ./install.sh --domain panel.example.com --email you@example.com [--repository git-url]"; exit 2;; esac; done
[[ $EUID -eq 0 ]] || { echo 'Run this installer with sudo or as root.'; exit 2; }

# Prompts use the controlling terminal so this works when invoked via curl | sudo bash.
prompt() {
  local variable="$1" label="$2" default="${3:-}" answer
  if [[ -n "$default" ]]; then
    read -r -p "$label [$default]: " answer </dev/tty
    printf -v "$variable" '%s' "${answer:-$default}"
  else
    read -r -p "$label: " answer </dev/tty
    printf -v "$variable" '%s' "$answer"
  fi
}

[[ -n "$DOMAIN" ]] || prompt DOMAIN 'Panel domain (for example panel.example.com)'
[[ -n "$EMAIL" ]] || prompt EMAIL "Email for Let's Encrypt certificate notices"
[[ $DOMAIN =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ && $EMAIL == *@* && $REPOSITORY =~ ^https://github\.com/.+\.git$ ]] || {
  echo 'Enter a valid domain, email address, and HTTPS GitHub repository URL.'; exit 2;
}
. /etc/os-release; [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] || { echo 'Ubuntu 24.04 is required.'; exit 1; }
getent ahosts "$DOMAIN" >/dev/null || { echo "DNS for $DOMAIN does not resolve yet."; exit 1; }
APP=/opt/rwa-vps-panel
apt-get update; DEBIAN_FRONTEND=noninteractive apt-get install -y nginx mariadb-server php8.3-cli php8.3-fpm php8.3-mysql php8.3-xml php8.3-curl php8.3-zip php8.3-mbstring php8.3-gd php8.3-intl composer git nodejs npm certbot python3-certbot-nginx jq ufw unzip acl
if [[ ! -d "$APP/.git" ]]; then
  if [[ -f "$SOURCE_DIR/artisan" && -d "$SOURCE_DIR/.git" ]]; then
    mkdir -p "$APP"
    cp -a "$SOURCE_DIR/." "$APP/"
  else
    [[ -n "$GITHUB_TOKEN" ]] || { read -r -s -p 'GitHub token with read access to the private repository: ' GITHUB_TOKEN </dev/tty; echo >&2; }
    git clone "https://x-access-token:${GITHUB_TOKEN}@${REPOSITORY#https://}" "$APP"
    git -C "$APP" remote set-url origin "$REPOSITORY"
  fi
else
  git -C "$APP" pull --ff-only
fi
cd "$APP"; composer install --no-dev --optimize-autoloader; npm ci; npm run build; cp -n .env.example .env; sed -i "s|^APP_URL=.*|APP_URL=https://$DOMAIN|" .env; sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mariadb/' .env; sed -i 's/^DB_DATABASE=.*/DB_DATABASE=rwa_panel/' .env; sed -i 's/^DB_USERNAME=.*/DB_USERNAME=rwa_panel/' .env; mkdir -p storage/app/provisioning
db_password=$(openssl rand -hex 24); mysql -e "CREATE DATABASE IF NOT EXISTS rwa_panel; CREATE USER IF NOT EXISTS 'rwa_panel'@'localhost' IDENTIFIED BY '$db_password'; GRANT ALL ON rwa_panel.* TO 'rwa_panel'@'localhost';"; sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=$db_password/" .env; php artisan key:generate --force; php artisan migrate --force; chown -R www-data:www-data storage bootstrap/cache
install -m 0750 -o root -g www-data deploy/rwa-panel-provision /usr/local/sbin/rwa-panel-provision; printf 'www-data ALL=(root) NOPASSWD: /usr/local/sbin/rwa-panel-provision [0-9]*\n' >/etc/sudoers.d/rwa-panel; chmod 0440 /etc/sudoers.d/rwa-panel; visudo -cf /etc/sudoers.d/rwa-panel
cp deploy/rwa-panel-worker.service /etc/systemd/system/; systemctl daemon-reload; systemctl enable --now rwa-panel-worker
sed "s/__DOMAIN__/$DOMAIN/g" deploy/nginx-panel.conf >/etc/nginx/sites-available/rwa-panel; ln -sf /etc/nginx/sites-available/rwa-panel /etc/nginx/sites-enabled/rwa-panel; rm -f /etc/nginx/sites-enabled/default; nginx -t; systemctl reload nginx; certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect
ufw allow OpenSSH; ufw allow 'Nginx Full'; ufw --force enable; echo "Installed: https://$DOMAIN/setup"
