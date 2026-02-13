<p align="center">
	<img src="images/EWC3LabsLogo-blue-128x128.png" width="128" height="128" alt="EWC3 Labs"><br>
</p>

# EWC3 Labs Test Hole Generator (OpenSCAD)

Parametric test-hole plate generator for 3D printing.

This repo is intended to be cross-post friendly (GitHub + Printables + Thingiverse): source is in `src/`, and ready-to-print exports are in `exports/`.

## Photos
- `images/printed_plate_1.jpg` (REQUIRED before public release)
- Optional: `images/printed_plate_2.jpg`

## Print settings (known-good baseline)

| Setting | Value |
|---|---|
| Nozzle | 0.4 mm |
| Layer height | 0.2 mm |
| Material | PLA (baseline) |
| Walls/perimeters | 4 |
| Infill | 20% |
| Supports | No |
| Brim | Outside / Mouse Ears, .02 spacing |
| Orientation | Flat on bed |

### First layer (critical for test-hole accuracy)
Elephant’s foot will undersize holes and can force you to deburr dozens of edges.

- Elephant foot compensation (e.g., OrcaSlicer) SHOULD be set unusually high for this part.
- If your slicer uses “First layer X-Y compensation” (or similar wording), use that.
- A starting point is **0.5 mm**; tune up/down for your material and first-layer squish.
- A brim SHOULD be used on plates this large to prevent warping; “easy to separate” brims defeat the purpose so space the brim .02 from the part so it actually sticks.

## Files

### Ready-to-print (download these)
- `exports/stl/` — STL plates (example configurations)

### Source (edit these)
- `src/test-hole-generator-v2.scad` — canonical OpenSCAD source (hybrid trapezoid/rectangle)
- `src/test-hole-generator-v2.json` — Customizer presets (useful printable configurations)
- `_ARCHIVE/src/` — older entrypoints kept for reference

## What it generates
A plate with rows of increasing hole sizes (circle/square/hex), with readable row labels.

Key features:
- Fully parametric (OpenSCAD Customizer-friendly)
- Multiple hole shapes (`circle`, `square`, `hexagon`)
- Row labels so you can quickly identify a fit

## Customize
Open `src/test-hole-generator-v2.scad` in OpenSCAD and use the Customizer to change:
- size range (`initial_hole_size`, `final_hole_size`, `hole_step_size`)
- hole count per row (`holes_per_row`)
- spacing, margins, and plate thickness
- `hole_type` (circle/square/hexagon)
- `plate_shape` (rectangle/trapezoid)
- `typeface_preset` (e.g., `arial_black` on Windows, `liberation_sans_bold` on most Linux)

## Export
- See [docs/EXPORTING.md](docs/EXPORTING.md)

## Cross-posting
- See [docs/CROSS_POSTING.md](docs/CROSS_POSTING.md)

## License
MIT. See [LICENSE](LICENSE).

When cross-posting to Thingiverse/Printables, select the MIT license to match.
