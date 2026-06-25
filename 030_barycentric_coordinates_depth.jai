#import "Basic";
#import "Math";
using ppm :: #import "ppm";
#import,file "colors.jai";

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Triangle :: struct {
    ax, ay, az : int;
    bx, by, bz : int;
    cx, cy, cz : int;
}

main :: () {
    width, height := 64, 64;
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    triangle := Triangle.{17, 4, 13, 55, 39, 128, 23, 59, 255};
    draw_triangle(*image, triangle, GREEN);

    ppm.write_p3("030_grey.ppm", *image);
}


draw_triangle :: (image: *ppm.PPM_Image, using triangle : Triangle, color: Vector4 = RED) {
    abc_area := signed_triangle_area(ax, ay, bx, by, cx, cy);
    if abc_area < 0 return;
    aabb := get_aabb(ax, ay, bx, by, cx, cy);
    for y: aabb.y_min .. aabb.y_max {
        for x: aabb.x_min .. aabb.x_max {
            
            pab_area := signed_triangle_area(x, y, ax, ay, bx, by);
            pbc_area := signed_triangle_area(x, y, bx, by, cx, cy);
            pca_area := signed_triangle_area(x, y, cx, cy, ax, ay);

            alpha := pbc_area / abc_area;
            beta  := pca_area / abc_area;
            gamma := pab_area / abc_area;

            if (alpha<0 || beta<0 || gamma<0) continue; // negative barycentric coordinate => the pixel is outside the triangle

            grey := (alpha * az + beta * bz + gamma * cz) / 255.0;
            set_pixel(image, x, y, make_vector4(grey));
        }
    }
}

#scope_file

get_aabb :: (ax: int, ay: int, bx: int, by: int, cx: int, cy: int) -> AABB {
    x_min := min(ax, bx, cx);
    x_max := max(ax, bx, cx);
    y_min := min(ay, by, cy);
    y_max := max(ay, by, cy);

    return .{x_min, x_max, y_min, y_max};
}

signed_triangle_area :: (ax, ay, bx, by, px, py) => 0.5 * ((ax-px) * (by-ay) - (ay-py) * (bx - ax));
