const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Declare dependency (must be fetched via `zig fetch --save` to populate build.zig.zon)
    const mcp_dep = b.dependency("mcp", .{
        .target = target,
        .optimize = optimize,
    });

    const mcp_mod = mcp_dep.module("mcp");

    const exe = b.addExecutable(.{
        .name = "zig-demo-mcp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("mcp", mcp_mod);

    b.installArtifact(exe);

    // Client executable (simple request emitter)
    const client = b.addExecutable(.{
        .name = "zig-demo-client",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/client.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(client);
}
