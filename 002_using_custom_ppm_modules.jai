#import "Basic";

ppm :: #import "ppm";

main :: () {
    width, height := 256, 256;
    image := ppm.make_image(width, height);

    for y: 0..height-1 {
        for x: 0..width-1 {
            r := cast(float) x/width;
            g := cast(float) y/height;
            b := 0.0;
            ppm_color := ppm.make_color(r,g,b);
            ppm.set_pixel(*image, x, y, ppm_color);
        }
    }

    ppm.write_p3("03.ppm", *image);
    print("OK!\n");
}
