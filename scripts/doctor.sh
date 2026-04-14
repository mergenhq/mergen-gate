#!/usr/bin/env bash
set -euo pipefail

echo "=== MERGEN REPO DOCTOR ==="
echo

echo "[1/4] discovery"
./scripts/test_discovery.sh
echo

echo "[2/4] discovery ci"
./scripts/ci_discovery.sh
echo

echo "[3/4] hygiene"
./scripts/repo_hygiene_check.sh
echo

echo "[4/4] legacy status"
./scripts/test_legacy.sh
echo

echo "=== REPO SUMMARY ==="
echo "Active contract:"
echo "  docs/contracts/discovery_contract.md"
echo
echo "Freeze decision:"
echo "  docs/decisions/discovery_freeze_decision.md"
echo
echo "Trace surface:"
echo "  scripts/show_discovery_trace.sh"
echo
echo "Trace export surface:"
echo "  scripts/export_discovery_trace.sh"
echo
echo "Trace snapshot contract:"
echo "  tests/fixtures/discovery_trace_canonical.json"
echo
echo "Trace artifact surface:"
echo "  scripts/write_discovery_trace_artifact.sh"
echo
echo "Trace diff surface:"
echo "  scripts/diff_discovery_trace.sh"
echo
echo "Trace archive surface:"
echo "  scripts/archive_discovery_trace.sh"
echo
echo "Trace history listing:"
echo "  scripts/list_discovery_trace_history.sh"
echo
echo "Trace manifest surface:"
echo "  artifacts/discovery_trace_manifest.ndjson"
echo
echo "Trace verify surface:"
echo "  scripts/verify_discovery_trace_manifest.sh"
echo
echo "Artifact root override:"
echo "  MERGEN_DISCOVERY_ARTIFACT_ROOT"
echo
echo "Artifact governance:"
echo "  docs/decisions/discovery_trace_artifact_governance.md"
echo
echo "Next phase:"
echo "  docs/roadmap/next_phase_plan.md"
echo
echo "Kernel identity:"
echo "  docs/roadmap/discovery_kernel_identity.md"
