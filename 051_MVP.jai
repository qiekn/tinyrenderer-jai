#import "Basic";
#import "Math";
#import "Random";
#import "Print_Vars";


using ppm :: #import "ppm";
using obj :: #import "obj";
#import,file "colors.jai";

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Triangle :: struct {
    a, b, c : Vector3;
}

// ----------------------------------------------------------------------------: globals

width, height :: 1024, 1024;
eye           :: Vector3.{0, 0, 3};
center        :: Vector3.{0,  0, 0};
up            :: Vector3.{0,  1, 0};

model, view, projection, viewport, mvp : Matrix4;

min_depth := 10.0;
max_depth := -10.0;

// ----------------------------------------------------------------------------: entry

main :: () {
    model      = rotate_y(10);
    view       = lookat(eye, center, up);
    projection = perspective(45.0 * PI / 180.0, 1.0, 0.1, 100.0);
    viewport   = make_viewport(0, 0, width, height);

    mvp = projection * view * model;

    draw_model("./assets/african_head.obj", "051_face");
    draw_model("./assets/diablo.obj", "051_diablo");
}

transform_vertex :: (using v: Vector3) -> Vector3 {
    clip := mvp * Vector4.{x, y, z, 1.0};

    // @HACK Avoid division by zero during the perspective divide.
    // @TODO near-plane clipping
    if clip.w == 0.0 return Vector3.{-999, -999, -999};

    // clip space -> NDC
    ndc := Vector4.{
        clip.x / clip.w,
        clip.y / clip.w,
        clip.z / clip.w,
        1.0,
    };

    // NDC -> screen
    screen := viewport * ndc;

    return screen.xyz;
}

draw_model :: (mesh_filepath : string, save_filepath : string, width := 1024, height := 1024) {
    framebuffer := make_image(width, height, BLACK);
    zbuffer := make_image(width, height, make_vector4(FLOAT16_MAX));
    defer free_image(*framebuffer);
    defer free_image(*zbuffer);

    vertices : [..] Vector3;
    indices : [..] Triangle_Indices;
    defer array_free(vertices);
    defer array_free(indices);

    load_obj(mesh_filepath, *vertices, *indices);

    // Enable z-test and rasterize triangles
    for indices {
        triangle := make_triangle(vertices, it);
        draw_triangle(*framebuffer, *zbuffer, triangle, random_color()); // Random color for each triangle
    }

    // Make our depth image looks nice
    for y: 0..width-1 {
        for x: 0..height-1 {
            z := get_pixel(*zbuffer, x, y).z;
            z = (z - min_depth) / (max_depth - min_depth);
            set_pixel(*zbuffer, x, y, Vector4.{z, z, z, 1.0});
        }
    }

    ppm.write_p3(tprint("%_color.ppm", save_filepath), *framebuffer);
    ppm.write_p3(tprint("%_depth.ppm", save_filepath), *zbuffer);
}

draw_triangle :: (framebuffer: *PPM_Image, zbuffer: *PPM_Image, a: Vector3, b: Vector3, c: Vector3, color : Vector4) {
    aabb := get_aabb(a, b, c);

    totoal_area := signed_triangle_area(a, b, c);
    if totoal_area == 0 return;

    for y: aabb.y_min .. aabb.y_max{
        for x: aabb.x_min .. aabb.x_max {
            p := Vector3.{cast(float) x + 0.5, cast(float) y + 0.5, 0.0};
            alpha := signed_triangle_area(p, b, c) / totoal_area;
            beta  := signed_triangle_area(p, c, a) / totoal_area;
            gamma := signed_triangle_area(p, a, b) / totoal_area;

            // This is not necessasry.
            // negative barycentric coordinate => the pixel is outside the triangle
            if alpha < 0 || beta < 0 || gamma < 0 {
                continue;
            }

            // Depth interplotion
            z := (alpha * a.z + beta * b.z + gamma * c.z);
            min_depth = min(min_depth, z);
            max_depth = max(max_depth, z);
            // NDC z is in [-1, 1].
            // -1 is the near plane, 1 is the far plane.
            // So smaller z means closer to the camera.
            if z >= get_pixel(zbuffer, x, y).z continue;
            set_pixel(zbuffer, x, y, make_vector4(z));
            set_pixel(framebuffer, x, y, color);
        }
    }
}

draw_triangle :: (framebuffer: *PPM_Image, zbuffer: *PPM_Image, using triangle: Triangle, color : Vector4) {
    draw_triangle(framebuffer, zbuffer, a, b, c, color);
}

#scope_file

// ----------------------------------------------------------------------------: helpers

get_aabb :: (a: Vector3, b: Vector3, c: Vector3) -> AABB {
    x_min := cast(int) floor(min(a.x, b.x, c.x));
    y_min := cast(int) floor(min(a.y, b.y, c.y));

    x_max := cast(int) ceil(max(a.x, b.x, c.x));
    y_max := cast(int) ceil(max(a.y, b.y, c.y));

    x_min = max(0, x_min);
    y_min = max(0, y_min);

    x_max = min(width  - 1, x_max);
    y_max = min(height - 1, y_max);

    return .{x_min, x_max, y_min, y_max};
}

// AB x AC
signed_triangle_area :: (a: Vector3, b: Vector3, c: Vector3) -> float {
    ab_x := b.x - a.x;
    ab_y := b.y - a.y;

    ac_x := c.x - a.x;
    ac_y := c.y - a.y;

    return 0.5 * (ab_x * ac_y - ab_y * ac_x);
}

// Vertices: an array of vertex positions loaded from an OBJ file.
// Indices:  a struct containing the three vertex indices of a triangle: a, b, c.
make_triangle :: (vertices : [..] Vector3, indices : Triangle_Indices) -> Triangle {
    a := transform_vertex(vertices[indices.a]);
    b := transform_vertex(vertices[indices.b]);
    c := transform_vertex(vertices[indices.c]);

    return Triangle.{a, b, c};
}


lookat :: (eye : Vector3, center: Vector3, up: Vector3) -> Matrix4 {
    z := normalize(eye - center); // camera backward
    x := normalize(cross(up, z)); // camera right
    y := cross(z, x);             // camera up

    // View Matrix
    return Matrix4.{
        x.x, x.y, x.z, -dot(x, eye),
        y.x, y.y, y.z, -dot(y, eye),
        z.x, z.y, z.z, -dot(z, eye),
        0,   0,   0,    1
    };
}

perspective :: (fov_y_radians: float, aspect: float, z_near: float, z_far: float) -> Matrix4 {
    f := 1.0 / tan(fov_y_radians * 0.5);
    return Matrix4.{
        f / aspect, 0,0,0,
        0, f, 0, 0,
        0, 0, -(z_far + z_near) / (z_far - z_near),-(2.0 * z_far * z_near) / (z_far - z_near),
        0, 0,-1, 0,
    };
}

make_viewport :: (x: float = 0, y: float = 0, w: int, h: int) -> Matrix4 {
    return Matrix4.{
        w/2.0, 0,     0, x + w/2.0,
        0,     h/2.0, 0, y + h/2.0,
        0,     0,     1, 0        ,
        0,     0,     0, 1        ,
    };
}


random_color :: () -> Vector4 {
    return Vector4.{
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        1.0,
    };
}

rotate_y :: (angle: float) -> Matrix4 {
    angle *= 1.0 / 180.0 * PI;
    c := cos(angle);
    s := sin(angle);

    return Matrix4.{
        c, 0, s, 0,
        0, 1, 0, 0,
       -s, 0, c, 0,
        0, 0, 0, 1,
    };
}
