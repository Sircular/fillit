const std = @import("std");
const glfw = @import("glfw");
const gl = @import("opengl");

const log = std.log;

const mesh = @import("mesh.zig");
const Mesh = mesh.Mesh;
const Point = mesh.Point;

const VertexDatum = packed struct {
    pos: Point,
};

fn fb_size_callback(_: glfw.Window, width: u32, height: u32) void {
    gl.viewport(0, 0, @intCast(c_int, width), @intCast(c_int, height));
}

fn get_proc_address(_: void, proc_name: [:0]const u8) ?*const anyopaque {
    if (glfw.getProcAddress(proc_name)) |proc| {
        return @ptrCast(*const anyopaque, proc);
    }
    return null;
}

fn process_inputs(window: glfw.Window) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
}

fn compile_shader(shader_type: gl.GLenum, source: [*c]const u8) !c_uint {
    var shader_id: c_uint = gl.createShader(shader_type);
    gl.shaderSource(shader_id, 1, &source, null);
    gl.compileShader(shader_id);

    var success: c_int = 0;
    gl.getShaderiv(shader_id, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var buf = [_:0]u8{0} ** 512;
        gl.getShaderInfoLog(shader_id, buf.len, null, &buf);
        log.err("Could not compile shader: {s}", .{buf});
        return error.ShaderCompileError;
    }

    return shader_id;
}
fn create_shader_program() !c_uint {
    const vertex_shader = try compile_shader(gl.VERTEX_SHADER,
        \\
        \\ #version 330 core
        \\ layout (location = 0) in vec3 aPos;
        \\ // layout (location = 1) in vec3 aColor;
        \\
        \\ out vec3 vertColor;
        \\
        \\ void main()
        \\ {
        \\   gl_Position = vec4(aPos, 1.0);
        \\   // vertColor = aColor;
        \\   vertColor = vec3(0, 1.0, 0);
        \\ }
        \\
    );
    defer gl.deleteShader(vertex_shader);

    const fragment_shader = try compile_shader(gl.FRAGMENT_SHADER,
        \\
        \\ # version 330 core
        \\ out vec4 FragColor;
        \\
        \\ in vec3 vertColor;
        \\
        \\ void main()
        \\ {
        \\   FragColor = vec4(vertColor, 1.0);
        \\ }
    );
    defer gl.deleteShader(fragment_shader);

    const program = gl.createProgram();
    gl.attachShader(program, vertex_shader);
    gl.attachShader(program, fragment_shader);
    gl.linkProgram(program);

    var success: c_int = 0;
    gl.getProgramiv(program, gl.LINK_STATUS, &success);
    if (success == 0) {
        var buf = [_:0]u8{0} ** 512;
        gl.getProgramInfoLog(program, buf.len, null, &buf);
        log.err("Could not compile shader: {s}", .{buf});
        return error.ShaderCompileError;
    }
    return program;
}

pub fn main() anyerror!u8 {
    try glfw.init(.{});
    defer glfw.terminate();

    const window = try glfw.Window.create(800, 600, "foobar", null, null, .{
        .client_api = .opengl_api,
        .context_version_major = 3,
        .context_version_minor = 3,
    });
    defer window.destroy();
    try glfw.makeContextCurrent(window);

    try gl.load({}, get_proc_address);

    gl.viewport(0, 0, 800, 600);
    window.setFramebufferSizeCallback(fb_size_callback);

    const attr_types = [_]mesh.VertexAttributeType{
        .{ .size = 3, .type_ = gl.FLOAT, .start = 0, .normalize = false },
        .{ .size = 3, .type_ = gl.FLOAT, .start = 3 * @sizeOf(f32), .normalize = false },
    };

    std.log.info("Total size of vertex is {} bytes", .{@sizeOf(VertexDatum)});

    const vertices = [_]VertexDatum{
        .{ .pos = .{ .x = -0.5, .y = -0.5, .z = 0 } },
        .{ .pos = .{ .x = -0.5, .y = 0.5, .z = 0 } },
        .{ .pos = .{ .x = 0.5, .y = 0.5, .z = 0 } },
        .{ .pos = .{ .x = 0.5, .y = -0.5, .z = 0 } },
    };

    const faces = [_]u32{
        0, 1, 2,
        0, 3, 2,
    };

    var themesh = Mesh.init();
    defer themesh.deinit();

    themesh.write_mesh(VertexDatum, &vertices, &faces, &attr_types);

    const shader_prog = try create_shader_program();
    defer gl.deleteProgram(shader_prog);

    while (!window.shouldClose()) {
        try glfw.pollEvents();
        process_inputs(window);

        gl.clearColor(0, 0, 0, 1);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shader_prog);
        gl.bindVertexArray(themesh.vao);
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, @intToPtr(?*anyopaque, 0));

        try window.swapBuffers();
    }

    return 0;
}
