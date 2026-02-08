const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");

// input_ctx: *av.AVFormatContext,
// video_stream: i32,
// video: *av.AVStream,
// yuv_frame: *av.AVFrame,
// rgba_frame: *av.AVFrame,
// buffer: []u8,
// sws_ctx: *av.sws.Context,
pkt: *av.Packet,
const Self = @This();
pub fn init() !Self {
    const pkt = try av.Packet.alloc();
    return .{ .pkt = pkt };
}

pub fn deinit(self: *Self) void {
    self.pkt.free();
}
