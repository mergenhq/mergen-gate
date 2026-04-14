#!/usr/bin/env bash
set -euo pipefail

echo "=== MERGEN RELEASE DOCTOR ==="

echo
echo "[1/5] discovery contract"
./scripts/ci_discovery.sh

echo
echo "[2/5] trace contract"
./scripts/ci_trace.sh

echo
echo "[3/5] hygiene"
./scripts/repo_hygiene_check.sh

echo
echo "[4/5] trace manifest verify"
./scripts/verify_discovery_trace_manifest.sh

echo
echo "[5/5] legacy lane status"
./scripts/test_legacy.sh

echo
echo "=== RELEASE SUMMARY ==="
echo "Discovery contract:"
echo "  docs/contracts/discovery_contract.md"
echo
echo "Trace operational contract:"
echo "  docs/contracts/discovery_trace_operational_contract.md"
echo
echo "Artifact governance:"
echo "  docs/decisions/discovery_trace_artifact_governance.md"
echo
echo "Freeze decision:"
echo "  docs/decisions/discovery_freeze_decision.md"
echo
echo "Roadmap:"
echo "  docs/roadmap/next_phase_plan.md"
