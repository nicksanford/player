//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");

pub const DecoderCtx = struct {
    // input_ctx: *av.AVFormatContext,
    // video_stream: i32,
    // video: *av.AVStream,
    // yuv_frame: *av.AVFrame,
    // rgba_frame: *av.AVFrame,
    // buffer: []u8,
    // sws_ctx: *av.sws.Context,
    pkt: *av.Packet,
    pub fn init() !DecoderCtx {
        const pkt = try av.Packet.alloc();
        return .{ .pkt = pkt };
    }

    pub fn deinit(self: *DecoderCtx) void {
        self.pkt.free();
    }
};

pub fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn run() anyerror!void {
    var x: DecoderCtx = try .init();
    defer x.deinit();
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow(); // Close window and OpenGL context

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        rl.drawText("Congrats! You created your first window!", 190, 200, 20, .light_gray);
        //----------------------------------------------------------------------------------
    }
}

test "basic add functionality" {
    try std.testing.expect(add(3, 7) == 10);
}
