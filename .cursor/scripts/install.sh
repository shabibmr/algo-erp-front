#!/usr/bin/env bash
# Idempotent Cloud Agent install for algo_erp_front + backend.
set -euo pipefail

export PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH:-}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$("$SCRIPT_DIR/resolve-backend.sh")"

cd /workspace
flutter pub get
dart run build_runner build --delete-conflicting-outputs

cd "$BACKEND_DIR"
npm ci
npx prisma generate

"$SCRIPT_DIR/setup-database.sh"

echo "Install complete."
