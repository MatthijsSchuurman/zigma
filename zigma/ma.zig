const std = @import("std");
const tst = @import("std").tst;
const rl = @cImport(@cInclude("raylib.h"));


pub const Objects = struct {
  pub const Text = @import("objects/text.zig");
};

pub const Effects = struct {
  pub const Background = @import("effects/background.zig");
};


const builtin = @import("builtin");
const use_gpa = builtin.mode == .Debug;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
pub const allocator = if (use_gpa) gpa.allocator() else arena.allocator();


const Scene = @import("lib/scene.zig").Scene;
var scenes_map = std.StringHashMap(Scene).init(allocator);

pub fn scene(name: []const u8) *Scene {
  if (scenes_map.getPtr(name)) |existing_scene| {
    return existing_scene;
  }

  const new_scene = Scene.init(allocator);
  scenes_map.put(name, new_scene) catch @panic("Failed to store scene");
  return scenes_map.getPtr(name).?;
}


const Timeline = @import("lib/timeline.zig").Timeline;
pub var timeline = Timeline.init(allocator);


pub const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,
};

const RenderCallback = fn () void;

pub fn init(config: Config) void {
  rl.InitWindow(config.width, config.height, config.title);
  rl.SetTargetFPS(200);
}

pub fn deinit() void {
  rl.CloseWindow();

  var it = scenes_map.iterator();
  while (it.next()) |entry| {
    entry.value_ptr.deinit();
  }

  scenes_map.deinit();
  timeline.deinit();

  if (use_gpa) _ = gpa.deinit() else arena.deinit();
}

pub fn render(callback: RenderCallback) bool {
  if (rl.WindowShouldClose()) {
    return false;
  }

  if (rl.IsKeyPressed(rl.KEY_KP_ADD) or rl.IsKeyPressed(rl.KEY_EQUAL)) {
    timeline.setSpeed(timeline.speed + 0.1);
  } else if (rl.IsKeyPressed(rl.KEY_KP_SUBTRACT) or rl.IsKeyPressed(rl.KEY_MINUS)) {
    timeline.setSpeed(timeline.speed - 0.1);
  }


  timeline.determineFrame();
  const activeScene = timeline.activeScene() orelse return false;

  rl.BeginDrawing();
  activeScene.render();
  callback();
  rl.EndDrawing();

  return true;
}


test "tst something" {
  try tst.expectEqual(0.0, 0.0);
}
