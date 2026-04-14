#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage:"
  echo "  activate_strategy.sh --trace-path <trace> --execution-token <token> --strategy-id <id> --version-id <version>"
  exit 2
}

TRACE=""
TOKEN=""
STRATEGY_ID=""
VERSION_ID=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --trace-path) TRACE="$2"; shift 2 ;;
    --execution-token) TOKEN="$2"; shift 2 ;;
    --strategy-id) STRATEGY_ID="$2"; shift 2 ;;
    --version-id) VERSION_ID="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[ -n "$TRACE" ] || usage
[ -n "$TOKEN" ] || usage
[ -n "$STRATEGY_ID" ] || usage
[ -n "$VERSION_ID" ] || usage

STATE_DIR=".activation_state"
mkdir -p "$STATE_DIR"

STATE_FILE="$STATE_DIR/${STRATEGY_ID}__${VERSION_ID}.json"

# 1 — duplicate activation block
if [ -f "$STATE_FILE" ]; then
  echo '{"verdict":"BLOCK","reason_code":"ALREADY_ACTIVE","activation":"DENIED"}'
  exit 1
fi

# 2 — token replay check (scan all states)
for f in "$STATE_DIR"/*.json; do
  [ -e "$f" ] || continue
  USED_TOKEN="$(python3 -c "import json,sys; print(json.load(open('$f'))['execution_token'])")"
  if [ "$USED_TOKEN" = "$TOKEN" ]; then
    echo '{"verdict":"BLOCK","reason_code":"TOKEN_ALREADY_USED","activation":"DENIED"}'
    exit 1
  fi
done

# 3 — run gate again silently for authority re-check
set +e
GATE_OUTPUT="$(cargo run --quiet --bin gate -- --trace-path "$TRACE")"
GATE_STATUS=$?
set -e

if [ -z "$GATE_OUTPUT" ]; then
  echo '{"verdict":"REVIEW","reason_code":"EMPTY_GATE_OUTPUT","activation":"DENIED"}'
  exit 2
fi

export GATE_OUTPUT
VERDICT="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"])["verdict"])')"
GATE_TOKEN="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"]).get("execution_token",""))')"

case "$VERDICT" in
  ALLOW)
    if [ -z "$GATE_TOKEN" ]; then
      echo '{"verdict":"BLOCK","reason_code":"MISSING_EXECUTION_TOKEN","activation":"DENIED"}'
      exit 1
    fi

    if [ "$GATE_TOKEN" != "$TOKEN" ]; then
      echo '{"verdict":"BLOCK","reason_code":"EXECUTION_TOKEN_MISMATCH","activation":"DENIED"}'
      exit 1
    fi
    ;;
  BLOCK)
    echo '{"verdict":"BLOCK","activation":"DENIED"}'
    exit 1
    ;;
  REVIEW)
    echo '{"verdict":"REVIEW","activation":"DENIED"}'
    exit 2
    ;;
  *)
    echo '{"verdict":"REVIEW","reason_code":"UNKNOWN_GATE_VERDICT","activation":"DENIED"}'
    exit 2
    ;;
esac

# 4 — write state (final authority commit)
cat > "$STATE_FILE" <<STATE
{
  "strategy_id": "$STRATEGY_ID",
  "version_id": "$VERSION_ID",
  "trace_path": "$TRACE",
  "execution_token": "$TOKEN",
  "status": "ACTIVE"
}
STATE

echo "{\"verdict\":\"ALLOW\",\"activation\":\"EXECUTED\",\"strategy_id\":\"$STRATEGY_ID\",\"version_id\":\"$VERSION_ID\"}"
