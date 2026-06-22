#import "Basic";
#import "Math";


using ppm :: #import "ppm";
#import,file "colors.jai";



// ----------------------------------------------------------------------------: globals

width, height := 64, 64;

// we can use magick.exe to scale and convert to png for beauty
// magick 010.ppm -scale 400% 010.png

// ----------------------------------------------------------------------------: entry

main :: () {
    image := make_image(width, height, BLACK);

    a := Vector2Int.{7, 3};
    b := Vector2Int.{12, 37};
    c := Vector2Int.{62, 53};

    draw_line(*image, a, b, BLUE);
    draw_line(*image, b, c, GREEN);
    draw_line(*image, c, a, YELLOW);

    // @Note that the following line AC has exactly the same endpoints with CA,
    // just passed parameters to the draw_line procedure in different order.
    draw_line(*image, a, c, RED);

    set_pixel(*image, a, WHITE);
    set_pixel(*image, b, WHITE);
    set_pixel(*image, c, WHITE);

    ppm.write_p3("010.ppm", *image);
    print("OK!\n");
}

draw_line :: (image: *PPM_Image, a: Vector2Int, b: Vector2Int, color: Vector4) {
    round_to_int :: (x : float) -> int { return cast(int)(x + 0.5); }

    // Make sure a-to-b is left-to-right
    if a.x > b.x then {
        Swap(*a.x, *b.x);
        Swap(*a.y, *b.y);
    }

    for x: a.x .. b.x {
        t := cast(float) (x - a.x) / (b.x - a.x);
        y := round_to_int(a.y + (b.y - a.y) * t);
        set_pixel(image, x, y, color);
    }
}
