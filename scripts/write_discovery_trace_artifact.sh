#!/usr/bin/env bash
set -euo pipefail
ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"

mkdir -p artifacts
cargo run --example export_discovery_trace > ${ARTIFACT_ROOT}/discovery_trace_current.json
echo "wrote ${ARTIFACT_ROOT}/discovery_trace_current.json"