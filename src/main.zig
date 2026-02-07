const std = @import("std");
const rl = @import("raylib");
const av = @import("ffmpeg");

const DecoderCtx = struct {
    // input_ctx: *av.AVFormatContext,
    // video_stream: i32,
    // video: *av.AVStream,
    // yuv_frame: *av.AVFrame,
    // rgba_frame: *av.AVFrame,
    // buffer: []u8,
    // sws_ctx: *av.sws.Context,
    fn init() DecoderCtx {
    var pkt = try av.Packet.alloc();

    };
    fn deinit() {
    pkt.free();

    };
};


pub fn main() anyerror!void {
    // av.FormatContext.open_input(url: [*:0]const u8, fmt: ?*const InputFormat, options: ?*Mutable, pb: ?*IOContext)
    // const ctx: DecoderCtx = .{
    //     input_ctx: *av.AVFormatContext,
    //     video_stream: i32,
    //     video: *av.AVStream,
    //     yuv_frame: *av.AVFrame,
    //     rgba_frame: *av.AVFrame,
    //     buffer: []u8,
    //     sws_ctx: *av.sws.Context,
    //     }
    // Initialization
    //--------------------------------------------------------------------------------------
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
