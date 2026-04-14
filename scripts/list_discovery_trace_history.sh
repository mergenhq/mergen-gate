#!/usr/bin/env bash
set -euo pipefail
ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"

mkdir -p ${ARTIFACT_ROOT}/discovery_history

count=0
for f in ${ARTIFACT_ROOT}/discovery_history/discovery_trace_*.json; do
  if [ -f "$f" ]; then
    echo "$f"
    count=$((count + 1))
  fi
done

echo "history_count=$count"