#!/usr/bin/env bash
set -Eeuo pipefail

VERSION=v1.0.63
ARCHIVE_URL="https://github.com/ShentoHendriks/rwa-vps-installer/releases/download/${VERSION}/rwa-vps-panel-${VERSION}.tar.gz"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

curl -fsSL --retry 3 "$ARCHIVE_URL" -o "$WORK_DIR/rwa-vps-panel.tar.gz"
tar -xzf "$WORK_DIR/rwa-vps-panel.tar.gz" -C "$WORK_DIR"
exec bash "$WORK_DIR/rwa-vps-panel/install.sh"
