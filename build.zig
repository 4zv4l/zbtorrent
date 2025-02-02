const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("btorrent", .{
        .root_source_file = b.path("src/btorrent.zig"),
        .target = target,
        .optimize = optimize,
    });
    const bencode = b.dependency("zbencode", .{}).module("bencode");
    mod.addImport("bencode", bencode);

    const run_unit_tests = b.addRunArtifact(b.addTest(.{
        .root_module = mod,
        .target = target,
        .optimize = optimize,
    }));
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
