const std = @import("std");

pub fn build(b: *std.Build) void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const demo_name = b.option([]const u8, "demo", "Which demo to build (e.g. text, pulse, wave)");

  const exe = b.addExecutable(.{
    .name = demo_name orelse "default",
    .root_source_file = .{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/main.zig", .{demo_name orelse "default"}) catch unreachable },
    .target = target,
    .optimize = optimize,
  });

  exe.linkSystemLibrary("raylib");
  exe.linkSystemLibrary("m");
  exe.linkSystemLibrary("GL");
  exe.linkSystemLibrary("pthread");
  exe.linkSystemLibrary("dl");
  exe.linkSystemLibrary("rt");

  const run_step = b.addRunArtifact(exe);
  b.step("run", "Run the demo").dependOn(&run_step.step);

  b.default_step.dependOn(&exe.step);
}
