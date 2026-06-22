#import "Basic";
#import "Math";
#import "Random";
#import "obj";

using ppm :: #import "ppm";
#import,file "colors.jai";

// ----------------------------------------------------------------------------: globals

width, height := 1024, 1024;
vertices : [..] Vector3;
triangles : [..] Triangle;

// ----------------------------------------------------------------------------: entry

main :: () {
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    load_obj("./assets/diablo.obj", *vertices, *triangles);

    t0 := current_time_monotonic(); // Drawing

    for triangles {
        draw_triangle(*image, it, RED);
    }

    t1 := current_time_monotonic(); // Write to file

    ppm.write_p3("test.ppm", *image);

    t2 := current_time_monotonic(); // Print benchmark result

    draw_seconds, ok0 := to_float64_seconds(t1 - t0);
    write_seconds, ok1 := to_float64_seconds(t2 - t1);
    total_seconds, ok2 := to_float64_seconds(t2 - t0);

    if ok0 print("Draw time:  % seconds\n", draw_seconds);
    if ok1 print("Write time: % seconds\n", write_seconds);
    if ok2 print("Total time: % seconds\n", total_seconds);

    array_free(vertices);
    array_free(triangles);
}

draw_triangle :: (image: *PPM_Image, triangle: Triangle, color: Vector4 = RED) {
    a := project(vertices[triangle.a]);
    b := project(vertices[triangle.b]);
    c := project(vertices[triangle.c]);

    draw_line(image, a, b, color);
    draw_line(image, b, c, color);
    draw_line(image, c, a, color);
}

draw_line :: (image: *PPM_Image, a: Vector2Int, b: Vector2Int, color: Vector4) {
    // If the line is steep, we transpose the image
    steep : bool = abs(a.x - b.x) < abs(a.y - b.y);
    if steep {
        Swap(*a.x, *a.y);
        Swap(*b.x, *b.y);
    }

    // Make sure a-to-b is left-to-right
    if a.x > b.x then Swap(*a, *b);

    y:= a.y;
    ierror := 0;
    for x: a.x .. b.x {
        if steep
            set_pixel(image, y, x, color);
        else
            set_pixel(image, x, y, color);
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
