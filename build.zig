const std = @import("std");

pub fn build(b: *std.Build) !void {
  const target = b.standardTargetOptions(.{});
  const optimize = b.standardOptimizeOption(.{});

  const demo_name = b.option([]const u8, "demo", "Which demo to build (e.g. text, pulse, wave)");
  const test_filter = b.option([]const u8, "filter", "Filter which tests to run");

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
  var test_cmd = std.ArrayList(u8).init(b.allocator);
  defer test_cmd.deinit();

  try test_cmd.appendSlice("set -o pipefail; ");
  try test_cmd.appendSlice("zig test -lm -lraylib zigma/ma.zig ");
  if (test_filter) |filter| {
    try test_cmd.appendSlice("--test-filter ");
    if (std.mem.startsWith(u8, filter, "zigma."))
      try test_cmd.appendSlice(filter["zigma.".len..])
    else
      try test_cmd.appendSlice(filter);

    try test_cmd.appendSlice(" ");
  }

  try test_cmd.appendSlice("2>&1 | cat");

  const test_cmd_string = try test_cmd.toOwnedSlice();
  const run_tests = b.addSystemCommand(&.{"sh", "-c", test_cmd_string});
  b.step("test", "Run unit tests").dependOn(&run_tests.step);
}
