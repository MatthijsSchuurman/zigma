const std = @import("std");
const scn = @import("scene.zig");

pub const Timeline = struct {
  allocator: std.mem.Allocator,
  scenes: std.ArrayList(*scn.Scene),

  pub fn init(allocator: std.mem.Allocator) Timeline {
    return Timeline {
      .allocator = allocator,
      .scenes = std.ArrayList(*scn.Scene).init(allocator),
    };
  }

  pub fn deinit(self: *Timeline) void {
    self.scenes.deinit();
  }

  pub fn add(self: *Timeline, scene: *scn.Scene) void {
    self.scenes.append(scene) catch unreachable;
  }

  pub fn active(self: *Timeline) ?*scn.Scene {
    if (self.scenes.items.len == 0)
      return null;

    return self.scenes.items[0]; //hardcoded for now, will be based on duration of individual scenes
  }
};
