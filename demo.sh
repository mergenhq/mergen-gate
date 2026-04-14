#!/usr/bin/env bash
set -euo pipefail

echo
echo "== MERGEN PUBLIC DEMO =="
echo
echo "This is a public walkthrough of the activation gate behavior."
echo "It does not expose the private runtime core."
echo
echo "Scenario:"
echo "A strategy passed backtest."
echo "Now we check whether it is safe to activate."
echo

echo "[1/3] verifying deterministic execution trace..."
sleep 0.4
echo "[2/3] checking replay consistency..."
sleep 0.4
echo "[3/3] validating state integrity before activation..."
sleep 0.4

echo
echo "---- VALID STATE ----"
cat <<'VALID'
{
  "verdict": "ALLOW",
  "reason_code": "TRACE_VERIFIED",
  "signal": "runtime_trace_valid",
  "hint": "trace verified exactly",
  "execution_token": "<redacted>"
}
{"verdict":"ALLOW","activation":"EXECUTED","strategy_id":"demo_ok","version_id":"v1"}
VALID

echo
echo "---- CORRUPTED STATE ----"
cat <<'BROKEN'
{
  "verdict": "BLOCK",
  "reason_code": "ROOT_HASH_MISMATCH",
  "signal": "trace_root_hash_differs",
  "hint": "trace root hash does not match canonical recomputation",
  "execution_token": null
}
{"pipeline":"DENIED","strategy_id":"demo_bad","version_id":"v1","verdict":"BLOCK"}
BROKEN

echo
echo "== RESULT =="
echo "Valid execution -> allowed"
echo "Corrupted execution -> blocked"
echo
echo "Activation is the last safe checkpoint."
echo "No valid trace -> no activation"
echo
