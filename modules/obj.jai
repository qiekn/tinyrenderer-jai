//
// Generate by GPT-5.5 Codex (2026-06-23 04:44)
// (We don't want to spend time parse waveform obj)
// (We just want to get vertices and triangles)
//

Triangle_Indices :: struct {
    a, b, c: int;
}

load_obj :: (filename: string, vertices: *[..]Vector3, triangles: *[..]Triangle_Indices) -> bool {
    data, ok := read_entire_file(filename);
    if !ok {
        print("Failed to read obj file: %\n", filename);
        return false;
    }
    defer free(data);

    cursor := 0;

    while cursor < data.count {
        line_start := cursor;

        while cursor < data.count && data[cursor] != #char "\n" {
            cursor += 1;
        }

        line := make_string_view(data, line_start, cursor);

        if cursor < data.count && data[cursor] == #char "\n" {
            cursor += 1;
        }

        parse_obj_line(line, vertices, triangles);
    }

    print("Loaded OBJ: % vertices, % triangles\n", vertices.count, triangles.count);
    return true;
}

#scope_file

Obj_Line_Parser :: struct {
    line: string;
    i: int;
}

parse_obj_line :: (line: string, vertices: *[..]Vector3, triangles: *[..]Triangle_Indices) {
    parser := Obj_Line_Parser.{line, 0};
    skip_spaces(*parser);

    if parser.i >= parser.line.count return;
    if parser.line[parser.i] == #char "#" return;

    // Vertex position: v x y z
    if consume_tag(*parser, #char "v") {
        x, ok_x := parse_float(*parser);
        y, ok_y := parse_float(*parser);
        z, ok_z := parse_float(*parser);

        if ok_x && ok_y && ok_z && only_spaces_remaining(*parser) {
            array_add(vertices, Vector3.{x, y, z});
        }

        return;
    }

    // Face: f vertex/uv/normal vertex/uv/normal vertex/uv/normal
    if consume_tag(*parser, #char "f") {
        a := parse_obj_face_vertex_index(*parser);
        b := parse_obj_face_vertex_index(*parser);
        c := parse_obj_face_vertex_index(*parser);

        if a >= 0 && b >= 0 && c >= 0 && only_spaces_remaining(*parser) {
            array_add(triangles, Triangle_Indices.{a, b, c});
        }

        return;
    }
}

make_string_view :: (s: string, start: int, end: int) -> string {
    result := s;
    result.data += start;
    result.count = end - start;
    return result;
}

consume_tag :: (parser: *Obj_Line_Parser, tag: u8) -> bool {
    if parser.i >= parser.line.count || parser.line[parser.i] != tag return false;
    if parser.i + 1 >= parser.line.count || !is_space(parser.line[parser.i + 1]) return false;

    parser.i += 1;
    return true;
}

parse_float :: (parser: *Obj_Line_Parser) -> float, bool {
    skip_spaces(parser);

    start := parser.i;
    skip_until_space(parser);

    token := make_string_view(parser.line, start, parser.i);
    value, success, remainder := string_to_float64(token);
    if !success || remainder.count != 0 return 0.0, false;

    return cast(float)value, true;
}

parse_obj_face_vertex_index :: (parser: *Obj_Line_Parser) -> int {
    skip_spaces(parser);

    index := parse_positive_int(parser);
    if index == 0 return -1;
    if !consume_char(parser, #char "/") return -1;
    if parse_positive_int(parser) == 0  return -1;
    if !consume_char(parser, #char "/") return -1;
    if parse_positive_int(parser) == 0  return -1;

    return index - 1;
}

parse_positive_int :: (parser: *Obj_Line_Parser) -> int {
    if parser.i >= parser.line.count || !is_digit(parser.line[parser.i]) return 0;

    result := 0;
    while parser.i < parser.line.count && is_digit(parser.line[parser.i]) {
        result = result * 10 + cast(int)(parser.line[parser.i] - #char "0");
        parser.i += 1;
    }

    return result;
}

consume_char :: (parser: *Obj_Line_Parser, c: u8) -> bool {
    if parser.i >= parser.line.count || parser.line[parser.i] != c return false;

    parser.i += 1;
    return true;
}

only_spaces_remaining :: (parser: *Obj_Line_Parser) -> bool {
    skip_spaces(parser);
    return parser.i >= parser.line.count;
}

is_space :: (c: u8) -> bool {
    return c == #char " " ||
           c == #char "\t" ||
           c == #char "\r" ||
           c == #char "\n";
}

skip_spaces :: (parser: *Obj_Line_Parser) {
    while parser.i < parser.line.count && is_space(parser.line[parser.i]) {
        parser.i += 1;
    }
}

skip_until_space :: (parser: *Obj_Line_Parser) {
    while parser.i < parser.line.count && !is_space(parser.line[parser.i]) {
        parser.i += 1;
    }
}

is_digit :: (c: u8) -> bool {
    return c >= #char "0" && c <= #char "9";
}

#import "Basic";
#import "File";
#import "Math";
