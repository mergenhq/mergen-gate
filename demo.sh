#!/usr/bin/env bash
set -euo pipefail

echo "Run this to see why activation needs a gate."
echo
echo "== MERGEN DEMO =="
echo

TMP_DIR="/tmp/mergen_demo_$$"
mkdir -p "$TMP_DIR"

ALLOW_STRATEGY_ID="demo_ok_$$"
BLOCK_STRATEGY_ID="demo_bad_$$"
SEED="demo_${$}"

echo "[1/4] build minimal runtime"
cargo run --quiet --bin make_test_runtime -- "$TMP_DIR" "$SEED" >/dev/null

echo "[2/4] export trace"
cargo run --quiet --bin export_trace -- "$TMP_DIR" >/dev/null

TRACE="$TMP_DIR/mergen_trace.json"
BROKEN="$TMP_DIR/mergen_trace_broken.json"

echo "[3/4] create corrupted state sample"
python3 - <<PY
import json
p="$TRACE"
b="$BROKEN"
d=json.load(open(p))
d["root_hash"]="BROKEN_"+d["root_hash"]
open(b,"w").write(json.dumps(d))
PY

rm -f ".activation_state/${ALLOW_STRATEGY_ID}__v1.json"
rm -f ".activation_state/${BLOCK_STRATEGY_ID}__v1.json"

echo
echo "---- ALLOW (valid state) ----"
./scripts/run_strategy_activation_pipeline.sh \
  --trace-path "$TRACE" \
  --strategy-id "$ALLOW_STRATEGY_ID" \
  --version-id v1 || true

echo
echo "---- BLOCK (corrupted state) ----"
./scripts/run_strategy_activation_pipeline.sh \
  --trace-path "$BROKEN" \
  --strategy-id "$BLOCK_STRATEGY_ID" \
  --version-id v1 || true

echo
echo "== DONE =="
echo "If the second step did not block, your system is unsafe."
