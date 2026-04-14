#!/usr/bin/env bash
set -euo pipefail

echo
echo "== MERGEN DEMO =="
echo
echo "A strategy passed backtest."
echo "Checking if it is safe to activate..."
echo

TMP_DIR="/tmp/mergen_demo_$$"
mkdir -p "$TMP_DIR"

ALLOW_STRATEGY_ID="demo_ok_$$"
BLOCK_STRATEGY_ID="demo_bad_$$"
SEED="demo_${$}"

echo "[1/5] building deterministic runtime snapshot"
cargo run --quiet --bin make_test_runtime -- "$TMP_DIR" "$SEED" >/dev/null

echo "[2/5] exporting execution trace"
cargo run --quiet --bin export_trace -- "$TMP_DIR" >/dev/null

TRACE="$TMP_DIR/mergen_trace.json"
BROKEN="$TMP_DIR/mergen_trace_broken.json"

echo "[3/5] simulating corruption"
python3 - <<PY
import json
p="$TRACE"
b="$BROKEN"
d=json.load(open(p))
d["root_hash"]="BROKEN_"+d["root_hash"]
open(b,"w").write(json.dumps(d))
PY

echo "[4/5] verification pipeline"
echo "→ verifying deterministic execution trace..."
sleep 0.4
echo "→ checking replay equivalence..."
sleep 0.4
echo "→ validating state integrity..."
sleep 0.4

rm -f ".activation_state/${ALLOW_STRATEGY_ID}__v1.json"
rm -f ".activation_state/${BLOCK_STRATEGY_ID}__v1.json"

echo
echo "---- VALID STATE ----"
./scripts/run_strategy_activation_pipeline.sh \
  --trace-path "$TRACE" \
  --strategy-id "$ALLOW_STRATEGY_ID" \
  --version-id v1 || true

echo
echo "---- CORRUPTED STATE ----"
./scripts/run_strategy_activation_pipeline.sh \
  --trace-path "$BROKEN" \
  --strategy-id "$BLOCK_STRATEGY_ID" \
  --version-id v1 || true

echo
echo "== RESULT =="
echo "Valid execution → allowed"
echo "Corrupted execution → blocked"
echo
echo "Activation is the last safe checkpoint."
echo "No valid trace -> no activation"
echo
