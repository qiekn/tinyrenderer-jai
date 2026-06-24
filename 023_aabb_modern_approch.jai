#import "Basic";
#import "Math";
using ppm :: #import "ppm";
#import,file "colors.jai";

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Triagnle :: struct {
    ax, ay : int;
    bx, by : int;
    cx, cy : int;
}

main :: () {
    width, height := 256, 256;
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    draw_triangle(*image,  35,  99,  81, 190,  97, 124, RED);
    draw_triangle(*image, 221,  83, 172,  33,  97, 206, WHITE);
    draw_triangle(*image, 213, 162, 155, 173, 163, 223, GREEN);

    ppm.write_p3("023.ppm", *image);
}


draw_triangle :: (image: *ppm.PPM_Image, using triangle : Triagnle, color: Vector4 = RED) {
    aabb := get_aabb(ax, ay, bx, by, cx, cy);
    for y: aabb.y_min .. aabb.y_max {
        for x: aabb.x_min .. aabb.x_max {
            if point_inside_triangle(x, y, triangle) {
                set_pixel(image, x, y, color);
            }
        }
    }
}

draw_triangle :: (image: *ppm.PPM_Image, ax: int, ay: int, bx: int, by: int, cx: int, cy: int, color: Vector4 = RED) {
    draw_triangle(image, .{ax, ay, bx, by, cx, cy}, color);
}

#scope_file

get_aabb :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> AABB {
    x_min := min(ax, bx, cx);
    x_max := max(ax, bx, cx);
    y_min := min(ay, by, cy);
    y_max := max(ay, by, cy);

    return .{x_min, x_max, y_min, y_max};
}

point_inside_triangle :: (x: int, y: int, using triangle: Triagnle) -> bool {
    s0 := vec2_cross_sign(ax, ay, bx, by, x, y);
    s1 := vec2_cross_sign(bx, by, cx, cy, x, y);
    s2 := vec2_cross_sign(cx, cy, ax, ay, x, y);

    has_negative := s0 < 0 || s1 < 0 || s2 < 0;
    has_positive := s0 > 0 || s1 > 0 || s2 > 0;

    return !(has_negative && has_positive);
}

// In 2D, all points lie on the same plane (screen space).
// The cross product only has one Z direction (PA x AB):
vec2_cross_sign :: (ax: int, ay: int, bx: int, by: int, px: int, py: int) -> int {
    // | ax-px  bx-ax |
    // | ay-py  by-ay |
    cross := (ax-px) * (by-ay) - (ay-py) * (bx - ax);

    // if cross > 0 return 1;
    // if cross < 0 return -1;
    // return 0;

    // We just use the sign, so just return
    return cross;
}
