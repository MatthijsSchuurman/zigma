const std = @import("std");
const testing = @import("std").testing;
const raylib = @cImport(@cInclude("raylib.h"));


pub const Object = @import("objects/base.zig").Object;
pub const Objects = struct {
  pub const Text = @import("objects/text.zig");
};

pub const Effects = struct {
  pub const Background = @import("effects/background.zig");
};


var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();


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


const timeline = @import("lib/timeline.zig");


pub const Config = struct {
  title: [*:0]const u8,
  width: i32,
  height: i32,
};

const RenderCallback = fn () void;

pub fn init(config: Config) void {
  raylib.InitWindow(config.width, config.height, config.title);
  raylib.SetTargetFPS(200);
}

pub fn deinit() void {
  raylib.CloseWindow();

  var it = scenes_map.iterator();
  while(it.next()) |entry| {
    entry.value_ptr.deinit();
  }

  scenes_map.deinit();

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
