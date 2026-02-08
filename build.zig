const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ffmpeg_dep = b.dependency("ffmpeg", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");

    const mod = b.addModule("player", .{
        // The root source file is the "entry point" of this module. Users of
        // this module will only be able to access public declarations contained
        // in this file, which means that if you have declarations that you
        // intend to expose to consumers that were defined in other files part
        // of this module, you will have to make sure to re-export them from
        // the root file.
        .root_source_file = b.path("src/root.zig"),
        // Later on we'll use this module as the root module of a test executable
        // which requires us to specify a target.
        .target = target,
    });
    mod.addImport("raylib", raylib);
    mod.linkLibrary(ffmpeg_dep.artifact("ffmpeg"));
    mod.addImport("ffmpeg", ffmpeg_dep.module("av"));

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "player", .module = mod },
        },
    });
    // exe_mod.addImport("raylib", raylib);
    // exe_mod.linkLibrary(ffmpeg_dep.artifact("ffmpeg"));
    // exe_mod.addImport("ffmpeg", ffmpeg_dep.module("av"));

    const run_step = b.step("run", "Run the app");

    //web exports are completely separate
    // if (target.query.os_tag == .emscripten) {
    //     const emsdk = rlz.emsdk;
    //     const wasm = b.addLibrary(.{
    //         .name = "'$PROJECT_NAME'",
    //         .root_module = exe_mod,
    //     });
    //
    //     const install_dir: std.Build.InstallDir = .{ .custom = "web" };
    //     const emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{ .optimize = optimize });
    //     const emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{ .optimize = optimize });
    //
    //     const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
    //         .optimize = optimize,
    //         .flags = emcc_flags,
    //         .settings = emcc_settings,
    //         .shell_file_path = emsdk.shell(raylib_dep.builder),
    //         .install_dir = install_dir,
    //         .embed_paths = &.{.{ .src_path = "resources/" }},
    //     });
    //     b.getInstallStep().dependOn(emcc_step);
    //
    //     const html_filename = try std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name});
    //     const emrun_step = emsdk.emrunStep(
    //         b,
    //         b.getInstallPath(install_dir, html_filename),
    //         &.{},
    //     );
    //
    //     emrun_step.dependOn(emcc_step);
    //     run_step.dependOn(emrun_step);
    // } else {
    const exe = b.addExecutable(.{
        .name = "player",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    run_step.dependOn(&run_cmd.step);
    // }
}
