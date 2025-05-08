const std = @import("std");

pub fn build(b: *std.Build) void {
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
    .root_source_file = .{ .cwd_relative = std.fmt.allocPrint(b.allocator, "{s}/main.zig", .{demo_name orelse "default"}) catch unreachable },
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
  if (test_file) |path| {
    var argv = std.ArrayList([]const u8).init(b.allocator);
    argv.append("zig") catch unreachable;
    argv.append("test") catch unreachable;
    argv.append(path) catch unreachable;
    //argv.append("-femit-llvm-ir") catch unreachable;

    inline for (system_libs) |lib| {
      argv.append("-l" ++ lib) catch unreachable;
    }

    const run_tests = b.addSystemCommand(argv.items);
    b.step("test", "Run unit tests").dependOn(&run_tests.step);
  }
}
