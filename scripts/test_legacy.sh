#!/usr/bin/env bash
set -euo pipefail

echo "LEGACY TEST LANE"
echo "Bu lane aktif değil."
echo "Sebep: orphan legacy testler mevcut crate surface'inde olmayan modülleri hedefliyor."
echo
echo "Detay:"
echo "  docs/legacy_test_quarantine.md"
echo
echo "Quarantined files:"
find tests_legacy_orphan -maxdepth 1 -type f -name "*.rs" | sort || true
