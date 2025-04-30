const std = @import("std");
const scene = @import("scene.zig");

pub const Timeline = struct {
  allocator: std.mem.Allocator,
  scenes: std.ArrayList(*scene.Scene),

  pub fn init(allocator: std.mem.Allocator) Timeline {
    return Timeline {
      .allocator = allocator,
      .scenes = std.ArrayList(*scene.Scene).init(allocator),
    };
  }

  pub fn deinit(self: *Timeline) void {
    self.scenes.deinit();
  }

  pub fn add(self: *Timeline, scenePtr: *scene.Scene) void {
    self.scenes.append(scenePtr) catch unreachable;
  }

  pub fn active(self: *Timeline) ?*scene.Scene {
    if (self.scenes.items.len == 0)
      return null;

    return self.scenes.items[0]; //hardcoded for now, will be based on duration of individual scenes
  }
};
