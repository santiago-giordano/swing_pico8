#!/usr/bin/env bash
# Builds the headless test rig: fake-08 (libretro core) patched with a
# PCM channel (serial 0x808) so the PCM carts can be heard, plus a tiny
# libretro frontend that runs scripted input, saves screenshots and WAVs.
#
# The patch is for TESTING ONLY: stock fake-08 has no PCM output.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$HERE/.work"
FAKE08_COMMIT=814991a2571ad3970e386cef48f3b148aa1c27b9
mkdir -p "$WORK"
if [ ! -d "$WORK/fake-08" ]; then
  git clone -q https://github.com/jtothebell/fake-08.git "$WORK/fake-08"
  git -C "$WORK/fake-08" checkout -q "$FAKE08_COMMIT"
  git -C "$WORK/fake-08" submodule update --init --depth 1 -q
  git -C "$WORK/fake-08" apply "$HERE/fake08-test.patch"
fi
make -C "$WORK/fake-08/platform/libretro" -j"$(nproc)" >/dev/null
gcc -O2 -w -I"$WORK/fake-08/platform/libretro" -o "$WORK/front" "$HERE/harness/front.c" -ldl
echo "ok: $WORK/front + fake08_libretro.so"
