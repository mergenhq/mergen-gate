#!/usr/bin/env bash
set -euo pipefail

echo "=== DISCOVERY CONTRACT CHECK ==="
./scripts/test_discovery.sh
cargo run >/dev/null
echo "DISCOVERY CONTRACT: OK"
