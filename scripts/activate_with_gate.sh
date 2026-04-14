#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage:"
  echo "  scripts/activate_with_gate.sh --trace-path <trace_file> --execution-token <token> -- <command> [args...]"
  exit 2
}

TRACE_PATH=""
EXECUTION_TOKEN=""
CMD=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --trace-path)
      [ "$#" -ge 2 ] || usage
      TRACE_PATH="$2"
      shift 2
      ;;
    --execution-token)
      [ "$#" -ge 2 ] || usage
      EXECUTION_TOKEN="$2"
      shift 2
      ;;
    --)
      shift
      CMD=("$@")
      break
      ;;
    *)
      usage
      ;;
  esac
done

[ -n "$TRACE_PATH" ] || usage
[ -n "$EXECUTION_TOKEN" ] || usage
[ "${#CMD[@]}" -gt 0 ] || usage

set +e
GATE_OUTPUT="$(cargo run --quiet --bin gate -- --trace-path "$TRACE_PATH")"
GATE_STATUS=$?
set -e

printf '%s\n' "$GATE_OUTPUT"

if [ -z "$GATE_OUTPUT" ]; then
  echo "ACTIVATION_GATE=REVIEW"
  exit 2
fi

export GATE_OUTPUT
VERDICT="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"])["verdict"])')"
EXPECTED_TOKEN="$(python3 -c 'import json,os; print(json.loads(os.environ["GATE_OUTPUT"]).get("execution_token",""))')"

case "$VERDICT" in
  ALLOW)
    if [ -z "$EXPECTED_TOKEN" ]; then
      echo '{"verdict":"BLOCK","reason_code":"MISSING_EXECUTION_TOKEN","signal":"gate_returned_no_token","hint":"allow verdict without token is not activation-authoritative"}'
      echo "ACTIVATION_GATE=BLOCK"
      exit 1
    fi

    if [ "$EXECUTION_TOKEN" != "$EXPECTED_TOKEN" ]; then
      echo '{"verdict":"BLOCK","reason_code":"EXECUTION_TOKEN_MISMATCH","signal":"provided_token_differs","hint":"provided execution token does not match gate authority output"}'
      echo "ACTIVATION_GATE=BLOCK"
      exit 1
    fi

    echo "ACTIVATION_GATE=ALLOW"
    exec "${CMD[@]}"
    ;;
  BLOCK)
    echo "ACTIVATION_GATE=BLOCK"
    exit 1
    ;;
  REVIEW)
    echo "ACTIVATION_GATE=REVIEW"
    exit 2
    ;;
  *)
    echo "ACTIVATION_GATE=REVIEW"
    exit 2
    ;;
esac
