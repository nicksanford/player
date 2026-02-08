const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");

pkt: *av.Packet,
input_ctx: *av.FormatContext,
output_ctx: *av.Codec.Context,
video_stream: u32,
video: *av.Stream,
yuv_frame: *av.Frame,
rgba_frame: *av.Frame,
// buffer: []u8,
// sws_ctx: *av.sws.Context,
const Self = @This();
pub fn init(uri: [:0]const u8) !Self {
    const pkt = try av.Packet.alloc();
    errdefer pkt.free();

    const input_ctx = try av.FormatContext.open_input(uri, null, null, null);
    errdefer input_ctx.close_input();

    // TODO: might also need to call find_stream_info
    const video_stream, const codec = try input_ctx.find_best_stream(.VIDEO, -1, -1);
    const video = input_ctx.streams[video_stream];
    std.log.debug("video_idx: {d}, id: {d}, avg_frame_rate: {d}/{d}, duration: {d}, width: {d}, height: {d}, codec_id: {d}, format: {d}\n", .{ video.index, video.id, video.avg_frame_rate.num, video.avg_frame_rate.den, video.duration, video.codecpar.width, video.codecpar.height, video.codecpar.codec_id, video.codecpar.format });
    std.log.debug("codec name: {s}\n", .{codec.long_name.?});

    const codec_ctx = try av.Codec.Context.alloc(codec);
    errdefer codec_ctx.free();

    const yuv_frame = try av.Frame.alloc();
    errdefer yuv_frame.free();

    const rgba_frame = try av.Frame.alloc();
    errdefer rgba_frame.free();

    // av.sws.Context.get(video.codecpar.width, video.codecpar.height, .AV_PIX_FMT_YUV420P, );

    return .{
        .pkt = pkt,
        .input_ctx = input_ctx,
        .output_ctx = codec_ctx,
        .video_stream = @as(u32, video_stream),
        .video = video,
        .yuv_frame = yuv_frame,
        .rgba_frame = rgba_frame,
    };
}

pub fn deinit(self: *Self) void {
    self.pkt.free();
    self.input_ctx.close_input();
    self.yuv_frame.free();
    self.rgba_frame.free();
}

test "nick init" {
    std.testing.log_level = .debug;
    var s = try Self.init("/home/user/Downloads/bbb_sunflower_2160p_60fps_normal.mp4");
    s.deinit();
}
