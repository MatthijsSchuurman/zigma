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
  rl.SetTargetFPS(200);

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

  if (rl.IsKeyPressed(rl.KEY_F)) {
    const monitor_index = 1; // second screen
    const width = rl.GetMonitorWidth(monitor_index);
    const height = rl.GetMonitorHeight(monitor_index);
    const xpos = rl.GetMonitorPosition(monitor_index).x;
    const ypos = rl.GetMonitorPosition(monitor_index).y;

    rl.SetWindowSize(width, height);
    rl.SetWindowPosition(@intFromFloat(xpos), @intFromFloat(ypos));
  }

  if (rl.IsKeyPressed(rl.KEY_KP_ADD) or rl.IsKeyPressed(rl.KEY_EQUAL)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current| {
      if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT))
        _ = timeline.timeline_speed(current.speed + 1.0)
      else
        _ = timeline.timeline_speed(current.speed + 0.1);
    }
  } else if (rl.IsKeyPressed(rl.KEY_KP_SUBTRACT) or rl.IsKeyPressed(rl.KEY_MINUS)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current| {
      if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT))
        _ = timeline.timeline_speed(current.speed - 1.0)
      else
        _ = timeline.timeline_speed(current.speed - 0.1);
    }
  }

  if (rl.IsKeyPressed(rl.KEY_RIGHT)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current| {
      if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT))
        _ = timeline.timeline_offset(current.speed * 5)
      else
        _ = timeline.timeline_offset(current.speed * 2);
    }
  } else if (rl.IsKeyPressed(rl.KEY_LEFT)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |current| {
      if (rl.IsKeyDown(rl.KEY_LEFT_SHIFT) or rl.IsKeyDown(rl.KEY_RIGHT_SHIFT))
        _ = timeline.timeline_offset(-current.speed * 5)
      else
        _ = timeline.timeline_offset(-current.speed * 2);
    }
  }

  rl.BeginDrawing();
  const success = world.render();
  rl.EndDrawing();

  return success;
}
