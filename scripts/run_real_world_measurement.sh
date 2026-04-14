#!/usr/bin/env bash
set -euo pipefail

RUNTIME_DIR="${1:-./runtime_real_world}"
INPUT_DIR="${2:-./war_inputs_ext}"
SIGNING_KEY="${3:-0101010101010101010101010101010101010101010101010101010101010101}"

cargo run -p mergen_control --bin run_measurement -- "$RUNTIME_DIR" "$INPUT_DIR" "$SIGNING_KEY"
