const std = @import("std");
const testing = @import("std").testing;
const raylib = @cImport(@cInclude("raylib.h"));

//const scenes = @import("lib/scenes.zig");
const timeline = @import("lib/timeline.zig");

pub const Object = @import("objects/base.zig").Object;
pub const Objects = struct {
  pub const Text = @import("objects/text.zig");
};

pub const Effects = struct {
  pub const Background = @import("effects/background.zig");
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();

pub const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,
};

const RenderCallback = fn () void;

pub fn init(config: Config) void {
  std.debug.print("Hello, {s}! The value is {d}\n", .{config.title, config.width});

  raylib.InitWindow(config.width, config.height, config.title);
  raylib.SetTargetFPS(200);
}

pub fn deinit() void {
  raylib.CloseWindow();
  _ = gpa.deinit();
}

pub fn render(callback: RenderCallback) bool {
  if(raylib.WindowShouldClose()) {
    return false;
  }

  if(raylib.IsKeyDown(raylib.KEY_LEFT_ALT) and raylib.IsKeyPressed(raylib.KEY_ENTER)) {
    raylib.ToggleFullscreen();
  }

  raylib.BeginDrawing();
  callback();
  raylib.EndDrawing();

  return true;
}


test "testing something" {
  try testing.expectEqual(0.0, 0.0);
}
