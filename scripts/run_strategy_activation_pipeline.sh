#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage:"
  echo "  scripts/run_strategy_activation_pipeline.sh --trace-path <trace_file> --strategy-id <id> --version-id <version>"
  exit 2
}

TRACE_PATH=""
STRATEGY_ID=""
VERSION_ID=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --trace-path)
      [ "$#" -ge 2 ] || usage
      TRACE_PATH="$2"
      shift 2
      ;;
    --strategy-id)
      [ "$#" -ge 2 ] || usage
      STRATEGY_ID="$2"
      shift 2
      ;;
    --version-id)
      [ "$#" -ge 2 ] || usage
      VERSION_ID="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$TRACE_PATH" ] || usage
[ -n "$STRATEGY_ID" ] || usage
[ -n "$VERSION_ID" ] || usage

set +e
GATE_OUTPUT="$(cargo run --quiet --bin gate -- --trace-path "$TRACE_PATH")"
GATE_STATUS=$?
set -e

if [ -n "$GATE_OUTPUT" ]; then
  printf '%s\n' "$GATE_OUTPUT"
fi

if [ -z "$GATE_OUTPUT" ]; then
  echo '{"pipeline":"DENIED","verdict":"REVIEW","reason_code":"EMPTY_GATE_OUTPUT"}'
  exit 2
fi

export GATE_OUTPUT
VERDICT="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"])["verdict"])')"

case "$VERDICT" in
  ALLOW)
    TOKEN="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"])["execution_token"])')"

    ./scripts/activate_strategy.sh \
      --trace-path "$TRACE_PATH" \
      --execution-token "$TOKEN" \
      --strategy-id "$STRATEGY_ID" \
      --version-id "$VERSION_ID"
    ;;
  BLOCK)
    echo "{\"pipeline\":\"DENIED\",\"strategy_id\":\"$STRATEGY_ID\",\"version_id\":\"$VERSION_ID\",\"verdict\":\"BLOCK\"}"
    exit 1
    ;;
  REVIEW)
    echo "{\"pipeline\":\"DENIED\",\"strategy_id\":\"$STRATEGY_ID\",\"version_id\":\"$VERSION_ID\",\"verdict\":\"REVIEW\"}"
    exit 2
    ;;
  *)
    echo '{"pipeline":"DENIED","verdict":"REVIEW","reason_code":"UNKNOWN_GATE_VERDICT"}'
    exit 2
    ;;
esac
