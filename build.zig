const std = @import("std");

pub fn build(b: *std.Build) !void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  // Dependencies
  const system_libs = [_][]const u8{
    "raylib", "m"
  };

  const demo_name = b.option([]const u8, "demo", "Which demo to build (e.g. text, pulse, wave)");
  const test_file = b.option([]const u8, "test", "Path to a Zig test file to run");

  // Setup exe
  const exe = b.addExecutable(.{
    .name = demo_name orelse "default",
    .root_source_file = .{ .cwd_relative = try std.fmt.allocPrint(b.allocator, "{s}/main.zig", .{demo_name orelse "default"})},
    .target = target,
    .optimize = optimize,
  });

  inline for (system_libs) |lib| {
    exe.linkSystemLibrary(lib);
  }

  // Modules
  exe.root_module.addImport("zigma", b.createModule(.{
    .root_source_file = . { .cwd_relative = "zigma/ma.zig" },
  }));

  // Define run command
  const run_exec = b.addRunArtifact(exe);
  b.step("run", "Run the demo").dependOn(&run_exec.step);
  b.default_step.dependOn(&exe.step);

  // Define test command
  var argv = std.ArrayList([]const u8).init(b.allocator);
  try argv.append("zig");
  try argv.append("test");
  //try argv.append("-femit-llvm-ir");

  inline for (system_libs) |lib| {
    try argv.append("-l" ++ lib);
  }

  const test_step = b.step("test", "Run unit tests");
  if (test_file) |path| {
    try argv.append(path);
    test_step.dependOn(&b.addSystemCommand(argv.items).step);
    _ = argv.pop();
  } else {
    var dir = try std.fs.cwd().openDir("./", .{.iterate = true});
    defer dir.close();

    var it = try dir.walk(b.allocator);
    while (try it.next() ) |entry| {
      if (entry.kind != .file) continue;
      if (!std.mem.endsWith(u8, entry.path, "_test.zig")) continue;

      try argv.append(entry.path);
      test_step.dependOn(&b.addSystemCommand(argv.items).step);
      _ = argv.pop();
    }
  }
}
