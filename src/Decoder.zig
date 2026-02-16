const std = @import("std");
const av = @import("ffmpeg");
const rl = @import("raylib");

pkt: *av.Packet,
demuxer_ctx: *av.FormatContext,
decoder_ctx: *av.Codec.Context,
video_stream: u32,
video: *av.Stream,
yuv_frame: *av.Frame,
rgba_frame: *av.Frame,
sws_ctx: *av.sws.Context,
// buffer: []u8,
// sws_ctx: *av.sws.Context,
const Self = @This();
// pub fn getFormat(s: *av.Codec.Context, fmt: *const av.PixelFormat) callconv(.c) av.PixelFormat {
//     while (p = fmt; )
//
// }

pub fn init(uri: [:0]const u8, width: i32, height: i32) !Self {
    const pkt = try av.Packet.alloc();
    errdefer pkt.free();

    const input_ctx = try av.FormatContext.open_input(uri, null, null, null);
    errdefer input_ctx.close_input();

    // std.log.debug("\n", .{});
    // std.log.debug("BEFORE: pkt.size {d}, stream_index: {d}\n", .{ pkt.size, pkt.stream_index });
    // try input_ctx.read_frame(pkt);
    // std.log.debug("AFTER 1: pkt.size {d}, stream_index: {d}\n", .{ pkt.size, pkt.stream_index });
    // try input_ctx.read_frame(pkt);
    // std.log.debug("AFTER 2: pkt.size {d}, stream_index: {d}\n", .{pkt.size, pkt.stream_index});
    // pkt.unref();
    // try input_ctx.read_frame(pkt);
    // std.log.debug("AFTER 3: pkt.size {d}, stream_index: {d}\n", .{pkt.size, pkt.stream_index});
    // pkt.unref();

    // TODO: might also need to call find_stream_info
    const video_stream, const codec = try input_ctx.find_best_stream(.VIDEO, -1, -1);
    const video = input_ctx.streams[video_stream];
    std.log.debug(
        "video_idx: {d}, id: {d}, avg_frame_rate: {d}/{d}, duration: {d}, width: {d}, height: {d}, codec_id: {d}, format: {d}\n",
        .{
            video.index,
            video.id,
            video.avg_frame_rate.num,
            video.avg_frame_rate.den,
            video.duration,
            video.codecpar.width,
            video.codecpar.height,
            video.codecpar.codec_id,
            video.codecpar.format,
        },
    );
    std.log.debug("codec name: {s}, is_decoder: {}\n", .{ codec.long_name.?, codec.is_decoder() });

    const decoder_ctx = try av.Codec.Context.alloc(codec);
    errdefer decoder_ctx.free();

    try decoder_ctx.parameters_to_context(video.codecpar);
    // decoder_ctx.get_format = getFormat;
    try decoder_ctx.open(codec, null);

    const yuv_frame = try av.Frame.alloc();
    errdefer yuv_frame.free();

    const rgba_frame = try av.Frame.alloc();
    errdefer rgba_frame.free();

    const out_width, const out_height = scaleMaintainingAspectRatio(@intCast(video.codecpar.width), @intCast(video.codecpar.height), width, height);

    const sws_ctx = try av.sws.Context.get(
        video.codecpar.width,
        video.codecpar.height,
        .YUV420P,
        @intCast(out_width),
        @intCast(out_height),
        .RGBA,
        .{ .FAST_BILINEAR = true },
        null,
        null,
        null,
    );

    return .{
        .pkt = pkt,
        .demuxer_ctx = input_ctx,
        .decoder_ctx = decoder_ctx,
        .video_stream = @as(u32, video_stream),
        .video = video,
        .yuv_frame = yuv_frame,
        .rgba_frame = rgba_frame,
        .sws_ctx = sws_ctx,
    };
}

pub fn next(self: *const Self) !?*av.Frame {
    std.log.debug("video_stream: {d}\n", .{self.video_stream});
    var i: u32 = 0;
    while (true) {
        std.log.debug("NICK: {d}\n", .{i});
        i += 1;
        try self.demuxer_ctx.read_frame(self.pkt);
        if (self.video_stream != self.pkt.stream_index) {
            std.log.debug("self.video_stream != self.pkt.stream_index\n", .{});
            continue;
        }
        std.log.debug("PKT: size: {d}, self.pkt.duration: {d}, self.pkt.stream_index: {d}\n", .{ self.pkt.size, self.pkt.duration, self.pkt.stream_index });
        try self.decoder_ctx.send_packet(self.pkt);
        self.pkt.unref();
        // test for eagain or eof and break if so
        self.decoder_ctx.receive_frame(self.yuv_frame) catch |err| {
            if (err == av.Error.EndOfFile) {
                std.log.err("NICK! error: {s}\n", .{@errorName(err)});
                return null;
            }

            if (err == av.Error.WouldBlock) {
                std.log.info("NICK!! error: {s}\n", .{@errorName(err)});
                continue;
            }
            return err;
        };

        try self.sws_ctx.scale_frame(self.rgba_frame, self.yuv_frame);
        return self.rgba_frame;
    }
}

pub fn deinit(self: Self) void {
    self.pkt.free();
    self.demuxer_ctx.close_input();
    self.yuv_frame.free();
    self.rgba_frame.free();
    self.sws_ctx.free();
}

fn scaleMaintainingAspectRatio(src_width: i32, src_height: i32, target_width: i32, target_height: i32) struct { i32, i32 } {
    const fsrc_width: f32 = @as(f32, @floatFromInt(src_width));
    const fsrc_height: f32 = @as(f32, @floatFromInt(src_height));
    const ftarget_width: f32 = @as(f32, @floatFromInt(target_width));
    const ftarget_height: f32 = @as(f32, @floatFromInt(target_height));
    const derived_target_width: f32 = fsrc_width / fsrc_height * ftarget_height;
    const derived_target_height: f32 = fsrc_height / fsrc_width * ftarget_width;

    if (derived_target_width <= ftarget_width) {
        return .{ @intFromFloat(derived_target_width), @intFromFloat(ftarget_height) };
    }

    if (derived_target_height <= ftarget_height) {
        return .{ @intFromFloat(ftarget_width), @intFromFloat(derived_target_height) };
    }

    unreachable;
}

test "fitWindow" {
    const Test = struct {
        src_width: i32,
        src_height: i32,
        target_width: i32,
        target_height: i32,
        output_width: i32,
        output_height: i32,
    };
    const tests = [_]Test{
        // width longer than height
        // equal
        .{ .src_width = 3840, .src_height = 2160, .target_width = 3840, .target_height = 2160, .output_width = 3840, .output_height = 2160 },
        // media smaller than target
        // target width bigger, but height limited
        .{ .src_width = 3840, .src_height = 2160, .target_width = 4000, .target_height = 2160, .output_width = 3840, .output_height = 2160 },
        // target height bigger
        .{ .src_width = 3840, .src_height = 2160, .target_width = 3840, .target_height = 3000, .output_width = 3840, .output_height = 2160 },
        // target width and height bigger, width limiting
        .{ .src_width = 3840, .src_height = 2160, .target_width = 4000, .target_height = 3000, .output_width = 4000, .output_height = 2250 },
        // target width and height bigger, height limiting
        .{ .src_width = 3840, .src_height = 2160, .target_width = 8000, .target_height = 3000, .output_width = 5333, .output_height = 3000 },
        // // media larger than window, height limited
        .{ .src_width = 3840, .src_height = 2160, .target_width = 800, .target_height = 300, .output_width = 533, .output_height = 300 },
        // // media larger than window, width limited
        .{ .src_width = 3840, .src_height = 2160, .target_width = 800, .target_height = 500, .output_width = 800, .output_height = 450 },
        .{ .src_width = 3840, .src_height = 2160, .target_width = 800, .target_height = 451, .output_width = 800, .output_height = 450 },
        .{ .src_width = 3840, .src_height = 2160, .target_width = 801, .target_height = 451, .output_width = 801, .output_height = 450 },

        // width shorter than height
        // equal
        .{ .src_width = 2160, .src_height = 3840, .target_width = 2160, .target_height = 3840, .output_width = 2160, .output_height = 3840 },
        // // media smaller than target
        // // target width bigger, but height limited
        .{ .src_width = 2160, .src_height = 3840, .target_width = 3160, .target_height = 3840, .output_width = 2160, .output_height = 3840 },
        // target height bigger
        .{ .src_width = 2160, .src_height = 3840, .target_width = 2160, .target_height = 4840, .output_width = 2160, .output_height = 3840 },
        // target width and height bigger, width limiting
        .{ .src_width = 2160, .src_height = 3840, .target_width = 3160, .target_height = 5840, .output_width = 3160, .output_height = 5617 },
        // target width and height bigger, height limiting
        .{ .src_width = 2160, .src_height = 3840, .target_width = 8160, .target_height = 4840, .output_width = 2722, .output_height = 4840 },
        // media larger than window, height limited
        .{ .src_width = 2160, .src_height = 3840, .target_width = 816, .target_height = 484, .output_width = 272, .output_height = 484 },
        // // media larger than window, width limited
        .{ .src_width = 2160, .src_height = 3840, .target_width = 272, .target_height = 884, .output_width = 272, .output_height = 483 },
    };

    for (tests) |t| {
        try std.testing.expectEqual(.{ t.output_width, t.output_height }, scaleMaintainingAspectRatio(t.src_width, t.src_height, t.target_width, t.target_height));
    }
}
test "nick init" {
    std.testing.log_level = .debug;
    av.av_log_set_level(.DEBUG);
    var s = try Self.init("/home/user/Downloads/bbb_sunflower_2160p_60fps_normal.mp4", 800, 450);
    var maybe_frame = try s.next();
    try std.testing.expect(maybe_frame != null);
    try std.testing.expect(maybe_frame.?.buf[0] != null);
    try std.testing.expectEqual(1459328, maybe_frame.?.buf[0].?.size);
    for (1..8) |i| {
        try std.testing.expect(maybe_frame.?.buf[i] == null);
    }

    for (0..100) |_| {
        _ = try s.next();
    }

    maybe_frame = try s.next();
    try std.testing.expect(maybe_frame != null);
    try std.testing.expect(maybe_frame.?.buf[0] != null);
    try std.testing.expectEqual(1459328, maybe_frame.?.buf[0].?.size);
    for (1..8) |i| {
        try std.testing.expect(maybe_frame.?.buf[i] == null);
    }

    s.deinit();
}
