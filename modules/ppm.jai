//
// make_image :: (width: int, height: int) -> PPM_Image
// make_image :: (width: int, height: int, background_color: Vector4) -> PPM_Image
//
// clear      :: (image: *PPM_Image, color: Vector4)
//
// set_pixel  :: (image: *PPM_Image, x: int, y: int, color: Vector4)
//
// write_p3   :: (filename: string, image: *PPM_Image)
// write_p6   :: (filename: string, image: *PPM_Image)
//

PPM_Image :: struct {
    width:  int;
    height: int;
    pixels: [] Vector4;
}

make_image :: (width: int, height: int) -> PPM_Image {
    image: PPM_Image;
    image.width  = width;
    image.height = height;
    image.pixels = NewArray(width * height, Vector4);
    return image;
}

make_image :: (width: int, height: int, background_color: Vector4) -> PPM_Image {
    image := make_image(width, height);
    clear(*image, background_color);
    return image;
}

set_pixel :: (image: *PPM_Image, x: int, y: int, color: Vector4) {
    if x < 0 || x >= image.width  return;
    if y < 0 || y >= image.height return;

    image.pixels[y * image.width + x] = color;
}

clear :: (image: *PPM_Image, color: Vector4) {
    for * image.pixels {
        it.* = color;
    }
}

write_p3 :: (filename: string, image: *PPM_Image) {
    builder: String_Builder;

    print_to_builder(*builder, "P3\n");
    print_to_builder(*builder, "% %\n", image.width, image.height);
    print_to_builder(*builder, "255\n");

    for y: 0..image.height - 1 {
        for x: 0..image.width - 1 {
            r, g, b := to_rgb8(image.pixels[y * image.width + x]);
            print_to_builder(*builder, "% % %\n", r, g, b);
        }
    }

    write_entire_file(filename, *builder);
}

write_p6 :: (filename: string, image: *PPM_Image) {
    builder: String_Builder;

    print_to_builder(*builder, "P6\n");
    print_to_builder(*builder, "% %\n", image.width, image.height);
    print_to_builder(*builder, "255\n");

    for y: 0..image.height - 1 {
        for x: 0..image.width - 1 {
            r, g, b := to_rgb8(image.pixels[y * image.width + x]);
            append(*builder, r);
            append(*builder, g);
            append(*builder, b);
        }
    }

    write_entire_file(filename, *builder);
}

#scope_file

// Convert a floating-point color (components in 0..1) to 8-bit RGB; alpha is not written to PPM.
to_rgb8 :: (c: Vector4) -> (r: u8, g: u8, b: u8) {
    return cast(u8)(255.999 * clamp_to_float_01(c.x)),
           cast(u8)(255.999 * clamp_to_float_01(c.y)),
           cast(u8)(255.999 * clamp_to_float_01(c.z));
}

clamp_to_float_01 :: (v: float) -> float {
    if v < 0 return 0;
    if v > 1 return 1;
    return v;
}

#import "Basic";
#import "Math";
#import "File";
