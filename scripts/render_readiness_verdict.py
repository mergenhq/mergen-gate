import json
import sys

if len(sys.argv) != 2:
    print("usage: python3 scripts/render_readiness_verdict.py <report.json>")
    sys.exit(1)

report_path = sys.argv[1]

with open(report_path, "r", encoding="utf-8") as f:
    report = json.load(f)

c = report["counters"]
lanes = report.get("lane_outcomes", {})

total = c.get("total_runs", 0)
success = c.get("success_runs", 0)
failed = c.get("failed_runs", 0)

execution_lane_success = c.get("execution_lane_success", 0)
diagnostic_lane_reject = c.get("diagnostic_lane_reject", 0)
diagnostic_lane_contradiction = c.get("diagnostic_lane_contradiction", 0)
hard_fail_reject = c.get("hard_fail_reject", 0)

apply_failed = c.get("apply_failed", 0)
trace_verify_failed = c.get("trace_verify_failed", 0)
recover_failed = c.get("recover_failed", 0)

def pct(a, b):
    return (a / b * 100.0) if b else 0.0

overall_success_pct = pct(success, total)
execution_share_pct = pct(execution_lane_success, total)
diagnostic_share_pct = pct(diagnostic_lane_reject + diagnostic_lane_contradiction, total)
hard_fail_share_pct = pct(hard_fail_reject, total)

if apply_failed == 0 and trace_verify_failed == 0 and recover_failed == 0:
    integrity_status = "GREEN"
else:
    integrity_status = "RED"

if integrity_status == "GREEN" and execution_share_pct >= 60.0:
    deployment_verdict = "EXECUTION_READY_FOR_SEMI_STRUCTURED_INPUTS"
elif integrity_status == "GREEN" and diagnostic_share_pct >= 20.0:
    deployment_verdict = "DIAGNOSTIC_READY_BUT_NOT_GENERAL_EXECUTION_READY"
else:
    deployment_verdict = "NOT_READY_FOR_DEPLOYMENT"

if diagnostic_lane_contradiction >= diagnostic_lane_reject:
    primary_diagnostic_mode = "CONTRADICTION_HEAVY"
else:
    primary_diagnostic_mode = "UNKNOWN_SEMANTICS_HEAVY"

print("")
print("===== MERGEN READINESS VERDICT =====")
print(f"integrity_status={integrity_status}")
print(f"deployment_verdict={deployment_verdict}")
print(f"primary_diagnostic_mode={primary_diagnostic_mode}")
print("")
print("summary_metrics=")
print(f"  total_runs={total}")
print(f"  success_runs={success}")
print(f"  failed_runs={failed}")
print(f"  overall_success_pct={overall_success_pct:.2f}")
print("")
print("lane_metrics=")
print(f"  execution_lane_success={execution_lane_success} ({execution_share_pct:.2f}%)")
print(f"  diagnostic_lane_reject={diagnostic_lane_reject}")
print(f"  diagnostic_lane_contradiction={diagnostic_lane_contradiction}")
print(f"  diagnostic_total={diagnostic_lane_reject + diagnostic_lane_contradiction} ({diagnostic_share_pct:.2f}%)")
print(f"  hard_fail_reject={hard_fail_reject} ({hard_fail_share_pct:.2f}%)")
print("")
print("integrity_metrics=")
print(f"  apply_failed={apply_failed}")
print(f"  trace_verify_failed={trace_verify_failed}")
print(f"  recover_failed={recover_failed}")
print("")
print("top_failure_reasons=")
for k, v in sorted(report.get("failure_reasons", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:10]:
    print(f"  {k}: {v}")
print("")
print("top_repair_chains=")
for k, v in sorted(report.get("repair_chains", {}).items(), key=lambda kv: (-kv[1], kv[0]))[:10]:
    print(f"  {k}: {v}")
