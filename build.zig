const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Export Module for pkg mgmt.
    const mod = b.addModule("libinput", .{
        .root_source_file = b.path("src/libinput_core.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    mod.linkSystemLibrary("libinput", .{
        .needed = true,
        .preferred_link_mode = .dynamic,
    });
    mod.linkSystemLibrary("libudev", .{
        .needed = true,
        .preferred_link_mode = .dynamic,
    });

    const exe = b.addExecutable(.{
        .name = "zigLibInput",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("libinput", mod);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
