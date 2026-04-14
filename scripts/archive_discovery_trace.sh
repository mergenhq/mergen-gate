#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"

mkdir -p "$ARTIFACT_ROOT"
mkdir -p "${ARTIFACT_ROOT}/discovery_history"

STAMP="$(date -u +"%Y%m%dT%H%M%S.%NZ")"
CURRENT="${ARTIFACT_ROOT}/discovery_trace_current.json"
OUT="${ARTIFACT_ROOT}/discovery_history/discovery_trace_${STAMP}.json"

# 🔴 DOĞRU: exporter kendi dosyasına yazsın
cargo run --example export_discovery_trace

# 🔴 sonra kopyala
cp "$CURRENT" "$OUT"

# sha256
if command -v shasum >/dev/null 2>&1; then
  HASH="$(shasum -a 256 "$OUT" | awk '{print $1}')"
else
  HASH="$(sha256sum "$OUT" | awk '{print $1}')"
fi

# claim_count extract
CLAIM_COUNT="$(cat "$OUT" | python3 -c "import sys,json; print(json.load(sys.stdin)['claim_count'])")"

# snapshot match
if diff -q "$OUT" tests/fixtures/discovery_trace_canonical.json >/dev/null 2>&1; then
  SNAPSHOT_MATCH="true"
else
  SNAPSHOT_MATCH="false"
fi

# manifest append
echo "{\"file\":\"$OUT\",\"sha256\":\"$HASH\",\"created_at\":\"$STAMP\",\"claim_count\":$CLAIM_COUNT,\"snapshot_match\":$SNAPSHOT_MATCH}" >> "${ARTIFACT_ROOT}/discovery_trace_manifest.ndjson"

echo "archived: $OUT"
echo "hash    : $HASH"
echo "current : $CURRENT"
