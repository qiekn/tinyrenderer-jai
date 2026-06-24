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

    ppm.write_p3("021.ppm", *image);
}

draw_triangle :: (image: *ppm.PPM_Image, ax: int, ay: int, bx: int, by: int, cx: int, cy: int, color: Vector4 = RED) {
    // Bubble sort: make sure a.y <= b.y <= c.y
    if ay > by { Swap(*ax, *bx); Swap(*ay, *by); }
    if ay > cy { Swap(*ax, *cx); Swap(*ay, *cy); }
    if by > cy { Swap(*bx, *cx); Swap(*by, *cy); }

    // Just a horizontal line
    if ay == cy {
        x1 := min(ax, bx, cx);
        x2 := max(ax, bx, cx);
        draw_horizontal_line(image, x1, x2, ay, color);
        return;
    }

    // Bottom half
    if ay < by {
        for y: ay .. by {
            t1 := cast(float)(y - ay) / (cy - ay);
            t2 := cast(float)(y - ay) / (by - ay);

            x1 := ax + cast(int)((cx - ax) * t1);
            x2 := ax + cast(int)((bx - ax) * t2);

            draw_horizontal_line(image, x1, x2, y, color);
        }
    }

    // Upper half
    if by < cy {
        for y: by .. cy {
            t1 := cast(float)(y - ay) / (cy - ay);
            t2 := cast(float)(y - by) / (cy - by);

            x1 := ax + cast(int)((cx - ax) * t1);
            x2 := bx + cast(int)((cx - bx) * t2);

            draw_horizontal_line(image, x1, x2, y, color);
        }
    }
}


// Actually, we don't need this complex version draw_line, we just need a draw_horizontal_line
draw_horizontal_line :: (image: *PPM_Image, x1: int, x2: int, y: int, color: Vector4) {
    if x1 > x2 then Swap(*x1, *x2);

    for x: x1 .. x2 {
        set_pixel(image, x, y, color);
    }
}


/*
draw_line :: (image: *PPM_Image, ax: int, ay: int, bx: int, by: int, color: Vector4) {
    steep : bool = abs(ax - bx) < abs(ay - by);
    if steep {
        Swap(*ax, *ay);
        Swap(*bx, *by);
    }

    if ax > bx {
        Swap(*ax, *bx);
        Swap(*ay, *by);
    }

    y := ay;
    ierror := 0;
    for x: ax .. bx {
        if steep then set_pixel(image, y, x, color);
        else set_pixel(image, x, y, color);
        ierror += 2 * abs(by - ay);
        if ierror > bx - ax {
            y += ifx by > ay then 1 else -1;
            ierror -= 2 * (bx - ax);
        }
    }
}
*/
