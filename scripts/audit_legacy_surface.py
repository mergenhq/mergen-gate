from pathlib import Path
import re
from collections import defaultdict

root = Path(".")
lib = root / "src/lib.rs"
tests_dir = root / "tests"

if not lib.exists():
    raise SystemExit("src/lib.rs bulunamadı")
if not tests_dir.exists():
    raise SystemExit("tests/ bulunamadı")

lib_text = lib.read_text()

pub_mods = set(re.findall(r'^\s*pub\s+mod\s+([A-Za-z_][A-Za-z0-9_]*)\s*;', lib_text, re.MULTILINE))

imports_by_test = defaultdict(set)
missing_by_test = defaultdict(set)
all_roots = set()

use_pattern = re.compile(r'^\s*use\s+mergen::([A-Za-z_][A-Za-z0-9_]*)', re.MULTILINE)

for path in sorted(tests_dir.glob("*.rs")):
    text = path.read_text()
    roots = set(use_pattern.findall(text))
    if not roots:
        continue

    imports_by_test[path.name] = roots
    for root_mod in roots:
        all_roots.add(root_mod)
        if root_mod not in pub_mods:
            missing_by_test[path.name].add(root_mod)

print("===== CRATE ROOT PUBLIC MODULES =====")
for mod in sorted(pub_mods):
    print(mod)

print()
print("===== TEST IMPORT ROOTS =====")
for test_name in sorted(imports_by_test):
    roots = ", ".join(sorted(imports_by_test[test_name]))
    print(f"{test_name}: {roots}")

print()
print("===== MISSING ROOT MODULES BY TEST =====")
if not missing_by_test:
    print("none")
else:
    for test_name in sorted(missing_by_test):
        roots = ", ".join(sorted(missing_by_test[test_name]))
        print(f"{test_name}: {roots}")

print()
print("===== MISSING ROOT MODULE SUMMARY =====")
summary = defaultdict(list)
for test_name, roots in missing_by_test.items():
    for root_mod in roots:
        summary[root_mod].append(test_name)

if not summary:
    print("none")
else:
    for root_mod in sorted(summary):
        tests = ", ".join(sorted(summary[root_mod]))
        print(f"{root_mod}: {tests}")
