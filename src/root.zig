//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");
const Decoder = @import("decoder.zig");

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

const Options = packed struct {
    __reserved: bool = false,
    drawFPS: bool = true,
    __reserved2: bool = false,
    __reserved3: bool = false,
    __reserved4: bool = false,
    __reserved5: bool = false,
    __reserved6: bool = false,
    __reserved7: bool = false,
};

const App = struct {
    window_width: i32 = 800,
    window_height: i32 = 450,
    targetFPS: i32 = 60,
    decoder: Decoder,
    file_dropped: bool = false,
    opts: Options = .{},

    const Self = @This();
    fn init() !Self {
        const decoder = try Decoder.init();
        return .{
            .decoder = decoder,
        };
    }

    fn deinit(self: *Self) void {
        self.decoder.deinit();
    }
};

pub fn run() anyerror!void {
    var x = try Decoder.init();
    defer x.deinit();
    var app = try App.init();
    defer app.deinit();
    rl.initWindow(app.window_height, app.window_width, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context
    app.window_width = @divFloor(rl.getMonitorWidth(0), 2);
    app.window_height = @divFloor(rl.getMonitorHeight(0), 2);
    rl.setWindowSize(app.window_width, app.window_height);
    rl.setWindowState(.{ .window_resizable = true });
    rl.setTargetFPS(app.targetFPS);
    // var buf: [4096]u8 = undefined;
    // var fba = std.heap.FixedBufferAllocator.init(&buf);
    // const scratch_allocator = fba.allocator();
    //--------------------------------------------------------------------------------------

    // Main game loop
    var texture: rl.Texture2D = .{ .id = 0, .width = 0, .height = 0, .mipmaps = 0, .format = .uncompressed_grayscale };
    defer {
        if (rl.isTextureValid(texture)) {
            texture.unload();
        }
    }
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        if (rl.isWindowResized()) {
            app.window_width = rl.getScreenWidth();
            app.window_height = rl.getScreenHeight();
        }

        // TODO pause

        if (rl.isKeyPressed(rl.KeyboardKey.t)) {
            rl.toggleFullscreen();
            app.window_width = rl.getScreenWidth();
            app.window_height = rl.getScreenHeight();
        }

        if (rl.isFileDropped()) {
            const dropped_files = rl.loadDroppedFiles();
            // TODO: when this happens implement
            // a files menu that allows you to switch
            // between the different files provided
            if (dropped_files.count != 1) {
                unreachable;
            }

            const path: [:0]const u8 = std.mem.span(dropped_files.paths[0]);
            if (rl.isFileExtension(path, ".mp4")) {
                unreachable;
            } else {
                if (rl.isTextureValid(texture)) {
                    texture.unload();
                }
                texture = try rl.loadTexture(path);
                app.window_width = texture.width;
                app.window_height = texture.height;
                rl.setWindowSize(app.window_width, app.window_height);
            }
            // const length = rl.textLength(ret);
            // std.log.debug("path: {s}, len: {d}, slice_len: {d}\n", .{ path_raw, length, ret.len });
            // TODO: reset decoder
            defer std.debug.print("executed unloadDroppedFiles\n", .{});
            defer rl.unloadDroppedFiles(dropped_files);
            defer std.debug.print("executing unloadDroppedFiles\n", .{});
        }
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        rl.drawTexture(texture, 0, 0, .white);
        if (app.opts.drawFPS) {
            rl.drawFPS(100, 100);
        }
        defer rl.endDrawing();

        rl.clearBackground(.white);
        //----------------------------------------------------------------------------------
    }
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
