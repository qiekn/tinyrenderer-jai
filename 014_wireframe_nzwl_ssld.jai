#import "Basic";
#import "Math";
#import "Random";

using obj :: #import "obj";
using ppm :: #import "ppm";
#import,file "colors.jai";

// ----------------------------------------------------------------------------: globals

width, height := 4096, 4096;
vertices : [..] Vector3;
indices : [..] Triangle_Indices;

// ----------------------------------------------------------------------------: entry

main :: () {
    image := make_image(width, height, BLACK);
    load_obj("./assets/nzwl_ssld.obj", *vertices, *indices);
    for indices draw_triangle(*image, it, GREEN);
    ppm.write_p3("test.ppm", *image);
}

draw_triangle :: (image: *PPM_Image, triangle: Triangle_Indices, color: Vector4 = RED) {
    a := project(vertices[triangle.a]);
    b := project(vertices[triangle.b]);
    c := project(vertices[triangle.c]);

    draw_line(image, a, b, color);
    draw_line(image, b, c, color);
    draw_line(image, c, a, color);
}

draw_line :: (image: *PPM_Image, a: Vector2Int, b: Vector2Int, color: Vector4) {
    steep : bool = abs(a.x - b.x) < abs(a.y - b.y);
    if steep { Swap(*a.x, *a.y); Swap(*b.x, *b.y); }
    if a.x > b.x then Swap(*a, *b);

    y:= a.y;
    ierror := 0;
    for x: a.x .. b.x {
        if steep then set_pixel(image, y, x, color);
        else set_pixel(image, x, y, color);
        ierror = ierror + 2 * abs(b.y - a.y);
        if ierror > b.x - a.x {
            y += ifx b.y > a.y then 1 else -1;
            ierror = ierror - 2 * (b.x - a.x);
        }
    }
}

project :: (original_point : Vector3) -> Vector2Int {
    x := cast(int) ((original_point.x * 0.5 + 0.5) * width);
    y := cast(int) ((original_point.y * 0.5 + 0.5) * height);
    return Vector2Int.{x, y};
}
