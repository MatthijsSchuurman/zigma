const std = @import("std");

// Setup memory management
const builtin = @import("builtin");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const allocator =
  if (builtin.is_test)
    std.testing.allocator
  else if (builtin.mode == .Debug)
    gpa.allocator()
  else
    arena.allocator();

// ECS
pub const ecs = @import("ecs.zig");
const rl = ecs.raylib;

// Init & Deinit
const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,

  fps: i32 = 200,
  msaa: bool = true,
};

pub fn init(config: Config) void {
  rl.InitWindow(config.width, config.height, config.title);
  rl.InitAudioDevice();

  if (config.fps > 0)
    rl.SetTargetFPS(config.fps);
  if (config.msaa)
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
}

pub fn create() *ecs.World {
  const world = allocator.create(ecs.World) catch @panic("Unable to create world");
  world.* = ecs.World.init(allocator);
  world.initSystems();

  _ = world.entity("timeline").timeline();

  return world;
}

pub fn destroy(world: *ecs.World) void {
  world.deinit();
  allocator.destroy(world);
}

pub fn deinit() void {
  rl.CloseAudioDevice();
  rl.CloseWindow();

  if (!builtin.is_test) {// Test allocator teardown done by test framework
    if (builtin.mode == .Debug)
      _ = gpa.deinit()
    else
      arena.deinit();
  }
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

  if (rl.IsKeyPressed(rl.KEY_SPACE)) {
    var timeline = world.entity("timeline");
    if (world.components.timeline.get(timeline.id)) |_|
      _ = timeline.timeline_speed(0.0);
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


// Testing
const tst = std.testing;

test { // Before
  rl.SetTraceLogLevel(rl.LOG_NONE);
  rl.SetWindowState(rl.FLAG_WINDOW_HIDDEN);

  init(.{.title = "test", .width = 320, .height = 200, .fps = 10}); //open raylib window once otherwise segfaulty
  //defer deinit(); // Can't do post test cleanup

  std.testing.refAllDecls(@This()); // Export tests in imported files
}

test "Zigma should create world" {
  // Given

  // When
  const world = create();
  defer destroy(world);

  // Then
  try tst.expectEqual(true, rl.IsWindowReady());
}

test "Zigma should render world" {
  // Given
  const world = create();
  defer destroy(world);

  _ = world.entity("camera").camera(.{});
  _ = world.entity("shader").shader(.{});
  _ = world.entity("light").light(.{.type = .Directional});
  _ = world.entity("material").material(.{.shader = "shader"});
  _ = world.entity("ball").model(.{.type = "sphere", .material = "material"});
  _ = world.entity("background").color(0, 0, 0, 255); // Wipe previous test data
  _ = world.entity("fps").fps();

  // When
  const result = render(world);

  // Then
  try tst.expectEqual(true, result);
  try ecs.expectScreenshot("world.render");
}
