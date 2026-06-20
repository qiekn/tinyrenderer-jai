#import "Basic";
#import "Math";
#import "File";

//
// make_image :: (width: int, height: int) -> PPM_Image
// 
// make_color :: (color : Vector3) -> PPM_Color
// make_color :: (color : Vector4) -> PPM_Color
// make_color :: (r: float, g: float, b: float) -> PPM_Color
//
// set_pixel  :: (image: *PPM_Image, x: int, y: int, color: PPM_Color)
//
// write_p3   :: (filename: string, image: *PPM_Image)
// write_p6   :: (filename: string, image: *PPM_Image)
//

PPM_Color :: struct {
    r, g, b: u8;
}

PPM_Image :: struct {
    width:  int;
    height: int;
    pixels: [] PPM_Color;
}

make_image :: (width: int, height: int) -> PPM_Image {
    image: PPM_Image;
    image.width  = width;
    image.height = height;
    image.pixels = NewArray(width * height, PPM_Color);
    return image;
}

set_pixel:: (image: *PPM_Image, x: int, y: int, color: PPM_Color) {
    if x < 0 || x >= image.width  return;
    if y < 0 || y >= image.height return;

    image.pixels[y * image.width + x] = color;
}

make_color :: (color : Vector3) {
    make_color(color.x, color.y, color.z);
} 

make_color :: (color : Vector4) {
    make_color(color.xyz);
}

make_color :: (r: float, g: float, b: float) -> PPM_Color {
    return .{
        cast(u8)(255.999 * clamp_to_float_01(r)),
        cast(u8)(255.999 * clamp_to_float_01(g)),
        cast(u8)(255.999 * clamp_to_float_01(b)),
    };
}

write_p3 :: (filename: string, image: *PPM_Image) {
    builder: String_Builder;

    print_to_builder(*builder, "P3\n");
    print_to_builder(*builder, "% %\n", image.width, image.height);
    print_to_builder(*builder, "255\n");

    for y: 0..image.height - 1 {
        for x: 0..image.width - 1 {
            c := image.pixels[y * image.width + x];
            print_to_builder(*builder, "% % %\n", c.r, c.g, c.b);
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
            c := image.pixels[y * image.width + x];

            append(*builder, c.r);
            append(*builder, c.g);
            append(*builder, c.b);
        }
    }

    write_entire_file(filename, *builder);
}

#scope_file

clamp_to_float_01 :: (v: float) -> float {
    if v < 0 return 0;
    if v > 1 return 1;
    return v;
}
