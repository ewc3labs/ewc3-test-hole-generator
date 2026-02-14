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

# Quality controls
# By default, the SCAD file's $fa/$fs are used.
# To speed up CI or quick local exports, you can override them:
#   OPENSCAD_FA=12 OPENSCAD_FS=1 ./scripts/export.sh
SCAD_GLOBAL_ARGS=()
if [[ -n "${OPENSCAD_FA:-}" ]]; then
  SCAD_GLOBAL_ARGS+=( -D "\$fa=${OPENSCAD_FA}" )
fi
if [[ -n "${OPENSCAD_FS:-}" ]]; then
  SCAD_GLOBAL_ARGS+=( -D "\$fs=${OPENSCAD_FS}" )
fi

export_one() {
  local out="$1"; shift
  "$OPENSCAD_EXE" "${FONTDIR_ARGS[@]}" "${SCAD_GLOBAL_ARGS[@]}" -o "$OUT_DIR/$out" "$SRC" "$@"
}

# Canonical export preset (keep stable; do not rely on SCAD defaults)
COMMON_ARGS=(
  -D holes_per_row=10
  -D hole_spacing=3.0
  -D plate_shape='"trapezoid"'
  -D plate_thickness=5.0
  -D text_size=4.0
  -D top_text_scale=0.85
  -D text_height=-1.5
  -D left_margin=3.0
  -D right_margin=3.0
  -D top_margin=3.0
  -D bottom_margin=3.0
  -D label_padding=1.0
  -D typeface_preset='"liberation_sans_bold"'
  -D typeface_custom='"Liberation Sans:style=Bold"'
)

# Example exports matching the historical naming pattern.
# NOTE: hole_type values: circle, square, hexagon

export_one "Test_Hole_Generator_Circle70to1095step05.stl" \
  "${COMMON_ARGS[@]}" \
  -D initial_hole_size=7 -D final_hole_size=10.95 -D hole_step_size=0.05 -D hole_type='"circle"'

export_one "Test_Hole_Generator_Hex50to1095step05.stl" \
  "${COMMON_ARGS[@]}" \
  -D initial_hole_size=5 -D final_hole_size=10.95 -D hole_step_size=0.05 -D hole_type='"hexagon"'

export_one "Test_Hole_Generator_Circle30to695step05.stl" \
  "${COMMON_ARGS[@]}" \
  -D initial_hole_size=3 -D final_hole_size=6.95 -D hole_step_size=0.05 -D hole_type='"circle"'

echo "OK: exported STLs to $OUT_DIR"
