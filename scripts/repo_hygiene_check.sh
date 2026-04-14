#!/usr/bin/env bash
set -euo pipefail

echo "=== REPO HYGIENE CHECK ==="

FOUND="$(find . \
  -path ./target -prune -o \
  -path ./.repo_quarantine -prune -o \
  -type f \( -name '*.bak' -o -name '*.bak_*' -o -name '*.rs.bak' -o -name '*.rs.bak_*' -o -name '*.toml.bak' -o -name '*.toml.bak_*' \) \
  -print)"

if [ -n "$FOUND" ]; then
  echo "Unexpected backup artifacts still present in active repo surface:"
  echo "$FOUND"
  exit 1
fi

echo "REPO HYGIENE: OK"
