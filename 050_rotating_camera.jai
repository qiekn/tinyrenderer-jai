#import "Basic";
#import "Math";
#import "Random";

using ppm :: #import "ppm";
using obj :: #import "obj";
#import,file "colors.jai";

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Position :: struct {
    x, y, z : int;
}

Vertex :: struct {
    using position : Position;
}

Triangle :: struct {
    a, b, c : Vertex;
}

// ----------------------------------------------------------------------------: entry

main :: () {
    draw_model("./assets/african_head.obj", "050");
}

draw_model :: (mesh_filepath : string, save_filepath : string, width := 1024, height := 1024) {
    framebuffer := make_image(width, height, BLACK);
    zbuffer := make_image(width, height, BLACK);
    defer free_image(*framebuffer);
    defer free_image(*zbuffer);

    vertices : [..] Vector3;
    indices : [..] Triangle_Indices;
    defer array_free(vertices);
    defer array_free(indices);

    load_obj(mesh_filepath, *vertices, *indices);

    for indices {
        triangle := make_triangle(vertices, it, width, height);
        draw_triangle(*framebuffer, *zbuffer, triangle, random_color()); // Random color for each triangle
    }

    ppm.write_p3(tprint("%_color.ppm", save_filepath), *framebuffer);
    ppm.write_p3(tprint("%_depth.ppm", save_filepath), *zbuffer);
}

// Draw one extra image: zbuffer
draw_triangle :: (framebuffer: *PPM_Image, zbuffer: *PPM_Image, a: Position, b: Position, c: Position, color : Vector4) {
    aabb := get_aabb(a, b, c);

    abc_area := signed_triangle_area(a, b, c);
    if abc_area == 0 return;

    for y: aabb.y_min .. aabb.y_max-1{
        for x: aabb.x_min .. aabb.x_max-1 {
            p := Position.{x, y, 0};
            alpha := signed_triangle_area(p, a, b) / abc_area;
            beta  := signed_triangle_area(p, b, c) / abc_area;
            gamma := signed_triangle_area(p, c, a) / abc_area;

            // negative barycentric coordinate => the pixel is outside the triangle
            if alpha < 0 || beta < 0 || gamma < 0 {
                continue;
            }

            z := (alpha * a.z + beta * b.z + gamma * c.z) / 255.0; // Depth interplotion
            if z <= get_pixel(zbuffer, x, y).z continue;
            set_pixel(zbuffer, x, y, Vector4.{z, z, z, 1});
            set_pixel(framebuffer, x, y, color);
        }
    }
}

draw_triangle :: (framebuffer: *PPM_Image, zbuffer: *PPM_Image, using triangle: Triangle, color : Vector4) {
    draw_triangle(framebuffer, zbuffer, a.position, b.position, c.position, color);
}

#scope_file

// ----------------------------------------------------------------------------: helpers

get_aabb :: (a: Position, b: Position, c: Position) -> AABB {
    x_min := min(a.x, b.x, c.x);
    x_max := max(a.x, b.x, c.x);
    y_min := min(a.y, b.y, c.y);
    y_max := max(a.y, b.y, c.y);

    return .{x_min, x_max, y_min, y_max};
}

// AB x BC
signed_triangle_area :: (a: Position, b: Position, c: Position) -> float {
    ab_x := b.x - a.x;
    ab_y := b.y - a.y;

    bc_x := c.x - b.x;
    bc_y := c.y - b.y;

    return 0.5 * (ab_x * bc_y - ab_y * bc_x);
}

// Vertices: an array of vertex positions loaded from an OBJ file.
// Indices:  a struct containing the three vertex indices of a triangle: a, b, c.
make_triangle :: (vertices : [..] Vector3, indices : Triangle_Indices, width := 1024, height := 1024) -> Triangle {
    // This opens the door to doing lots of functional-programming-ish things with greater ease.
    to_position :: v => Position.{cast(int) v.x, cast(int) v.y, cast(int) v.z};

    angle := PI / 6.0; // 30 degrees

    pa := project(rotate_y(vertices[indices.a], angle), width, height);
    pb := project(rotate_y(vertices[indices.b], angle), width, height);
    pc := project(rotate_y(vertices[indices.c], angle), width, height);

    a := Vertex.{to_position(pa)};
    b := Vertex.{to_position(pb)};
    c := Vertex.{to_position(pc)};

    return Triangle.{a, b, c};
}

// [  cos(a)   0   sin(a) ]    [ x ]
// [    0      1     0    ] x  [ y ]
// [ -sin(a)   0   cos(a) ]    [ z ]
rotate_y :: (using v: Vector3, angle: float) -> Vector3 {
    c := cos(angle);
    s := sin(angle);
    return Vector3.{
        c * x + s * z,
        y,
        -s * x + c * z,
    };
}

// Currently orthographic projection
project :: (p : Vector3, width : int, height : int) -> Vector3 {
    x := (p.x * 0.5 + 0.5) * width;
    y := (p.y * 0.5 + 0.5) * height;
    z := (p.z * 0.5 + 0.5) * 255;
    return Vector3.{x, y, z};
}


random_color :: () -> Vector4 {
    return Vector4.{
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        1.0,
    };
}
