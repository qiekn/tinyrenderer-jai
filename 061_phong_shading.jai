#import "Basic";
#import "Math";
#import "Random";
#import "Print_Vars";

using ppm :: #import "ppm";
using obj :: #import "obj";
using gl  :: #import "gl";
#import,file "colors.jai";

// ----------------------------------------------------------------------------: globals

width, height :: 1024, 1024;
light :: Vector3.{1, 1, 1};

// Camera
eye           :: Vector3.{0, 0, 3};
center        :: Vector3.{0, 0, 0};
up            :: Vector3.{0, 1, 0};

// MVP matrices
model : Matrix4;
view, projection, viewport : Matrix4;

vertices : [..] Vector3;
indices : [..] Triangle_Indices;
zbuffer : Z_Buffer;

l_dir : Vector3;
triangle_world : Triangle;

// ----------------------------------------------------------------------------: entry

main :: () {
    model = rotate_y(30.0);
    view = lookat(eye, center, up);
    projection = make_perspective(radian_to_angle(45), 1.0, 0.1, 100.0);
    viewport   = make_viewport(0, 0, width, height);
    zbuffer    = make_zbuffer(width, height);

    load_obj("./assets/african_head.obj", *vertices, *indices);
    defer array_free(vertices);
    defer array_free(indices);

    framebuffer := make_image(width, height, BLACK);
    defer free_image(*framebuffer);

    l_dir = normalize(view * model * Vector4.{light.x, light.y, light.z, 0.0}).xyz;

    shader := Shader.{vertex_pass, fragment_pass};

    for indices {
        {
            using it;
            triangle_world = Triangle.{vertices[a], vertices[b], vertices[c]};
        }
        triangle := make_triangle(vertices, it, shader);
        draw_triangle(*framebuffer, *zbuffer, triangle, shader);
    }

    ppm.write_p3("061.ppm", *framebuffer);
}

// ----------------------------------------------------------------------------: shaders

// Every vertex will be processed by this procedure
// From vertex position load from obj file (e.g. v 0.120409 0.670105 0.118388)
// To screen space position
//
// @TODO
//
// VS_Input :: struct {
//     position : Vector3;
//     normal   : Vector3;
//     uv       : Vector2;
// }
// 
// VS_Output :: struct {
//     clip_position : Vector4;
//     world_pos     : Vector3;
//     normal        : Vector3;
//     uv            : Vector2;
// }
// 
// Currently only process screen space position.
vertex_pass :: (using v : Vector3) -> Vector3 {
    world := model * Vector4.{x, y, z, 1.0};
    clip := projection * view * world;
    return clip_to_screen(clip);
}

//
// @TODO FS_Input & FS_Output struct
//
fragment_pass :: () -> Vector4 {
    l := l_dir; using triangle_world;
    ambient := 0.3;
    n := normalize(cross(b - a, c - a));   // triangle normal
    r := normalize(n * dot(n, l) * 2.0 - l); // reflected light direction
    diffuse := max(0.0, dot(n, l));
    specular := pow(max(r.z, 0.0), 35);

    color := make_vector4(min(1.0, ambient + 0.4 * diffuse + 0.9 * specular));
    color.w = 1.0;
    return color;
}

// ----------------------------------------------------------------------------: helpers

random_color :: () -> Vector4 {
    return Vector4.{
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        random_get_zero_to_one_open(),
        1.0,
    };
}

clip_to_screen :: (clip : Vector4) -> Vector3 {
    if clip.w == 0.0 return .{-999, -999, -999};

    ndc := Vector4.{
        clip.x / clip.w,
        clip.y / clip.w,
        clip.z / clip.w,
        1.0,
    };

    screen := viewport * ndc;
    return screen.xyz;
}

radian_to_angle :: (x : float) -> float {
    return x * PI / 180.0;
}
