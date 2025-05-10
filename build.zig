const std = @import("std");

pub fn build(b: *std.Build) !void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const demo_name = b.option([]const u8, "demo", "Which demo to build (e.g. text, pulse, wave)");
  const test_file = b.option([]const u8, "file", "Path to a Zig test file to run");

  // Modules
  const zigma = b.createModule(.{
    .root_source_file = . { .cwd_relative = "zigma/ma.zig" },
    .target = target,
    .optimize = optimize,
  });

  // Dependencies
  const system_libs = [_][]const u8{
    "raylib", "m"
  };


  // Setup exe
  const exe = b.addExecutable(.{
    .name = demo_name orelse "default",
    .root_source_file = .{ .cwd_relative = try std.fmt.allocPrint(b.allocator, "{s}/main.zig", .{demo_name orelse "default"})},
    .target = target,
    .optimize = optimize,
  });

  exe.root_module.addImport("zigma", zigma);
  inline for (system_libs) |lib|
    exe.linkSystemLibrary(lib);

  const run_exec = b.addRunArtifact(exe);
  b.step("run", "Run the demo").dependOn(&run_exec.step);
  b.default_step.dependOn(&exe.step);


  // Setup test
  const test_step = b.step("test", "Run unit tests");

  var dir = try std.fs.cwd().openDir("./", .{ .iterate = true });
  defer dir.close();

  var it = try dir.walk(b.allocator);
  while (try it.next()) |entry| {
    if (entry.kind != .file) continue;
    if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

    if (test_file) |filter|
      if (!std.mem.endsWith(u8, entry.path, filter)) continue;

    const tst = b.addTest(.{
      .root_source_file = .{ .cwd_relative = entry.path },
    });

    tst.root_module.addImport("zigma", zigma);
    inline for (system_libs) |lib|
      tst.linkSystemLibrary(lib);

    const run_test = b.addRunArtifact(tst);
    test_step.dependOn(&run_test.step);
  }
}
