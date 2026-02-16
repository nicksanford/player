//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");
const Decoder = @import("Decoder.zig");

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
    decoder: ?Decoder = null,
    file_dropped: bool = false,
    opts: Options = .{},
    texture: ?rl.Texture2D = null,
    image: rl.Image,

    const Self = @This();
    fn init() !Self {
        std.log.debug("allocating packet", .{});
        rl.initWindow(800, 450, "raylib-zig [core] example - basic window");
        const width = @divFloor(rl.getMonitorWidth(0), 2);
        const height = @divFloor(rl.getMonitorHeight(0), 2);
        const app: Self = .{ .window_width = width, .window_height = height, .image = rl.genImageColor(width, height, .red) };
        rl.setWindowSize(app.window_width, app.window_height);
        rl.setWindowState(.{ .window_resizable = true });
        rl.setTargetFPS(app.targetFPS);
        return app;
    }

    fn deinit(self: *Self) void {
        if (self.decoder) |*d| {
            d.deinit();
        }
        if (self.texture) |texture| {
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

    fn handleFilesDropped(self: *Self) !void {
        if (rl.isFileDropped()) {
            if (self.decoder) |decoder| {
                decoder.deinit();
                self.decoder = null;
            }
            self.file_dropped = true;
            const dropped_files = rl.loadDroppedFiles();
            defer rl.unloadDroppedFiles(dropped_files);
            if (dropped_files.count != 1) {
                // TODO: when this happens implement
                // a files menu that allows you to switch
                // between the different files provided
                unreachable;
            }

            const path: [:0]const u8 = std.mem.span(dropped_files.paths[0]);
            if (rl.isFileExtension(path, ".mp4")) {
                self.decoder = Decoder.init(path, self.window_width, self.window_height) catch null;
            } else {
                if (self.texture) |texture| {
                    texture.unload();
                }
                self.texture = rl.loadTexture(path) catch null;
                if (self.texture) |texture| {
                    self.window_width = texture.width;
                    self.window_height = texture.height;
                    rl.setWindowSize(self.window_width, self.window_height);
                }
            }
        }
    }

    fn decode(self: *Self) !void {
        if (self.decoder) |decoder| {
            const frame = try decoder.next();
            if (frame == null) {
                return;
            }
            // self.image.width = self.frame.width;
        }
    }
    fn draw(self: *Self) void {
        rl.beginDrawing();
        rl.clearBackground(.white);

        if (self.texture) |texture| {
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
        try app.handleFilesDropped();
        try app.decode();
        app.draw();
    }
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("Decoder.zig");
    // const x = try av.Packet.alloc();
    // x.free();
}
