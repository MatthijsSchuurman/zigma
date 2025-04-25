const raylib = @cImport(@cInclude("raylib.h"));
const testing = @import("std").testing;
const std = @import("std");


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

pub fn close() void {
  raylib.CloseWindow();
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
