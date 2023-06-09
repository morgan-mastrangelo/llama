const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "llama",
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibCpp();
    lib.addIncludePath(".");
    lib.addIncludePath("examples");
    lib.addCSourceFiles(&.{
        "ggml.c",
    }, &.{"-std=c11"});
    lib.addCSourceFiles(&.{
        "llama.cpp",
        "examples/common.cpp",
    }, &.{"-std=c++11"});
    lib.install();

    const build_args = .{ .b = b, .lib = lib, .target = target, .optimize = optimize };
    const exe = build_example("main", build_args);
    _ = build_example("quantize", build_args);
    _ = build_example("perplexity", build_args);
    _ = build_example("embedding", build_args);

    // create "zig build run" command for ./main

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn build_example(comptime name: []const u8, args: anytype) *std.build.LibExeObjStep {
    const b = args.b;
    const lib = args.lib;
    const target = args.target;
    const optimize = args.optimize;

    const exe = b.addExecutable(.{
        .name = name,
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(".");
    exe.addIncludePath("examples");
    exe.addCSourceFiles(&.{
        std.fmt.comptimePrint("examples/{s}/{s}.cpp", .{name, name}),
    }, &.{"-std=c++11"});
    exe.linkLibrary(lib);
    exe.install();

    return exe;
}
