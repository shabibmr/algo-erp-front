#!/usr/bin/env bash
# Idempotent MariaDB bootstrap for local algoERP development.
set -euo pipefail

DB_NAME="${DB_NAME:-algoerp_dev}"
DB_USER="${DB_USER:-algoerp}"
DB_PASSWORD="${DB_PASSWORD:-algoerp_dev}"
MYSQL_SOCKET="${MYSQL_SOCKET:-/run/mysqld/mysqld.sock}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$("$SCRIPT_DIR/resolve-backend.sh")"
SCHEMA_FILE="$BACKEND_DIR/docs/db/live_schema.sql"

start_mysql() {
  if mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null; then
    return 0
  fi

  sudo mkdir -p /run/mysqld
  sudo chown mysql:mysql /run/mysqld
  sudo mysqld_safe \
    --datadir=/var/lib/mysql \
    --socket="$MYSQL_SOCKET" \
    --pid-file=/run/mysqld/mysqld.pid &
  for _ in $(seq 1 45); do
    if mysqladmin ping -h 127.0.0.1 --silent 2>/dev/null; then
      return 0
    fi
    sleep 1
  done
  echo "MariaDB did not become ready in time." >&2
  return 1
}

write_backend_env() {
  local env_file="$BACKEND_DIR/.env"
  cat >"$env_file" <<EOF
PORT=5000
DATABASE_URL=mysql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:3306/${DB_NAME}
JWT_ACCESS_SECRET=dev-access-secret-32chars-min
JWT_REFRESH_SECRET=dev-refresh-secret-32chars-min
NODE_ENV=development
LOG_TO_FILE=false
EOF
}

start_mysql

sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

table_count="$(sudo mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}';")"
if [[ "$table_count" -eq 0 ]]; then
  if [[ ! -f "$SCHEMA_FILE" ]]; then
    echo "Missing schema file: $SCHEMA_FILE" >&2
    exit 1
  fi
  sudo mysql "$DB_NAME" <"$SCHEMA_FILE"
fi

write_backend_env

cd "$BACKEND_DIR"
npx tsx scripts/seed-dev-permissions.ts
npx tsx scripts/seed-test-user.ts

echo "Database ready: ${DB_NAME} (${table_count:-imported} tables)"
