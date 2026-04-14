#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage:"
  echo "  scripts/pre_deploy_gate.sh --runtime-dir <dir>"
  echo "  scripts/pre_deploy_gate.sh --trace-path <file>"
  exit 2
}

if [ "$#" -ne 2 ]; then
  usage
fi

MODE="$1"
TARGET="$2"

set +e
./scripts/gate_check.sh "$MODE" "$TARGET"
STATUS=$?
set -e

case "$STATUS" in
  0)
    echo "DEPLOY_GATE=ALLOW"
    exit 0
    ;;
  1)
    echo "DEPLOY_GATE=BLOCK"
    exit 1
    ;;
  2)
    echo "DEPLOY_GATE=REVIEW"
    exit 2
    ;;
  *)
    echo "DEPLOY_GATE=UNKNOWN"
    exit 2
    ;;
esac
