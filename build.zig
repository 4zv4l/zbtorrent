const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("bitorrent", .{
        .root_source_file = b.path("src/bitorrent.zig"),
        .target = target,
        .optimize = optimize,
    });
    const bencode = b.dependency("bencode", .{}).module("bencode");
    mod.addImport("bencode", bencode);
}
