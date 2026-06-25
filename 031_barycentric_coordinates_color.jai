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

Position :: struct {
    x, y : int;
}

Vertex :: struct {
    using pos: Position;
    color : Vector4;
}

Triangle :: struct {
    a, b, c : Vertex;
}

main :: () {
    width, height := 64, 64;
    image := make_image(width, height, BLACK);
    defer free_image(*image);

    a := Vertex.{.{17, 4},  RED};
    b := Vertex.{.{55, 39}, GREEN};
    c := Vertex.{.{23, 59}, BLUE};

    draw_triangle(*image, a, b, c);

    ppm.write_p3("023_color.ppm", *image);
}

draw_triangle :: (image: *ppm.PPM_Image, a: Vertex, b: Vertex, c: Vertex) {
    aabb := get_aabb(a.pos, b.pos, c.pos);

    abc_area := signed_area(a, b, c);
    if abc_area == 0 return;

    for y: aabb.y_min .. aabb.y_max {
        for x: aabb.x_min .. aabb.x_max {
            pab_area := signed_area(p, a.pos, b.pos);
            pbc_area := signed_area(p, b.pos, c.pos);
            pca_area := signed_area(p, c.pos, a.pos);

            alpha := pbc_area / abc_area;
            beta  := pca_area / abc_area;
            gamma := pab_area / abc_area;

            // negative barycentric coordinate => the pixel is outside the triangle
            if alpha < 0 || beta < 0 || gamma < 0 {
                continue;
            }

            color := alpha * a.color + beta * b.color + gamma * c.color;

            set_pixel(image, x, y, color);
        }
    }
}

draw_triangle :: (image: *ppm.PPM_Image, using triangle: Triangle) {
    draw_triangle(image, a, b, c);
}

#scope_file

get_aabb :: (a: Position, b: Position, c: Position) -> AABB {
    x_min := min(a.x, b.x, c.x);
    x_max := max(a.x, b.x, c.x);
    y_min := min(a.y, b.y, c.y);
    y_max := max(a.y, b.y, c.y);

    return .{x_min, x_max, y_min, y_max};
}

// AB x BC
signed_area :: (a: Position, b: Position, c: Position) -> float {
    ab_x := b.x - a.x;
    ab_y := b.y - a.y;

    bc_x := c.x - b.x;
    bc_y := c.y - b.y;

    return 0.5 * ab_x * bc_y - ab_y * bc_x;
}
