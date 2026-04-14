#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-./real_world_chaos}"
INPUT_DIR="$BASE_DIR/inputs"
RUNTIME_DIR="$BASE_DIR/runtime"
REPORT_PATH="$BASE_DIR/report.json"
SIGNING_KEY="${2:-0101010101010101010101010101010101010101010101010101010101010101}"
COUNT="${3:-250}"

rm -rf "$BASE_DIR"
mkdir -p "$INPUT_DIR" "$RUNTIME_DIR"

python3 - <<'PY' "$INPUT_DIR" "$COUNT"
import json
import os
import random
import sys

input_dir = sys.argv[1]
count = int(sys.argv[2])

rng = random.Random(20260406)

def write(name, content):
    path = os.path.join(input_dir, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

def valid_payload(i):
    return {
        "stimulus_id": f"stimulus-{i}",
        "stimulus_hash": f"stimulus-{i}-hash",
        "candidates": [
            {
                "candidate_id": f"candidate-{i}",
                "model_name": "dummy-model",
                "model_version": "v1",
                "decision_status": "applied",
                "decision_reason": "accepted_runtime_intent_applied",
                "context_hash": f"ctx-{i}",
                "metadata_json": "{}",
            }
        ],
    }

def alias_status_payload(i, alias):
    p = valid_payload(i)
    p["candidates"][0]["decision_status"] = alias
    return p

def alias_reason_payload(i, alias):
    p = valid_payload(i)
    p["candidates"][0]["decision_reason"] = alias
    return p

def missing_metadata_payload(i):
    p = valid_payload(i)
    del p["candidates"][0]["metadata_json"]
    return p

def empty_context_payload(i):
    p = valid_payload(i)
    p["candidates"][0]["context_hash"] = ""
    return p

def missing_stimulus_hash_payload(i):
    p = valid_payload(i)
    del p["stimulus_hash"]
    return p

def missing_candidates_payload(i):
    p = valid_payload(i)
    del p["candidates"]
    return p

def invalid_reason_payload(i):
    p = valid_payload(i)
    p["candidates"][0]["decision_reason"] = "totally_unknown_reason"
    return p

def invalid_status_payload(i):
    p = valid_payload(i)
    p["candidates"][0]["decision_status"] = "TOTALLY_UNKNOWN_STATUS"
    return p

def huge_metadata_payload(i, size=12000):
    p = valid_payload(i)
    p["candidates"][0]["metadata_json"] = "X" * size
    return p

def multi_candidate_payload(i):
    return {
        "stimulus_id": f"stimulus-{i}",
        "stimulus_hash": f"stimulus-{i}-hash",
        "candidates": [
            {
                "candidate_id": f"candidate-{i}-a",
                "model_name": "dummy-a",
                "model_version": "v1",
                "decision_status": "applied",
                "decision_reason": "accepted_runtime_intent_applied",
                "context_hash": f"ctx-{i}-a",
                "metadata_json": "{}",
            },
            {
                "candidate_id": f"candidate-{i}-b",
                "model_name": "dummy-b",
                "model_version": "v2",
                "decision_status": "applied",
                "decision_reason": "accepted_runtime_intent_applied",
                "context_hash": f"ctx-{i}-b",
                "metadata_json": "{}",
            }
        ],
    }

def malformed_json(i):
    variants = [
        '{"stimulus_id": "broken"',
        '{"stimulus_id": 123',
        '{"candidates": [',
        '{ not-json }',
        '{"stimulus_id":"x","stimulus_hash":"y","candidates":',
    ]
    return variants[i % len(variants)]

status_aliases = [
    "approved", "accept", "completed", "done", "executed",
    "denied", "cancelled", "skipped", "pass"
]

reason_aliases = [
    "accepted",
    "accepted_apply",
    "apply_ok",
    "already_processed",
    "duplicate_input",
    "invalid_receipt",
    "bad_receipt",
    "state_mismatch",
    "prev_state_mismatch",
]

profiles = [
    ("valid", 0.22),
    ("alias_status", 0.12),
    ("alias_reason", 0.10),
    ("missing_metadata", 0.10),
    ("empty_context", 0.10),
    ("missing_stimulus_hash", 0.10),
    ("missing_candidates", 0.08),
    ("invalid_reason", 0.06),
    ("invalid_status", 0.06),
    ("huge_metadata", 0.03),
    ("multi_candidate", 0.02),
    ("malformed_json", 0.01),
]

total = sum(w for _, w in profiles)
profiles = [(name, w / total) for name, w in profiles]

def choose_profile():
    r = rng.random()
    acc = 0.0
    for name, w in profiles:
        acc += w
        if r <= acc:
            return name
    return profiles[-1][0]

summary = {
    "generated": 0,
    "by_profile": {},
}

for i in range(1, count + 1):
    profile = choose_profile()
    summary["generated"] += 1
    summary["by_profile"][profile] = summary["by_profile"].get(profile, 0) + 1

    if profile == "valid":
        payload = valid_payload(i)
        write(f"{i:04d}_valid.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "alias_status":
        payload = alias_status_payload(i, rng.choice(status_aliases))
        write(f"{i:04d}_alias_status.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "alias_reason":
        payload = alias_reason_payload(i, rng.choice(reason_aliases))
        write(f"{i:04d}_alias_reason.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "missing_metadata":
        payload = missing_metadata_payload(i)
        write(f"{i:04d}_missing_metadata.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "empty_context":
        payload = empty_context_payload(i)
        write(f"{i:04d}_empty_context.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "missing_stimulus_hash":
        payload = missing_stimulus_hash_payload(i)
        write(f"{i:04d}_missing_stimulus_hash.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "missing_candidates":
        payload = missing_candidates_payload(i)
        write(f"{i:04d}_missing_candidates.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "invalid_reason":
        payload = invalid_reason_payload(i)
        write(f"{i:04d}_invalid_reason.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "invalid_status":
        payload = invalid_status_payload(i)
        write(f"{i:04d}_invalid_status.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "huge_metadata":
        payload = huge_metadata_payload(i)
        write(f"{i:04d}_huge_metadata.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "multi_candidate":
        payload = multi_candidate_payload(i)
        write(f"{i:04d}_multi_candidate.json", json.dumps(payload, ensure_ascii=False, indent=2))
    elif profile == "malformed_json":
        write(f"{i:04d}_malformed_json.json", malformed_json(i))

with open(os.path.join(os.path.dirname(input_dir), "generation_summary.json"), "w", encoding="utf-8") as f:
    json.dump(summary, f, ensure_ascii=False, indent=2)
PY

cargo run -p mergen_control --bin run_measurement -- "$RUNTIME_DIR" "$INPUT_DIR" "$SIGNING_KEY" | tee "$REPORT_PATH"

python3 - <<'PY' "$BASE_DIR/generation_summary.json" "$REPORT_PATH"
import json
import sys

gen_path = sys.argv[1]
report_path = sys.argv[2]

with open(gen_path, "r", encoding="utf-8") as f:
    gen = json.load(f)

with open(report_path, "r", encoding="utf-8") as f:
    report = json.load(f)

c = report["counters"]
success_rate = (c["success_runs"] / c["total_runs"] * 100.0) if c["total_runs"] else 0.0
repair_attempt_rate = (c["auto_repair_attempted"] / c["total_runs"] * 100.0) if c["total_runs"] else 0.0
repair_success_rate = (c["auto_repair_succeeded"] / c["auto_repair_attempted"] * 100.0) if c["auto_repair_attempted"] else 0.0

print("")
print("===== REAL WORLD CHAOS SUMMARY =====")
print(f"generated_total={gen['generated']}")
print(f"success_runs={c['success_runs']}")
print(f"failed_runs={c['failed_runs']}")
print(f"success_rate_pct={success_rate:.2f}")
print(f"auto_repair_attempted={c['auto_repair_attempted']}")
print(f"auto_repair_succeeded={c['auto_repair_succeeded']}")
print(f"auto_repair_failed={c['auto_repair_failed']}")
print(f"auto_repair_attempt_rate_pct={repair_attempt_rate:.2f}")
print(f"auto_repair_success_rate_pct={repair_success_rate:.2f}")
print(f"apply_failed={c['apply_failed']}")
print(f"trace_verify_failed={c['trace_verify_failed']}")
print(f"recover_failed={c['recover_failed']}")
print("")
print("generation_profiles=")
for k, v in sorted(gen.get("by_profile", {}).items(), key=lambda kv: (-kv[1], kv[0])):
    print(f"  {k}: {v}")
print("")
print("top_failure_reasons=")
for k, v in sorted(report.get("failure_reasons", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:10]:
    print(f"  {k}: {v}")
print("")
print("top_repair_chains=")
for k, v in sorted(report.get("repair_chains", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:10]:
    print(f"  {k}: {v}")
print("")
print("top_applied_repairs=")
for k, v in sorted(report.get("applied_repairs", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:10]:
    print(f"  {k}: {v}")
PY
