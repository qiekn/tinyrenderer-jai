#import "Basic";
#import "Math";

#scope_file

using ppm :: #import "ppm";
using obj :: #import "obj";

#scope_export

Shader :: struct {
    vertex   : (Vector3) -> Vector3;
    fragment : () -> Vector4;
}

AABB :: struct {
    x_min: int;
    x_max: int;
    y_min: int;
    y_max: int;
}

Triangle :: struct {
    a, b, c : Vector3;
}

Z_Buffer :: struct {
    zbuffer : PPM_Image;
    min_depth := 10.0;
    max_depth := -10.0;
}

// Vertices: an array of vertex positions loaded from an OBJ file.
// Indices:  a struct containing the three vertex indices of a triangle: a, b, c.
make_triangle :: (vertices : [..] Vector3, indices : Triangle_Indices, shader : Shader) -> Triangle {
    a := shader.vertex(vertices[indices.a]);
    b := shader.vertex(vertices[indices.b]);
    c := shader.vertex(vertices[indices.c]);
    return Triangle.{a, b, c};
}

draw_triangle :: (framebuffer: *PPM_Image, using _zbuffer: *Z_Buffer, using triangle : Triangle, shader : Shader) {
    aabb := get_aabb(a, b, c, framebuffer.width, framebuffer.height);

    totoal_area := signed_triangle_area(a, b, c);
    if totoal_area == 0 return;

    color := shader.fragment();

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
            if z >= get_pixel(*zbuffer, x, y).z continue;
            set_pixel(*zbuffer, x, y, make_vector4(z));
            set_pixel(framebuffer, x, y, color);
        }
    }
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

// Init View Matrix
// eye: camera position
// center: where camera looks at
// up: without it, camera can roll any angle, but now the camera's up is 'up'
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

// Note: fov is y radians
make_perspective :: (fov: float, aspect: float, z_near: float, z_far: float) -> Matrix4 {
    f := 1.0 / tan(fov * 0.5);
    return Matrix4.{
        _11 = f / aspect,
        _22 = f,
        _33 = -(z_far + z_near) / (z_far - z_near),
        _34 = -(2.0 * z_far * z_near) / (z_far - z_near),
        _43 = -1,
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

make_zbuffer :: (w: int, h: int) -> Z_Buffer {
    image := make_image(w, h, make_vector4(FLOAT16_MAX));
    return .{zbuffer = image};
}

#scope_file

// ----------------------------------------------------------------------------: helpers

// @NOTE now we use thoes global variables: mvp, viewport
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

get_aabb :: (a: Vector3, b: Vector3, c: Vector3, width: int, height: int) -> AABB {
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
