#import "Basic";
#import "Math";
#import "Random";

using ppm :: #import "ppm";
#import,file "colors.jai";

// ----------------------------------------------------------------------------: globals

width, height := 256, 256;

// we can use magick.exe to scale and convert to png for beauty
// magick result.ppm -scale 400% result.png

// ----------------------------------------------------------------------------: entry

main :: () {
    image := make_image(width, height, BLACK);

    random_seed(69105);
    count := 1 << 24;

    t0 := current_time_monotonic(); // Apollo Time

    for i: 1..count {
        a := Vector2Int.{random_int(width), random_int(height)};
        b := Vector2Int.{random_int(width), random_int(height)};
        color := random_color();
        draw_line(*image, a, b, color);
    }

    t1 := current_time_monotonic();

    ppm.write_p3("test.ppm", *image);

    t2 := current_time_monotonic();

    draw_seconds, ok0 := to_float64_seconds(t1 - t0);
    write_seconds, ok1 := to_float64_seconds(t2 - t1);
    total_seconds, ok2 := to_float64_seconds(t2 - t0);

    if ok0 print("Draw time:  % seconds\n", draw_seconds);
    if ok1 print("Write time: % seconds\n", write_seconds);
    if ok2 print("Total time: % seconds\n", total_seconds);
}

draw_line :: (image: *PPM_Image, a: Vector2Int, b: Vector2Int, color: Vector4) {
    round_to_int :: (x : float) -> int { return cast(int)(x + 0.5); }

    // If the line is steep, we t ranspose the image
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

random_int :: (max : int) -> int {
    return cast(int)(random_get() % cast(u64) max);
}

random_color :: () -> Vector4 {
    return Vector4.{
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        255.0,
    };
}
