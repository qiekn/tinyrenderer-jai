#import "Basic";
#import "Math";
using ppm :: #import "ppm";
#import,file "colors.jai";

main :: () {
    width, height := 256, 256;
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    draw_triangle(*image,  35,  99,  81, 190,  97, 124, RED);
    draw_triangle(*image, 221,  83, 172,  33,  97, 206, WHITE);
    draw_triangle(*image, 213, 162, 155, 173, 163, 223, GREEN);

    ppm.write_p3("test.ppm", *image);
}

draw_triangle :: (image: *ppm.PPM_Image, ax: int, ay: int, bx: int, by: int, cx: int, cy: int, color: Vector4 = RED) {
    a := Vector2Int.{ax, ay};
    b := Vector2Int.{bx, by};
    c := Vector2Int.{cx, cy};

    draw_line(image, a, b, color);
    draw_line(image, b, c, color);
    draw_line(image, c, a, color);
}

draw_line :: (image: *PPM_Image, a: Vector2Int, b: Vector2Int, color: Vector4) {
    steep : bool = abs(a.x - b.x) < abs(a.y - b.y);
    if steep {
        Swap(*a.x, *a.y);
        Swap(*b.x, *b.y);
    }

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
