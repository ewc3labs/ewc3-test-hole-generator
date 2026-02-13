// EWC3Labs Hole Size Test Plate Generator
// https://youtube.com/@EWC3Labs
// https://buymeacoffee.com/ewc3labs
//
// This tool was created out of sheer frustration at the number of 
// "test hole" and "hex nut size" STL files on the internet
// that were either incomplete, poorly labeled, fixed-size, 
// or only available for a handful of metrics.
// EWC3Labs' version is fully parametric, supports circle, 
// square, and hex holes, includes readable labels,
// and is customizable without touching code thanks to 
// OpenSCAD's Customizer.
//
// Designed by Wilson Cook
// Last updated: 2025-06-07

// Parameters

// Distance from the left edge to first hole
left_margin = 15; // [0:0.1:100]

// Distance from the last hole to the right edge
right_margin = 3; // [0:0.1:100]

// Distance from the top edge to the top row
top_margin = 3; // [0:0.1:100]

// Distance from the bottom row to the bottom edge
bottom_margin = 3; // [0:0.1:100]

// Size of the smallest hole
start_size = 5; // [0:0.01:200]

// Size increase per hole
step_size = 0.05; // [0.001:0.001:10]

// Final hole size (inclusive)
end_size = 8.95; // [0:0.01:200]

// Number of holes per horizontal row
holes_per_row = 10; // [1:1:50]

// Distance between holes
hole_spacing = 3; // [0:0.1:50]

// Plate thickness in mm
plate_thickness = 5; // [0.2:0.1:30]

// Hole shape: choose from dropdown
shape_type = "hexagon";  // [circle, square, hexagon]

// Height of the embossed label text
text_height = 5; // [0.5:0.1:20]

// Font settings (OpenSCAD does not support font dropdowns).
// Note: If a font isn't visible in OpenSCAD, it must be installed system-wide or provided via OpenSCAD CLI `--fontdir`.
// Examples: "Liberation Sans:style=Bold", "Liberation Serif:style=Bold", "DejaVu Sans:style=Bold"
typeface = "Liberation Sans:style=Bold";

// Depth of label engraving into plate
text_depth = 1; // [0:0.1:10]

// Guardrails (Customizer ranges help, but `-D` overrides can still break things)
assert(left_margin >= 0 && right_margin >= 0 && top_margin >= 0 && bottom_margin >= 0,
    "Margins must be >= 0");
assert(start_size >= 0 && end_size >= 0,
    "Hole sizes must be >= 0");
assert(end_size >= start_size,
    "end_size must be >= start_size");
assert(step_size > 0,
    "step_size must be > 0");
assert(holes_per_row >= 1,
    "holes_per_row must be >= 1");
assert(hole_spacing >= 0,
    "hole_spacing must be >= 0");
assert(plate_thickness > 0,
    "plate_thickness must be > 0");
assert(text_height >= 0,
    "text_height must be >= 0");
assert(text_depth >= 0 && text_depth <= plate_thickness,
    "text_depth must be between 0 and plate_thickness");

// Rendering quality controls
// NOTE: Do not include these in the Customizer. Adding $fa/$fs
// to the GUI causes unexpected render behavior or fails silently.
$fa = $preview ? 6 : 3;
$fs = $preview ? 2 : 0.25;

// Derived values
total_holes = ceil(((end_size - start_size) / step_size) + 1);
number_of_rows = ceil(total_holes / holes_per_row);

plate_width = left_margin + right_margin + 
    (holes_per_row * (end_size + hole_spacing)) - hole_spacing;
plate_height = top_margin + bottom_margin + 
    (number_of_rows * (end_size + hole_spacing)) - hole_spacing;

// Function to generate a cutout of the specified shape
module generate_cutout(shape_type, x, y, w, h) {
    translate([x, y, 0])
    linear_extrude(height = h) {
        if (shape_type == "circle") {
            circle(d = w);
        } else if (shape_type == "square") {
            square([w, w], center = true);
        } else if (shape_type == "hexagon") {
            radius = w / sqrt(3);
            polygon(points=[
                [radius, 0],
                [radius/2, w/2],
                [-radius/2, w/2],
                [-radius, 0],
                [-radius/2, -w/2],
                [radius/2, -w/2]
            ]);
        }
    }
}

// Recursive function to layout holes and add size labels
module generate_holes_recursive(hole_num, max_holes) {
    if (hole_num < max_holes) {
        row = floor(hole_num / holes_per_row);
        col = hole_num % holes_per_row;

        x = left_margin + col * (end_size + hole_spacing) + 
            end_size / 2;
        y = bottom_margin + row * (end_size + hole_spacing) + 
            end_size / 2;

        hole_size = start_size + hole_num * step_size;

        // Debug output
        echo(str("hole_num: ", hole_num, 
            " row: ", row, 
            " col: ", col, 
            " hole_size: ", hole_size, 
            " position: [", x, ",", y, "]"));

        // Generate the hole shape
        generate_cutout(shape_type, x, y, hole_size, 
                        plate_thickness);

        // Label only at the start of each row
        if (col == 0) {
            translate([2, y - (text_height / 2), 
                      plate_thickness - text_depth])
            linear_extrude(height = 3)
            text(str(hole_size), size = text_height, 
                 font = typeface);
        }

        generate_holes_recursive(hole_num + 1, max_holes);
    }
}

// Main helper module
module generate_plate_with_cutouts() {
    difference() {
        cube([plate_width, plate_height, plate_thickness]);
        generate_holes_recursive(0, total_holes);
    }
}

// Execute build
generate_plate_with_cutouts();
