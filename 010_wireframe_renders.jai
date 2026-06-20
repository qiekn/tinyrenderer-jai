#import "Basic";

using ppm :: #import "ppm";
#import,file "colors.jai";


// ----------------------------------------------------------------------------: globals

width, height := 64, 64;

// ----------------------------------------------------------------------------: entry

main :: () {
    image := make_image(width, height, BLACK);

    ax, ay := 7, 3;
    bx, by := 12, 37;
    cx, cy := 62, 53;

    set_pixel(*image, ax, ay, WHITE);
    set_pixel(*image, bx, by, WHITE);
    set_pixel(*image, cx, cy, WHITE);

    ppm.write_p3("010.ppm", *image);
    print("OK!\n");
}
