#!/usr/bin/env bash
set -euo pipefail
ARTIFACT_ROOT="${MERGEN_DISCOVERY_ARTIFACT_ROOT:-artifacts}"

cargo run --example export_discovery_trace