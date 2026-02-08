const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");

input_ctx: *av.FormatContext,
video_stream: i32,
// video: *av.AVStream,
// yuv_frame: *av.AVFrame,
// rgba_frame: *av.AVFrame,
// buffer: []u8,
// sws_ctx: *av.sws.Context,
pkt: *av.Packet,
const Self = @This();
pub fn init(uri: [:0]const u8) !Self {
    const pkt = try av.Packet.alloc();
    errdefer pkt.free();
    const input_ctx = try av.FormatContext.open_input(uri, null, null, null);
    errdefer input_ctx.close_input();
    // TODO: might also need to call find_stream_info
    const video_stream, const codec = try input_ctx.find_best_stream(.VIDEO, -1, -1);
    if (!codec.is_decoder()) {
        @panic("not a decoder");
    }
    const video = input_ctx.streams[video_stream];
    std.log.debug("video: {}", .{video});
    return .{ .pkt = pkt, .input_ctx = input_ctx, .video_stream = video_stream };
}

pub fn deinit(self: *Self) void {
    self.pkt.free();
}

test "init" {
    const s = try Self.init("");
    s.deinit();
}
