const gl = @import("opengl");

pub const Point = packed struct {
    x: f32,
    y: f32,
    z: f32,
};

pub const VertexAttributeType = struct {
    size: c_int,
    type_: c_uint,
    start: usize,
    normalize: bool,
};

pub const Mesh = struct {
    vbo: c_uint,
    vao: c_uint,
    eao: c_uint,

    pub fn init() Mesh {
        var mesh = Mesh{ .vbo = 0, .vao = 0, .eao = 0 };
        gl.genVertexArrays(1, &mesh.vao);
        gl.genBuffers(1, &mesh.vbo);
        gl.genBuffers(1, &mesh.eao);
        return mesh;
    }

    pub fn deinit(self: Mesh) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
        gl.deleteBuffers(1, &self.eao);
    }

    pub fn write_mesh(self: *Mesh, comptime T: type, vertices: []const T, faces: []const u32, attr_sets: []const VertexAttributeType) void {
        _ = attr_sets;
        gl.bindVertexArray(self.vao);
        gl.bindBuffer(gl.ARRAY_BUFFER, self.vbo);
        gl.bufferData(gl.ARRAY_BUFFER, @intCast(i32, @sizeOf(T) * vertices.len), vertices.ptr, gl.STATIC_DRAW);

        var i: c_uint = 0;
        while (i < attr_sets.len) : (i += 1) {
            const attr = attr_sets[i];
            gl.vertexAttribPointer(
                i,
                attr.size,
                attr.type_,
                if (attr.normalize) gl.TRUE else gl.FALSE,
                // gl.FALSE,
                @sizeOf(T),
                @intToPtr(?*anyopaque, attr.start),
            );
            gl.enableVertexAttribArray(i);
            break;
        }

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.eao);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(i32, faces.len * @sizeOf(u32)), faces.ptr, gl.STATIC_DRAW);
    }
};

pub fn tessellate_line(_: Point, _: Point, _: f32, dest: *Mesh) void {
    const vertices = [_]Point{
        Point{ .x = -0.5, .y = -0.5, .z = 0 },
        Point{ .x = 0.5, .y = -0.5, .z = 0 },
        Point{ .x = 0.5, .y = 0.5, .z = 0 },
        Point{ .x = -0.5, .y = -0.5, .z = 0 },
        Point{ .x = -0.5, .y = 0.5, .z = 0 },
        Point{ .x = 0.5, .y = 0.5, .z = 0 },
    };

    const faces = [_]u32{
        0, 1, 2,
        0, 3, 2,
    };

    dest.write_mesh(&vertices, &faces);
    gl.vertexAttribPointer(0, 6, gl.FLOAT, gl.FALSE, @sizeOf(Point), @intToPtr(?*anyopaque, 0));
    gl.enableVertexAttribArray(0);
}
