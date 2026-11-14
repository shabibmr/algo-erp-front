#!/usr/bin/env bash
# Resolves the algoERP backend checkout used by Cloud Agent setup scripts.
set -euo pipefail

BACKEND_REPO="${BACKEND_REPO:-github.com/shabibmr/algo-backend-backend}"
BACKEND_DIR="${BACKEND_DIR:-$HOME/models/backend}"

if [[ -f "$BACKEND_DIR/package.json" ]]; then
  printf '%s\n' "$BACKEND_DIR"
  exit 0
fi

# Cursor repositoryDependencies may check out sibling repos; probe common layouts.
for candidate in \
  "$HOME/models/backend" \
  "$HOME/shabibmr/algo-backend-backend" \
  "/workspace/../models/backend" \
  "/workspace/../algo-backend-backend"; do
  if [[ -f "$candidate/package.json" ]]; then
    printf '%s\n' "$candidate"
    exit 0
  fi
done

mkdir -p "$(dirname "$BACKEND_DIR")"
if [[ ! -d "$BACKEND_DIR/.git" ]]; then
  git clone --depth 1 "https://${BACKEND_REPO}.git" "$BACKEND_DIR"
fi

printf '%s\n' "$BACKEND_DIR"
