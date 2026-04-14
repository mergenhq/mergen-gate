#!/usr/bin/env bash
set -euo pipefail

./scripts/test_discovery.sh
cargo run
