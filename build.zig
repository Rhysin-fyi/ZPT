const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "ZPT",
        .root_module = exe_mod,
    });

    const lua_dep = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
    });
    // adds the zlua module and lua artifact
    exe.root_module.addImport("zlua", lua_dep.module("zlua"));

    //exe.linkLibC();
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    // usage: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_exe.step);
}
