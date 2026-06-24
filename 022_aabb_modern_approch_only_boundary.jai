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

    ppm.write_p3("022.ppm", *image);
}


draw_triangle :: (image: *ppm.PPM_Image, using triangle : Triagnle, color: Vector4 = RED) {
    using aabb := get_aabb(ax, ay, bx, by, cx, cy);
    for y: y_min..y_max {
        for x: x_min..x_max {
            // Let's draw the AABB only
            set_pixel(image, x, y, color);
        }
    }
}

draw_triangle :: (image: *ppm.PPM_Image, ax: int, ay: int, bx: int, by: int, cx: int, cy: int, color: Vector4 = RED) {
    draw_triangle(image, .{ax, ay, bx, by, cx, cy}, color);
}

get_aabb :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> AABB {
    x_min := min(ax, bx, cx);
    x_max := max(ax, bx, cx);
    y_min := min(ay, by, cy);
    y_max := max(ay, by, cy);

    return .{x_min, x_max, y_min, y_max};
}
