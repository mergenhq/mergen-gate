#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage:"
  echo "  scripts/gate_check.sh --runtime-dir <dir>"
  echo "  scripts/gate_check.sh --trace-path <file>"
  exit 2
}

if [ "$#" -ne 2 ]; then
  usage
fi

MODE="$1"
TARGET="$2"

case "$MODE" in
  --runtime-dir)
    cargo run --quiet --bin gate -- --runtime-dir "$TARGET"
    ;;
  --trace-path)
    cargo run --quiet --bin gate -- --trace-path "$TARGET"
    ;;
  *)
    usage
    ;;
esac
