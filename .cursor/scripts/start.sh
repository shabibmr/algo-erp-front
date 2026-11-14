#!/usr/bin/env bash
# Per-boot startup: ensure MariaDB is running before terminals start services.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null; then
  echo "MariaDB already running."
  exit 0
fi

"$SCRIPT_DIR/setup-database.sh" >/dev/null
echo "MariaDB started."
