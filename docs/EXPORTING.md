# Exporting

## Goal
Deterministically regenerate print artifacts in `exports/` from the canonical source in `src/`.

Canonical source:
- `src/test-hole-generator-v2.scad`

## OpenSCAD CLI
OpenSCAD supports headless export via CLI.

### Windows (recommended paths)
- OpenSCAD default install path is typically:
  - `C:\Program Files\OpenSCAD\openscad.exe`

### Git Bash (this workspace)
If running from Git Bash, the path is usually:
- `/c/Program Files/OpenSCAD/openscad.exe`

## Scripts
This repo includes convenience scripts:
- `scripts/export.sh` (Git Bash)
- `scripts/export.ps1` (PowerShell)

They export one or more known-good STL configurations into `exports/stl/`.

## Fonts
OpenSCAD’s GUI generally only sees system-installed fonts.

For deterministic CLI exports (and to support a “repo-local `fonts/` folder”), the export scripts pass `--fontdir` when a `fonts/` directory exists at the repo root.

You can override the fonts directory:
- Bash: `OPENSCAD_FONTDIR="/abs/path/to/fonts" ./scripts/export.sh`
- PowerShell: `./scripts/export.ps1 -FontDir "C:\\path\\to\\fonts"`

## Notes
- OpenSCAD output depends on `$fa`/`$fs` and CGAL; keep these stable for reproducible artifacts.
- If you change geometry-affecting defaults, bump the artifact filenames or add new ones.
