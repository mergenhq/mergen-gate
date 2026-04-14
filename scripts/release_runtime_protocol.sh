#!/usr/bin/env bash
set -euo pipefail

echo "== runtime protocol release gate =="
echo

echo "== cargo test --workspace =="
cargo test --workspace
echo

echo "== runtime protocol e2e =="
cargo test --test runtime_protocol_e2e
echo

echo "== runtime protocol duplicate e2e =="
cargo test --test runtime_protocol_duplicate_e2e
echo

echo "== runtime journal legacy rejection =="
cargo test --test runtime_journal_legacy_rejection
echo

echo "== runtime replay empty journal contract =="
cargo test --test runtime_replay_empty_journal_contract
echo

echo "== runtime journal migration strategy placeholder =="
cargo test --test runtime_journal_migration_strategy_placeholder
echo
echo "== runtime journal version detector matrix =="
cargo test --test runtime_journal_version_detector_matrix
echo
echo "== runtime journal version classifier placeholder =="
cargo test --test runtime_journal_version_classifier_placeholder
echo

echo "== runtime replay cli =="
cargo test --test runtime_replay_cli
echo

echo "== verify discovery trace manifest =="
bash ./scripts/verify_discovery_trace_manifest.sh
echo

echo "== enforce discovery trace integrity =="
bash ./scripts/enforce_discovery_trace_integrity.sh
echo

JOURNAL_PATH="${MERGEN_RUNTIME_JOURNAL_ROOT:-./artifacts}/runtime_journal.ndjson"

if [[ -f "$JOURNAL_PATH" ]]; then
  echo "== runtime replay verify =="
  cargo run --bin runtime_replay_verify -- --journal-path "$JOURNAL_PATH"
  echo
else
  echo "== runtime replay verify skipped =="
  echo "runtime journal not found at: $JOURNAL_PATH"
  echo
fi

echo "runtime_protocol_release_gate_ok"
