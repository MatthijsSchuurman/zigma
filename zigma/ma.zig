const std = @import("std");
const tst = @import("std").tst;
const rl = @cImport(@cInclude("raylib.h"));

// Setup memory management
const builtin = @import("builtin");
const use_gpa = builtin.mode == .Debug;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const allocator = if (use_gpa) gpa.allocator() else arena.allocator();

// Timeline
//const Timeline = @import("timeline.zig").Timeline;
//var timeline = Timeline.init(allocator);

// ECS
pub const ecs = @import("ecs.zig");

// Init, Deinit & Render
const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,
};

pub fn init(config: Config) ecs.World {
  rl.InitWindow(config.width, config.height, config.title);
  rl.SetTargetFPS(200);

  return ecs.World.init(allocator);
}

pub fn deinit() void {
  rl.CloseWindow();

  //timeline.deinit();

  if (use_gpa) _ = gpa.deinit() else arena.deinit();
}

pub fn render() bool {
  if (rl.WindowShouldClose()) {
    return false;
  }

  // if (rl.IsKeyPressed(rl.KEY_KP_ADD) or rl.IsKeyPressed(rl.KEY_EQUAL)) {
  //   timeline.setSpeed(timeline.speed + 0.1);
  // } else if (rl.IsKeyPressed(rl.KEY_KP_SUBTRACT) or rl.IsKeyPressed(rl.KEY_MINUS)) {
  //   timeline.setSpeed(timeline.speed - 0.1);
  // }
  //
  // timeline.determineFrame();

  rl.BeginDrawing();

  rl.EndDrawing();
  return true;
}

// Testing
test "tst something" {
  try tst.expectEqual(0.0, 0.0);
}
