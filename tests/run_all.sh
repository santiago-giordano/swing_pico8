#!/usr/bin/env bash
# Builds the carts and runs every test against the patched fake-08 rig.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 build.py
[ -x tests/.work/front ] || bash tests/setup.sh
for t in test_timing test_groove test_sync test_live_edit test_mix; do
  echo "== $t"
  python3 "tests/$t.py"
done
python3 tests/screens.py >/dev/null
echo "all tests ok"
