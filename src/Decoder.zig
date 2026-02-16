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

fn scaleMaintainingAspectRatio(src_width: u32, src_height: u32, target_width: u32, target_height: u32) struct { u32, u32 } {
    const fsrc_width: f32 = @as(f32, @floatFromInt(src_width));
    const fsrc_height: f32 = @as(f32, @floatFromInt(src_height));
    const fwindow_width: f32 = @as(f32, @floatFromInt(target_width));
    const fwindow_height: f32 = @as(f32, @floatFromInt(target_height));
    if (src_width <= target_width and src_height <= target_height) {
        // no need to scale as the window is greater in both
        // dimensions
        return .{ src_width, src_height };
    }

    const src_aspect_ratio: f32 = fsrc_width / fsrc_height;
    const window_aspect_ratio: f32 = fwindow_width / fwindow_height;
    var output_width: f32 = undefined;
    var output_height: f32 = undefined;
    if (src_width >= src_height) {
        // horizontal
        if (src_aspect_ratio >= window_aspect_ratio) {
            output_width = @divFloor(fwindow_width, 2) * 2;
            output_height = @divFloor(fwindow_width * (fsrc_height / fsrc_width), 2) * 2;
        } else {
            output_width = @divFloor(fwindow_height * (fsrc_width / fsrc_height), 2) * 2;
            output_height = @divFloor(fwindow_height, 2) * 2;
        }

        return .{ @intFromFloat(output_width), @intFromFloat(output_height) };
    }
    // TODO: vertical video unimplemented
    unreachable;
}

fn f(x: u32) struct { u32, u32 } {
    return .{ x, x };
}
test "f" {
    const Test = struct {
        x: u32,
        out1: u32,
        out2: u32,
    };
    const tests = [_]Test{
        .{ .x = 1, .out1 = 1, .out2 = 1 },
    };

    for (tests) |t| {
        try std.testing.expectEqual(f(t.x), struct { u32, u32 }{ t.out1, t.out2 });
    }
}

test "fitWindow" {
    const Test = struct {
        src_width: u32,
        src_height: u32,
        window_width: u32,
        window_height: u32,
        output_width: u32,
        output_height: u32,
    };
    const tests = [_]Test{
        // equal
        .{ .src_width = 3840, .src_height = 2160, .window_width = 3840, .window_height = 2160, .output_width = 3840, .output_height = 2160 },
        // media smaller than window
        .{ .src_width = 3840, .src_height = 2160, .window_width = 4000, .window_height = 2160, .output_width = 3840, .output_height = 2160 },
        .{ .src_width = 3840, .src_height = 2160, .window_width = 3840, .window_height = 3000, .output_width = 3840, .output_height = 2160 },
        .{ .src_width = 3840, .src_height = 2160, .window_width = 4000, .window_height = 3000, .output_width = 3840, .output_height = 2160 },
        // media larger than window
        .{ .src_width = 3840, .src_height = 2160, .window_width = 1280, .window_height = 720, .output_width = 1280, .output_height = 720 },
        .{ .src_width = 3840, .src_height = 2160, .window_width = 1280, .window_height = 800, .output_width = 1280, .output_height = 720 },
        .{ .src_width = 3840, .src_height = 2160, .window_width = 2000, .window_height = 720, .output_width = 1280, .output_height = 720 },
        .{ .src_width = 3840, .src_height = 2160, .window_width = 2001, .window_height = 1000, .output_width = 1776, .output_height = 1000 },
    };

    for (tests) |t| {
        try std.testing.expectEqual(.{ t.output_width, t.output_height }, scaleMaintainingAspectRatio(t.src_width, t.src_height, t.window_width, t.window_height));
    }
}
// test "nick init" {
//     std.testing.log_level = .debug;
//     var s = try Self.init("/home/user/Downloads/bbb_sunflower_2160p_60fps_normal.mp4");
//     s.deinit();
// }
