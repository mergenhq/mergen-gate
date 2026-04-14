#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"
CURRENT="${ARTIFACT_ROOT}/discovery_trace_current.json"
MANIFEST="${ARTIFACT_ROOT}/discovery_trace_manifest.ndjson"

if [ ! -f "$CURRENT" ]; then
  echo "missing current artifact: $CURRENT" >&2
  exit 1
fi

if [ ! -f "$MANIFEST" ]; then
  echo "missing manifest: $MANIFEST" >&2
  exit 1
fi

if command -v shasum >/dev/null 2>&1; then
  CURRENT_HASH="$(shasum -a 256 "$CURRENT" | awk '{print $1}')"
else
  CURRENT_HASH="$(sha256sum "$CURRENT" | awk '{print $1}')"
fi

LATEST_HASH="$(tail -n 1 "$MANIFEST" | python3 -c 'import sys, json; print(json.loads(sys.stdin.read())["sha256"])')"

if [ "$CURRENT_HASH" != "$LATEST_HASH" ]; then
  echo "ARTIFACT TAMPER DETECTED: current hash does not match manifest latest hash" >&2
  echo "current:  $CURRENT_HASH" >&2
  echo "manifest: $LATEST_HASH" >&2
  exit 1
fi

echo "integrity_ok current_hash=$CURRENT_HASH"
