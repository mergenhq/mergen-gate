#!/usr/bin/env bash
set -euo pipefail

echo "== canonical runtime journal path =="
if [ -n "${MERGEN_RUNTIME_JOURNAL_ROOT:-}" ]; then
  JOURNAL_PATH="${MERGEN_RUNTIME_JOURNAL_ROOT%/}/runtime_journal.ndjson"
else
  JOURNAL_PATH="./artifacts/runtime_journal.ndjson"
fi
echo "$JOURNAL_PATH"

echo
echo "== canonical file existence =="
if [ -f "$JOURNAL_PATH" ]; then
  echo "exists"
else
  echo "missing"
fi

echo
echo "== canonical file first 20 lines =="
if [ -f "$JOURNAL_PATH" ]; then
  sed -n '1,20p' "$JOURNAL_PATH"
else
  echo "missing"
fi

echo
echo "== canonical version report =="
if [ -f "$JOURNAL_PATH" ]; then
  cargo run --bin runtime_journal_version_report -- --journal-path "$JOURNAL_PATH" || true
else
  echo "skip:no_canonical_journal"
fi

echo
echo "== canonical replay verify =="
if [ -f "$JOURNAL_PATH" ]; then
  cargo run --bin runtime_replay_verify -- --journal-path "$JOURNAL_PATH" || true
else
  echo "skip:no_canonical_journal"
fi

echo
echo "== non-canonical contrast surfaces =="
for p in \
  "./audit_data/execution_events.log" \
  "./audit_data/guard_events.log" \
  "./audit.log" \
  "./audit_data/epistemic_memory.log"
do
  if [ -f "$p" ]; then
    echo "--- $p"
    cargo run --bin runtime_journal_version_report -- --journal-path "$p" || true
  fi
done

echo
echo "== writer surface grep =="
grep -RIn "append_runtime_journal_entry\|runtime_journal_claim_from_path" src tests || true

echo
echo "== hardcoded journal path grep =="
grep -RIn "runtime_journal.ndjson\|execution_events\.log\|guard_events\.log\|audit\.log\|audit_data" src tests examples || true
