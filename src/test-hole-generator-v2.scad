// EWC3 Test Hole Generator — V2 (trapezoid/rectangle hybrid)
// License: MIT (see LICENSE)
//
// Notes:
// - This variant supports both rectangle and trapezoid plates.
// - It intentionally generates full rows (even if the final row would be partial)
//   so printed plates look consistent.
// - Font defaults assume you distribute a local `fonts/` folder and/or use
//   OpenSCAD CLI `--fontdir` for deterministic exports.
//
// Origin: evolved from the trapezoid generator workbench version.

// Shape of the holes (Options: "circle", "square", "hexagon")
hole_type = "hexagon"; // [circle, square, hexagon]
// Start with this size
initial_hole_size = 5; // [0:0.01:200]
// Go up to at least this size (make complete rows)
final_hole_size = 6.75; // [0:0.01:200]
// Make each hole this much bigger
hole_step_size = 0.25; // [0.001:0.001:10]
// Number of holes per row
holes_per_row = 4; // [1:1:50]
// Spacing between holes
hole_spacing = 3.0; // [0:0.1:50]
// Thickness of the plate
plate_thickness = 5.0; // [0.2:0.1:30]
// Shape of the plate and hole grid. May save some filament using trapezoid.
plate_shape = "rectangle"; // [trapezoid, rectangle]
// Height of the embossed text
text_size = 5.0; // [0.5:0.1:20]
// Top labels (column offsets) are rendered smaller than row labels
top_text_scale = 0.85; // [0.30:0.05:1.50]
// Padding between the label block and the first column of holes
label_padding = 1.0; // [0:0.1:25]
// Typeface preset (avoids font-install docs; pick what your OS likely has)
typeface_preset = "liberation_sans_bold"; // [liberation_sans_bold,dejavu_sans_bold,noto_sans_bold,arial_black,custom]
// Custom typeface string (used when typeface_preset="custom")
// OpenSCAD font syntax is typically: "Family Name:style=Bold".
typeface_custom = "Liberation Sans:style=Bold";
// Depth of the embossed text (positive = raised, negative = engraved)
text_height = 1.0; // [-5:0.1:5]
// Left margin of the plate
left_margin = 3.00; // [0:0.1:100]
// Right margin of the plate
right_margin = 3.00; // [0:0.1:100]
// Top margin of the plate
top_margin = 3.00; // [0:0.1:100]
// Bottom margin of the plate
bottom_margin = 3.00; // [0:0.1:100]

// Estimated label width is heuristic (OpenSCAD doesn't expose real text metrics).
// `left_margin` is margin to the LEFT of labels.
// `label_padding` is spacing BETWEEN labels and the hole grid.
label_width_scale = 1.05;

// For geometry helpers
inf = 1e200 * 1e200;

// Guardrails (Customizer ranges help, but `-D` overrides can still break things)
assert(initial_hole_size >= 0 && final_hole_size >= 0,
    "Hole sizes must be >= 0");
assert(final_hole_size >= initial_hole_size,
    "final_hole_size must be >= initial_hole_size");
assert(hole_step_size > 0,
    "hole_step_size must be > 0");
assert(holes_per_row >= 1,
    "holes_per_row must be >= 1");
assert(hole_spacing >= 0,
    "hole_spacing must be >= 0");
assert(plate_thickness > 0,
    "plate_thickness must be > 0");
assert(left_margin >= 0 && right_margin >= 0 && top_margin >= 0 && bottom_margin >= 0,
    "Margins must be >= 0");
assert(text_size > 0,
    "text_size must be > 0");
assert(label_padding >= 0,
    "label_padding must be >= 0");
assert(top_text_scale > 0,
    "top_text_scale must be > 0");

function resolve_typeface(preset, custom) =
    (preset == "arial_black") ? "Arial Black" :
    (preset == "dejavu_sans_bold") ? "DejaVu Sans:style=Bold" :
    (preset == "noto_sans_bold") ? "Noto Sans:style=Bold" :
    (preset == "custom") ? custom :
    "Liberation Sans:style=Bold";

typeface = resolve_typeface(typeface_preset, typeface_custom);

// Set arc fragment angle for preview and render:
// Note: Very small $fa/$fs values can explode render time for circle-heavy plates.
$fa = $preview ? 12 : 5;
$fs = $preview ? 1 : 0.25;

// Calculate number of holes and rows
total_holes = ceil(((final_hole_size - initial_hole_size) / hole_step_size) + 1);
number_of_rows = ceil(total_holes / holes_per_row);

// Helper functions

// Return the first row index
function first_row() = 0;

// Return the last row index
function last_row() = number_of_rows - 1;

// Return the row index for a given hole
function row_index(hole_num) = floor(hole_num / holes_per_row);

// Return the column index for a given hole
function col_index(hole_num) = hole_num % holes_per_row;

// Return the hole number for a given row and column
function hole_number(row, col) = row * holes_per_row + col;

// Calculate hole size of a specific hole number
function hole_size(hole_num) = initial_hole_size + (hole_num * hole_step_size);

// Calculate the ACTUAL width of a specific hole
function hole_width(hole_num) = 
    hole_type == "hexagon" ? 
        hole_size(hole_num) * 2 / sqrt(3) : 
        hole_size(hole_num); // Default case

// Calculate the MEASURED width of a specific hole (if trapezoid then actual width; if rectangle then width of largest hole in the plate)
function measured_hole_width(hole_num) = 
    (plate_shape == "rectangle") ? 
        hole_width(last_hole(number_of_rows - 1)) : 
        hole_width(hole_num);

// Calculate the height of a specific hole
function hole_height(hole_num) = hole_size(hole_num); // For now, only circles, squares, and hexagons are considered, and they are all equal in height

// Find the last hole number in a row
function last_hole(row_num) = row_num * holes_per_row + holes_per_row - 1;

// Calculate the row height of a specific row number (which is the height of the largest (last) hole in the row)
function row_height(row_num) = hole_height(last_hole(row_num));

// Each row is a "band" that must fit the hole AND the row label.
row_text_band_scale = 1.10;
function row_band_height(row_num) = max(row_height(row_num), text_size * row_text_band_scale);

top_text_size = text_size * top_text_scale;

// Top labels live in their own band (with padding) so they don't clip.
top_label_padding = hole_spacing;
top_label_band_height = top_text_size * row_text_band_scale;

// RECURSIVE Calculate the sum of all row heights up to a specific row number
function sum_row_heights(row_num) = 
    row_num == undef || row_num < 0 ? 
        0 : 
        row_height(row_num) + sum_row_heights(row_num - 1);

function sum_row_band_heights(row_num) =
    row_num == undef || row_num < 0 ?
        0 :
        row_band_height(row_num) + sum_row_band_heights(row_num - 1);

// Return the first hole number in a row
function first_hole(row_num) = row_num * holes_per_row;

// Return the last hole number in a row (always full rows)
function last_hole(row_num) = first_hole(row_num) + holes_per_row - 1;

// Recursive function to return the weighted sum of text length for each character in a string.
// If a character is "1" or ".", it is weighted as 0.5, else 1.
function weighted_sum_text_length(text, index) = 
    (index == undef || index >= len(text)) ? 
        0 : 
    let (
        current_char = text[index],
        current_weight = (current_char == "1" || current_char == ".") ? 0.5 : 1
    ) current_weight + weighted_sum_text_length(text, index + 1);

// Recursive function to find the longest text string among all rows
function longest_text_length(row_num, max_rows, longest_so_far) = 
    (row_num == undef || max_rows == undef || row_num >= max_rows) ? 
        longest_so_far : 
    let (
        current_text = str(hole_size(row_num * holes_per_row)),
        current_length = weighted_sum_text_length(current_text, 0),
        new_longest = (longest_so_far == undef || current_length > longest_so_far[1]) ? [current_text, current_length] : longest_so_far
    ) longest_text_length(row_num + 1, max_rows, new_longest);

// Calculate the longest text label width and adjust left margin
longest_label = longest_text_length(0, number_of_rows, [hole_width(0),0]);
longest_label_width = (longest_label[1] * text_size * label_width_scale);
left_margin_adj = left_margin + longest_label_width + label_padding;

// RECURSIVE calculate the sum of hole widths in a row
function add_hole_widths(from_hole, to_hole) = 
    (from_hole == undef || to_hole == undef || from_hole > to_hole) ? 
        0 : 
        measured_hole_width(from_hole) + add_hole_widths(from_hole + 1, to_hole);

// Calculate the width of a specific row
function row_width(row_num) = 
    left_margin_adj + 
    right_margin + 
    add_hole_widths(first_hole(row_num), last_hole(row_num)) + 
    (holes_per_row - 1) * hole_spacing;

// Calculate the height of the trapezoid (sum of all row heights plus spacing between rows plus top and bottom margins)
function trapezoid_height() = 
    sum_row_band_heights(number_of_rows - 1)
    + (number_of_rows - 1) * hole_spacing
    + top_label_padding
    + top_label_band_height
    + top_margin
    + bottom_margin;

// Calculate the y coordinate for the centerline of given row number
function row_center(row_num) = 
    bottom_margin + 
    sum_row_band_heights(row_num) +
    ((row_num <= 0) ? 0 : row_num) * hole_spacing  
    - row_band_height(row_num) / 2;

// Convenience helpers for row extents
function row_bottom(row_num) = row_center(row_num) - (row_band_height(row_num) / 2);
function row_top(row_num) = row_center(row_num) + (row_band_height(row_num) / 2);

// Hole extents within a row (excludes label-only band). Using these for the
// trapezoid edge fit avoids over-constraining the right edge when text bands
// are taller than the holes.
function row_hole_bottom(row_num) = row_center(row_num) - (row_height(row_num) / 2);
function row_hole_top(row_num) = row_center(row_num) + (row_height(row_num) / 2);

function clamp_safe(v, lo, hi) = (hi < lo) ? lo : min(max(v, lo), hi);

// Column-center X positions (based on row 0 so the offsets align with the size progression)
function col_center_x_for_row(row, col) =
    (col == undef || col <= 0) ?
        left_margin_adj + measured_hole_width(hole_number(row, 0)) / 2 :
        col_center_x_for_row(row, col - 1)
            + measured_hole_width(hole_number(row, col - 1)) / 2
            + hole_spacing
            + measured_hole_width(hole_number(row, col)) / 2;

// Format a value to two decimals with a leading '.' when < 1
function fmt_fixed2(v) =
    let(
        scaled = round(v * 100),
        ip = floor(scaled / 100),
        fp = scaled - ip * 100,
        fp2 = (fp < 10) ? str("0", fp) : str(fp)
    ) (ip == 0) ? str(".", fp2) : str(ip, ".", fp2);

top_text_y = row_top(last_row()) + top_label_padding + top_label_band_height / 2;

// Calculate the slope of a line given two points
function slope(x1, y1, x2, y2) = (y2 - y1) / (x2 - x1);

// Calculate the x-intercept of a line given a point and the slope
function x_intercept(x, y, m) = x - y / m;

// Calculate the x-intercept of a line given two points
function x_intercept_two_points(x1, y1, x2, y2) = x_intercept(x1, y1, slope(x1, y1, x2, y2));

// Calculate the intersection point of two lines given a point and slope for each line
function intersection_point(x1, y1, m1, x2, y2, m2) = 
    (m1 == inf) ? [x1, y2] :
    (m2 == inf) ? [x2, y1] :
    [(y2 - y1 + m1 * x1 - m2 * x2) / (m1 - m2),
    y1 + m1 * ((y2 - y1 + m1 * x1 - m2 * x2) / (m1 - m2) - x1)
];

// Calculate the intersection point of two lines given two points for each line
function intersection_point_two_points(x1, y1, x2, y2, x3, y3, x4, y4) = 
    intersection_point(
        x1, y1, slope(x1, y1, x2, y2), 
        x3, y3, slope(x3, y3, x4, y4)
    );

// --- Plate boundary helpers ---

function max_list(values) = (values == undef || len(values) == 0) ? 0 : max(values);

// Safe index list helper: avoids deprecated ranges like [0:-1]
function idx0(count) = (count == undef || count <= 0) ? [] : [0:count - 1];

function right_edge_c_for_a(a) =
    max_list([for (r = idx0(number_of_rows)) row_width(r) - a * row_hole_bottom(r)]);

function right_edge_area_for_a(a) =
    let(
        H = trapezoid_height(),
        c = right_edge_c_for_a(a)
    ) H * (2 * c + a * H) / 2;

function best_right_edge(candidates, idx, best) =
    (idx == undef || candidates == undef || idx >= len(candidates)) ?
        best :
    let(
        a = candidates[idx],
        c = right_edge_c_for_a(a),
        area = right_edge_area_for_a(a),
        best2 = (best == undef || area < best[0]) ? [area, a, c] : best
    ) best_right_edge(candidates, idx + 1, best2);

function candidate_slopes() =
    concat(
        [0],
        [
            for (i = idx0(number_of_rows))
            for (j = idx0(number_of_rows))
            let(
                yi = row_hole_bottom(i),
                yj = row_hole_bottom(j),
                xi = row_width(i),
                xj = row_width(j),
                dy = yj - yi
            ) if (j > i && dy > 0) max(0, (xj - xi) / dy)
        ]
    );

best_edge = best_right_edge(candidate_slopes(), 0, undef);
right_edge_a = best_edge[1];
right_edge_c = best_edge[2];

function rectangle_points() =
    let(
        H = trapezoid_height(),
        W = max_list([for (r = idx0(number_of_rows)) row_width(r)])
    ) [[0, 0], [W, 0], [W, H], [0, H]];

function trapezoid_points() =
    let(
        H = trapezoid_height(),
        x0 = right_edge_c,
        xH = right_edge_a * H + right_edge_c,
        top_row = last_row(),
        top_last_col = holes_per_row - 1,
        top_last_hole = hole_number(top_row, top_last_col),
        top_last_center_x = col_center_x_for_row(top_row, top_last_col),
        top_last_measured_w = measured_hole_width(top_last_hole),
        // "Cell" right edge ≈ hole right edge plus half the inter-hole spacing.
        // This gives a reasonable pad so the right wall isn't kissing the hole.
        cell_pad = (holes_per_row > 1) ? (hole_spacing / 2) : 0,
        x_vert_raw = top_last_center_x + (top_last_measured_w / 2) + cell_pad + right_margin,
        // Never cut left of the trapezoid's bottom-right x.
        x_vert = max(x_vert_raw, x0),
        y_int_raw = (right_edge_a == 0) ? H : ((x_vert - right_edge_c) / right_edge_a),
        y_int = clamp_safe(y_int_raw, 0, H)
    )
    // Prevent a sharp/acute top-right corner by truncating the slanted edge
    // with a vertical segment located near the top-right hole's cell.
    (right_edge_a == 0 || x_vert >= xH || y_int >= H) ?
        [[0, 0], [x0, 0], [xH, H], [0, H]] :
        [[0, 0], [x0, 0], [x_vert, y_int], [x_vert, H], [0, H]];

function plate_points() = (plate_shape == "rectangle") ? rectangle_points() : trapezoid_points();

// Module to generate cutout shapes
module generate_cutout(hole_type, x, y, w, h, d) {
    translate([x, y, 0])
    linear_extrude(height = d) {
        if (hole_type == "circle") {
            circle(d = w);
        } else if (hole_type == "square") {
            square([w, w], center = true);
        } else if (hole_type == "hexagon") {
            // Regular hexagon using point-to-point diameter w (circumdiameter)
            radius = w / 2;
            polygon(points=[
                [radius * cos(0), radius * sin(0)],
                [radius * cos(60), radius * sin(60)],
                [radius * cos(120), radius * sin(120)],
                [radius * cos(180), radius * sin(180)],
                [radius * cos(240), radius * sin(240)],
                [radius * cos(300), radius * sin(300)]
            ]);
        }
    }
}

// Module to generate text
module generate_text(hole_size, y) {
    z_offset = (text_height > 0) ? 0 : text_height;
    translate([left_margin, y, plate_thickness + z_offset])
    linear_extrude(height = abs(text_height))
    text(str(hole_size), size = text_size, font=typeface, halign="left", valign="center");
}

module generate_top_text(col) {
    z_offset = (text_height > 0) ? 0 : text_height;
    x = col_center_x_for_row(last_row(), col);
    y = top_text_y;
    translate([x, y, plate_thickness + z_offset])
    linear_extrude(height = abs(text_height))
    text(fmt_fixed2(col * hole_step_size), size = top_text_size, font=typeface, halign="center", valign="center");
}

module generate_origin_text() {
    z_offset = (text_height > 0) ? 0 : text_height;
    x = left_margin;
    y = top_text_y;
    translate([x, y, plate_thickness + z_offset])
    linear_extrude(height = abs(text_height))
    text("+", size = top_text_size, font=typeface, halign="left", valign="center");
}

// Recursive function to create the text labels for each row
module generate_row_text_recursive(row_num, max_rows) {
    if (row_num == undef || max_rows == undef) {
        echo("ERROR generate_row_text_recursive(): row_num or max_rows undefined; cannot generate text");
    } else {
        if (row_num < max_rows) {
            current_hole_size = hole_size(row_num * holes_per_row);
            y = row_center(row_num);
            generate_text(current_hole_size, y);
            generate_row_text_recursive(row_num + 1, max_rows);
        }
    }
}

module generate_col_text_recursive(col, max_cols) {
    if (col == undef || max_cols == undef) {
        echo("ERROR generate_col_text_recursive(): col or max_cols undefined; cannot generate top labels");
    } else {
        if (col < max_cols) {
            if (col == 0) {
                generate_origin_text();
            }
            generate_top_text(col);
            generate_col_text_recursive(col + 1, max_cols);
        }
    }
}

// Recursive function to create the holes
module generate_holes_recursive(hole_num, max_holes, last_x, last_y, last_hole_width, last_measured_hole_width, last_hole_height) {
    if (hole_num == undef || max_holes == undef) {
        echo("ERROR generate_holes_recursive(): hole_num or max_holes undefined; cannot generate holes");
    } else {
        if (hole_num < max_holes) {
            current_hole_width = hole_width(hole_num);
            current_measured_hole_width = measured_hole_width(hole_num);
            current_hole_height = hole_height(hole_num);

            row = row_index(hole_num);
            col = col_index(hole_num);

            x = (col == 0) ? left_margin_adj + current_measured_hole_width / 2 : last_x + (last_measured_hole_width / 2) + hole_spacing + (current_measured_hole_width / 2);
            y = row_center(row);

            generate_cutout(hole_type, x, y, current_hole_width, current_hole_height, plate_thickness);

            generate_holes_recursive(hole_num + 1, max_holes, x, y, current_hole_width, current_measured_hole_width, current_hole_height);
        }
    }
}

// Helper module to generate plate with cutouts
module generate_plate_with_cutouts() {
    difference() {
        linear_extrude(height = plate_thickness)
        polygon(points = plate_points());

        generate_holes_recursive(0, (number_of_rows * holes_per_row), left_margin_adj + hole_width(0) / 2, row_center(0), 0, 0);

        if (text_height < 0) {
            generate_row_text_recursive(0, number_of_rows);
            generate_col_text_recursive(0, holes_per_row);
        }
    }

    if (text_height > 0) {
        union() {
            generate_row_text_recursive(0, number_of_rows);
            generate_col_text_recursive(0, holes_per_row);
        }
    }
}

generate_plate_with_cutouts();
