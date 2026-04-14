#!/usr/bin/env bash
set -euo pipefail
ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"

FIXTURE="tests/fixtures/discovery_trace_canonical.json"
CURRENT="${ARTIFACT_ROOT}/discovery_trace_current.json"

if [ ! -f "$CURRENT" ]; then
  ./scripts/write_discovery_trace_artifact.sh >/dev/null
fi

if command -v diff >/dev/null 2>&1; then
  diff -u "$FIXTURE" "$CURRENT" || true
else
  echo "diff command not found"
  exit 1
fi