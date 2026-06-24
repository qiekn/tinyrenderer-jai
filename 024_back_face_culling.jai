#import "Basic";
#import "Math";
#import "Random";

using obj :: #import "obj";
using ppm :: #import "ppm";
#import,file "colors.jai";

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Triangle :: struct {
    ax, ay : int;
    bx, by : int;
    cx, cy : int;
}

main :: () {
    draw_model("./assets/diablo.obj", "024_diablo.ppm");
    draw_model("./assets/nzwl_ssld.obj", "024_ssld.ppm", 4096, 4096);
}

draw_model :: (mesh_filepath : string, save_filepath : string, width := 1024, height := 1024) {
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    vertices : [..] Vector3;
    indices : [..] Triangle_Indices;
    defer array_free(vertices);
    defer array_free(indices);

    load_obj(mesh_filepath, *vertices, *indices);

    for indices {
        triangle := make_triangle(vertices, it, width, height);
        draw_triangle(*image, triangle, random_color());
    }
    ppm.write_p3(save_filepath, *image);
}


draw_triangle :: (image: *ppm.PPM_Image, using triangle : Triangle, color: Vector4 = RED) {
    // Simple Back-face culling
    signed_area := vec2_cross_product_signed_area(ax, ay, bx, by, cx, cy);
    if signed_area <= 0 return;

    aabb := get_aabb(ax, ay, bx, by, cx, cy);
    for y: aabb.y_min .. aabb.y_max {
        for x: aabb.x_min .. aabb.x_max {
            if point_inside_triangle(x, y, triangle) {
                set_pixel(image, x, y, color);
            }
        }
    }
}

#scope_file

get_aabb :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> AABB {
    x_min := min(ax, bx, cx);
    x_max := max(ax, bx, cx);
    y_min := min(ay, by, cy);
    y_max := max(ay, by, cy);

    return .{x_min, x_max, y_min, y_max};
}

point_inside_triangle :: (x: int, y: int, using triangle: Triangle) -> bool {
    s0 := vec2_cross_product_signed_area(ax, ay, bx, by, x, y);
    s1 := vec2_cross_product_signed_area(bx, by, cx, cy, x, y);
    s2 := vec2_cross_product_signed_area(cx, cy, ax, ay, x, y);

    has_negative := s0 < 0 || s1 < 0 || s2 < 0;
    has_positive := s0 > 0 || s1 > 0 || s2 > 0;

    return !(has_negative && has_positive);
}

// In 2D, all points lie on the same plane (screen space).
// The cross product only has one Z direction (PA x AB):
vec2_cross_product_signed_area :: (ax: int, ay: int, bx: int, by: int, px: int, py: int) -> int {
    // | ax-px  bx-ax |
    // | ay-py  by-ay |
    return (ax-px) * (by-ay) - (ay-py) * (bx - ax);
}

// Vertices: an array of vertex positions loaded from an OBJ file.
// Indices:  a struct containing the three vertex indices of a triangle: a, b, c.
make_triangle :: (vertices : [..] Vector3, indices : Triangle_Indices, width := 1024, height := 1024) -> Triangle {

    // This opens the door to doing lots of functional-programming-ish things with greater ease.
    to_vec2i :: v => Vector2Int.{cast(int) v.x, cast(int) v.y};

    a := to_vec2i(ndc_to_screen_space(vertices[indices.a], width, height));
    b := to_vec2i(ndc_to_screen_space(vertices[indices.b], width, height));
    c := to_vec2i(ndc_to_screen_space(vertices[indices.c], width, height));

    return Triangle.{a.x, a.y, b.x, b.y, c.x, c.y};
}

ndc_to_screen_space :: (p : Vector3, width : int, height : int) -> Vector2 {
    x := (p.x * 0.5 + 0.5) * width;
    y := (p.y * 0.5 + 0.5) * height;
    return Vector2.{x, y};
}

random_color :: () -> Vector4 {
    return Vector4.{
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        255.0,
    };
}
