#!/usr/bin/env bash
set -euo pipefail

# Exports known-good STL variants into exports/stl/
# Usage:
#   OPENSCAD_EXE="/c/Program Files/OpenSCAD/openscad.exe" ./scripts/export.sh
#+#+#+#+
# Fonts:
#   By default, this script uses "$ROOT_DIR/fonts" (if present).
#   Override with:
#     OPENSCAD_FONTDIR="/abs/path/to/fonts" ./scripts/export.sh

if [[ -z "${OPENSCAD_EXE:-}" ]]; then
  if command -v openscad >/dev/null 2>&1; then
    OPENSCAD_EXE="openscad"
  else
    # Windows Git Bash typical install path
    OPENSCAD_EXE="/c/Program Files/OpenSCAD/openscad.exe"
  fi
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC="$ROOT_DIR/src/test-hole-generator-v2.scad"
OUT_DIR="$ROOT_DIR/exports/stl"

OPENSCAD_FONTDIR=${OPENSCAD_FONTDIR:-$ROOT_DIR/fonts}

FONTDIR_ARGS=()
if [[ -d "$OPENSCAD_FONTDIR" ]]; then
  if command -v cygpath >/dev/null 2>&1; then
    FONTDIR_ARGS=(--fontdir "$(cygpath -w "$OPENSCAD_FONTDIR")")
  else
    FONTDIR_ARGS=(--fontdir "$OPENSCAD_FONTDIR")
  fi
fi

mkdir -p "$OUT_DIR"

export_one() {
  local out="$1"; shift
  "$OPENSCAD_EXE" "${FONTDIR_ARGS[@]}" -o "$OUT_DIR/$out" "$SRC" "$@"
}

# Example exports matching the historical naming pattern.
# NOTE: hole_type values: circle, square, hexagon

export_one "Test_Hole_Generator_Circle50to1095step05.stl" \
  -D initial_hole_size=5 -D final_hole_size=10.95 -D hole_step_size=0.05 -D hole_type='"circle"'

export_one "Test_Hole_Generator_Hex50to1095step05.stl" \
  -D initial_hole_size=5 -D final_hole_size=10.95 -D hole_step_size=0.05 -D hole_type='"hexagon"'

export_one "Test_Hole_Generator_Circle30to995step05.stl" \
  -D initial_hole_size=3 -D final_hole_size=9.95 -D hole_step_size=0.05 -D hole_type='"circle"'

echo "OK: exported STLs to $OUT_DIR"
