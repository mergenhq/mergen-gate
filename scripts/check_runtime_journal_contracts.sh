#!/usr/bin/env bash
set -euo pipefail

echo "== runtime journal contract check =="

CANONICAL_JOURNAL="./artifacts/runtime_journal.ndjson"

echo
echo "== 1) canonical path =="
echo "${CANONICAL_JOURNAL}"

echo
echo "== 2) ensure parent directory exists =="
mkdir -p ./artifacts
echo "ok"

echo
echo "== 3) ensure canonical journal file exists =="
touch "${CANONICAL_JOURNAL}"
echo "ok"

echo
echo "== 4) canonical version report =="
cargo run --bin runtime_journal_version_report -- --journal-path "${CANONICAL_JOURNAL}"

echo
echo "== 5) canonical replay verify =="
cargo run --bin runtime_replay_verify -- --journal-path "${CANONICAL_JOURNAL}"

echo
echo "== 6) non-canonical contrast =="
for path in \
  "./audit_data/execution_events.log" \
  "./audit_data/guard_events.log" \
  "./audit.log" \
  "./audit_data/epistemic_memory.log"
do
  if [ -f "${path}" ]; then
    echo "--- ${path}"
    if cargo run --bin runtime_journal_version_report -- --journal-path "${path}"; then
      true
    else
      true
    fi
  fi
done

echo
echo "== 7) targeted runtime journal contract tests =="
cargo test --test runtime_journal_empty_surface_contract
cargo test --test runtime_journal_canonical_write_contract
cargo test --test runtime_journal_version_contract
cargo test --test runtime_journal_version_detector_matrix
cargo test --test runtime_journal_version_leaf_guard
cargo test --test runtime_journal_version_report_cli
cargo test --test runtime_journal_version_report_hash_contract
cargo test --test runtime_journal_version_report_snapshot

echo
echo "== 8) workspace regression =="
cargo test --workspace

echo
echo "runtime journal contract check: PASS"
