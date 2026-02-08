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
    window_width: i32,
    window_height: i32,
    targetFPS: i32 = 60,
    decoder: ?Decoder,
    file_dropped: bool = false,
    opts: Options = .{},
    maybe_texture: ?rl.Texture2D = null,

    const Self = @This();
    fn init() !Self {
        std.log.debug("allocating packet", .{});
        const x = try av.Packet.alloc();
        x.free();
        rl.initWindow(800, 450, "raylib-zig [core] example - basic window");
        const app: Self = .{
            .window_width = @divFloor(rl.getMonitorWidth(0), 2),
            .window_height = @divFloor(rl.getMonitorHeight(0), 2),
            .decoder = null,
        };
        rl.setWindowSize(app.window_width, app.window_height);
        rl.setWindowState(.{ .window_resizable = true });
        rl.setTargetFPS(app.targetFPS);
        return app;
    }

    fn deinit(self: *Self) void {
        if (self.decoder) |*d| {
            d.deinit();
        }
        if (self.maybe_texture) |texture| {
            texture.unload();
        }
        rl.closeWindow(); // Close window and OpenGL context
    }

    fn handleResize(self: *Self) void {
        if (rl.isWindowResized()) {
            self.window_width = rl.getScreenWidth();
            self.window_height = rl.getScreenHeight();
        }
    }

    fn handleToggleFullScreen(self: *Self) void {
        if (rl.isKeyPressed(rl.KeyboardKey.t)) {
            rl.toggleFullscreen();
            self.window_width = rl.getScreenWidth();
            self.window_height = rl.getScreenHeight();
        }
    }

    fn handleFilesDropped(self: *Self) void {
        if (rl.isFileDropped()) {
            self.file_dropped = true;
            const dropped_files = rl.loadDroppedFiles();
            defer rl.unloadDroppedFiles(dropped_files);
            // TODO: reset decoder
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
                if (self.maybe_texture) |texture| {
                    texture.unload();
                }
                self.maybe_texture = rl.loadTexture(path) catch null;
                if (self.maybe_texture) |texture| {
                    self.window_width = texture.width;
                    self.window_height = texture.height;
                    rl.setWindowSize(self.window_width, self.window_height);
                }
            }
        }
    }

    fn draw(self: *Self) void {
        rl.beginDrawing();
        rl.clearBackground(.white);

        if (self.maybe_texture) |texture| {
            rl.drawTexture(texture, 0, 0, .white);
        } else if (!self.file_dropped) {
            rl.drawText("Drop your file into this window.", 100, 40, 20, .dark_gray);
        } else {
            rl.drawText("That is not a valid file type..", 100, 40, 20, .dark_gray);
            rl.drawText("Drop your file into this window.", 100, 60, 20, .dark_gray);
        }

        if (self.opts.drawFPS) {
            rl.drawFPS(100, 100);
        }
        defer rl.endDrawing();
    }
};

pub fn run() anyerror!void {
    var app = try App.init();
    defer app.deinit();
    while (!rl.windowShouldClose()) {
        app.handleResize();
        app.handleToggleFullScreen();
        app.handleFilesDropped();
        app.draw();
    }
}

test "basic add functionality" {
    const s = try Decoder.init("");
    s.deinit();
}
