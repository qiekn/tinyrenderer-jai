#import "Basic";
#import "Math"; // Vector4
#import "File"; // write_entire_file

width  :: 256;
height :: 256;

framebuffer: [width * height] Vector4;

main :: () {
    builder : String_Builder;
    print_to_builder(*builder, "P3\n% %\n255\n", width, height);

    {
        r, g, b: float = 0.02, 0.15, 0.15;
        for y: 0..height - 1 {
            for x : 0..width - 1 {
                ir := cast(int)(255.999 * r);
                ig := cast(int)(255.999 * g);
                ib := cast(int)(255.999 * b);
                print_to_builder(*builder, "% % %\n", ir, ig, ib);
            }
        }
    }

    write_entire_file("test.ppm", *builder);
    print("Done!\n");
}
