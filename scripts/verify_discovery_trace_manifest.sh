#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"
MANIFEST="${ARTIFACT_ROOT}/discovery_trace_manifest.ndjson"

# hard gate: current artifact must match latest manifest hash
./scripts/enforce_discovery_trace_integrity.sh >/dev/null

if [ ! -f "$MANIFEST" ]; then
  echo "missing manifest: $MANIFEST" >&2
  exit 1
fi

if [ ! -s "$MANIFEST" ]; then
  echo "empty manifest: $MANIFEST" >&2
  exit 1
fi

LATEST_LINE="$(tail -n 1 "$MANIFEST")"

LATEST_FILE="$(printf '%s' "$LATEST_LINE" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read())["file"])')"
LATEST_HASH="$(printf '%s' "$LATEST_LINE" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read())["sha256"])')"
SNAPSHOT_MATCH="$(printf '%s' "$LATEST_LINE" | python3 -c 'import sys,json; print(json.loads(sys.stdin.read())["snapshot_match"])')"
ENTRY_COUNT="$(wc -l < "$MANIFEST" | awk "{print \$1}")"

if [ ! -f "$LATEST_FILE" ]; then
  echo "latest manifest file missing: $LATEST_FILE" >&2
  exit 1
fi

if command -v shasum >/dev/null 2>&1; then
  COMPUTED_HASH="$(shasum -a 256 "$LATEST_FILE" | awk '{print $1}')"
else
  COMPUTED_HASH="$(sha256sum "$LATEST_FILE" | awk '{print $1}')"
fi

if [ "$COMPUTED_HASH" != "$LATEST_HASH" ]; then
  echo "manifest hash mismatch" >&2
  echo "computed: $COMPUTED_HASH" >&2
  echo "manifest: $LATEST_HASH" >&2
  exit 1
fi

if [ "$SNAPSHOT_MATCH" != "true" ] && [ "$SNAPSHOT_MATCH" != "True" ]; then
  echo "snapshot_match must be true, got $SNAPSHOT_MATCH" >&2
  exit 1
fi

echo "manifest_ok entries=$ENTRY_COUNT"
echo "latest_file=$LATEST_FILE"
echo "latest_hash=$LATEST_HASH"
