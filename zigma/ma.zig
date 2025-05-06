const std = @import("std");
const tst = @import("std").tst;
const rl = @cImport(@cInclude("raylib.h"));

// Setup memory management
const builtin = @import("builtin");
const use_gpa = builtin.mode == .Debug;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const allocator = if (use_gpa) gpa.allocator() else arena.allocator();

// ECS
pub const ecs = @import("ecs.zig");

// Init & Deinit
const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,
};

pub fn init(config: Config) *ecs.World {
  rl.InitWindow(config.width, config.height, config.title);
  rl.SetTargetFPS(20);

  const world = allocator.create(ecs.World) catch @panic("Unable to create world");
  world.* = ecs.World.init(allocator);
  world.initSystems();

  _ = world.entity("timeline").timeline_init();

  return world;
}

pub fn deinit(world: *ecs.World) void {
  world.deinit();
  allocator.destroy(world);

  rl.CloseWindow();

  if (use_gpa) _ = gpa.deinit() else arena.deinit();
}

// Render
pub fn render(world: *ecs.World) bool {
  if (rl.WindowShouldClose())
    return false;

  if (rl.IsKeyPressed(rl.KEY_KP_ADD) or rl.IsKeyPressed(rl.KEY_EQUAL)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current|
      _ = timeline.timeline_speed(current.speed + 0.1);
  } else if (rl.IsKeyPressed(rl.KEY_KP_SUBTRACT) or rl.IsKeyPressed(rl.KEY_MINUS)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current|
      _ = timeline.timeline_speed(current.speed - 0.1);
  }

  rl.BeginDrawing();
  rl.ClearBackground(.{.r = 0, .g = 0, .b = 23, .a = 50});

  const success = world.render();

  rl.EndDrawing();

  return success;
}

// Testing
test "tst something" {
  try tst.expectEqual(0.0, 0.0);
}
