#!/usr/bin/env bash
set -euo pipefail

echo "=== MERGEN FULL CI ==="

./scripts/ci_discovery.sh
./scripts/ci_trace.sh
./scripts/repo_hygiene_check.sh
./scripts/test_legacy.sh

echo "FULL CI: OK"
