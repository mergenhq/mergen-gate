#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${1:-./banded_chaos}"
INPUT_DIR="$BASE_DIR/inputs"
RUNTIME_DIR="$BASE_DIR/runtime"
REPORT_PATH="$BASE_DIR/report.json"
MANIFEST_PATH="$BASE_DIR/manifest.json"
SIGNING_KEY="${2:-0101010101010101010101010101010101010101010101010101010101010101}"
COUNT="${3:-300}"

rm -rf "$BASE_DIR"
mkdir -p "$INPUT_DIR" "$RUNTIME_DIR"

python3 - <<'PY' "$INPUT_DIR" "$MANIFEST_PATH" "$COUNT"
import json
import os
import random
import sys

input_dir = sys.argv[1]
manifest_path = sys.argv[2]
count = int(sys.argv[3])

rng = random.Random(20260407)

def write_json(name, payload):
    path = os.path.join(input_dir, name)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)

def write_raw(name, raw):
    path = os.path.join(input_dir, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(raw)

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
                "metadata_json": "{}"
            }
        ]
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
                "metadata_json": "{}"
            },
            {
                "candidate_id": f"candidate-{i}-b",
                "model_name": "dummy-b",
                "model_version": "v2",
                "decision_status": "applied",
                "decision_reason": "accepted_runtime_intent_applied",
                "context_hash": f"ctx-{i}-b",
                "metadata_json": "{}"
            }
        ]
    }

def malformed_json(i):
    variants = [
        '{"stimulus_id": "broken"',
        '{"stimulus_id": 123',
        '{"candidates": [',
        '{ not-json }',
        '{"stimulus_id":"x","stimulus_hash":"y","candidates":'
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
    ("A_repairable_noise", "valid", 0.20),
    ("A_repairable_noise", "alias_status", 0.10),
    ("A_repairable_noise", "missing_metadata", 0.10),
    ("A_repairable_noise", "empty_context", 0.10),
    ("A_repairable_noise", "missing_stimulus_hash", 0.10),
    ("A_repairable_noise", "huge_metadata", 0.04),

    ("B_semantic_ambiguity", "alias_reason", 0.10),
    ("B_semantic_ambiguity", "invalid_reason", 0.07),
    ("B_semantic_ambiguity", "invalid_status", 0.07),

    ("C_hard_fail", "missing_candidates", 0.08),
    ("C_hard_fail", "malformed_json", 0.03),
    ("C_hard_fail", "multi_candidate", 0.01),
]

total = sum(w for _, _, w in profiles)
profiles = [(band, name, w / total) for band, name, w in profiles]

def choose_profile():
    r = rng.random()
    acc = 0.0
    for band, name, w in profiles:
        acc += w
        if r <= acc:
            return band, name
    return profiles[-1][0], profiles[-1][1]

manifest = {
    "generated_total": 0,
    "files": [],
    "band_counts": {},
    "profile_counts": {},
}

for i in range(1, count + 1):
    band, profile = choose_profile()
    manifest["generated_total"] += 1
    manifest["band_counts"][band] = manifest["band_counts"].get(band, 0) + 1
    manifest["profile_counts"][profile] = manifest["profile_counts"].get(profile, 0) + 1

    if profile == "valid":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, valid_payload(i))
    elif profile == "alias_status":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, alias_status_payload(i, rng.choice(status_aliases)))
    elif profile == "missing_metadata":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, missing_metadata_payload(i))
    elif profile == "empty_context":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, empty_context_payload(i))
    elif profile == "missing_stimulus_hash":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, missing_stimulus_hash_payload(i))
    elif profile == "huge_metadata":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, huge_metadata_payload(i))
    elif profile == "alias_reason":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, alias_reason_payload(i, rng.choice(reason_aliases)))
    elif profile == "invalid_reason":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, invalid_reason_payload(i))
    elif profile == "invalid_status":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, invalid_status_payload(i))
    elif profile == "missing_candidates":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, missing_candidates_payload(i))
    elif profile == "multi_candidate":
        name = f"{i:04d}_{band}_{profile}.json"
        write_json(name, multi_candidate_payload(i))
    elif profile == "malformed_json":
        name = f"{i:04d}_{band}_{profile}.json"
        write_raw(name, malformed_json(i))
    else:
        raise RuntimeError(profile)

    manifest["files"].append({
        "file": name,
        "band": band,
        "profile": profile,
    })

with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)
PY

cargo run -p mergen_control --bin run_measurement -- "$RUNTIME_DIR" "$INPUT_DIR" "$SIGNING_KEY" | tee "$REPORT_PATH"

python3 - <<'PY' "$MANIFEST_PATH" "$REPORT_PATH"
import json
import sys
from collections import defaultdict

manifest_path = sys.argv[1]
report_path = sys.argv[2]

with open(manifest_path, "r", encoding="utf-8") as f:
    manifest = json.load(f)

with open(report_path, "r", encoding="utf-8") as f:
    report = json.load(f)

processed = set(report.get("processed_files", []))
failed = set(report.get("failed_files", []))

band_totals = defaultdict(int)
band_success = defaultdict(int)
band_fail = defaultdict(int)
profile_totals = defaultdict(int)
profile_success = defaultdict(int)
profile_fail = defaultdict(int)

for entry in manifest["files"]:
    fn = entry["file"]
    band = entry["band"]
    profile = entry["profile"]

    band_totals[band] += 1
    profile_totals[profile] += 1

    if fn in processed:
        band_success[band] += 1
        profile_success[profile] += 1
    elif fn in failed:
        band_fail[band] += 1
        profile_fail[profile] += 1

def pct(a, b):
    return (a / b * 100.0) if b else 0.0

c = report["counters"]

print("")
print("===== BANDED REAL WORLD SUMMARY =====")
print(f"generated_total={manifest['generated_total']}")
print(f"execution_lane_success={c['execution_lane_success']}")
print(f"diagnostic_lane_reject={c['diagnostic_lane_reject']}")
print(f"diagnostic_lane_contradiction={c['diagnostic_lane_contradiction']}")
print(f"hard_fail_reject={c['hard_fail_reject']}")
print(f"success_runs={c['success_runs']}")
print(f"failed_runs={c['failed_runs']}")
print(f"success_rate_pct={pct(c['success_runs'], c['total_runs']):.2f}")
print(f"apply_failed={c['apply_failed']}")
print(f"trace_verify_failed={c['trace_verify_failed']}")
print(f"recover_failed={c['recover_failed']}")
print(f"auto_repair_attempted={c['auto_repair_attempted']}")
print(f"auto_repair_succeeded={c['auto_repair_succeeded']}")
print(f"auto_repair_failed={c['auto_repair_failed']}")
print("")

print("band_metrics=")
for band in sorted(band_totals.keys()):
    total = band_totals[band]
    succ = band_success[band]
    fail = band_fail[band]
    print(
        f"  {band}: total={total}, success={succ}, fail={fail}, success_rate_pct={pct(succ, total):.2f}"
    )

print("")
print("profile_metrics=")
for profile in sorted(profile_totals.keys()):
    total = profile_totals[profile]
    succ = profile_success[profile]
    fail = profile_fail[profile]
    print(
        f"  {profile}: total={total}, success={succ}, fail={fail}, success_rate_pct={pct(succ, total):.2f}"
    )

print("")
print("lane_outcomes=")
for k, v in sorted(report.get("lane_outcomes", {}).items(), key=lambda kv: (-kv[1], kv[0])):
    print(f"  {k}: {v}")

print("")
print("top_failure_reasons=")
for k, v in sorted(report.get("failure_reasons", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:12]:
    print(f"  {k}: {v}")

print("")
print("top_repair_chains=")
for k, v in sorted(report.get("repair_chains", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:12]:
    print(f"  {k}: {v}")

print("")
print("top_applied_repairs=")
for k, v in sorted(report.get("applied_repairs", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:12]:
    print(f"  {k}: {v}")
PY
