const std = @import("std");
const scn = @import("scene.zig");

pub const Timeline = struct {
  allocator: std.mem.Allocator,
  scenes: std.ArrayList(*scn.Scene),

  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timestampPreviousMS: i64 = 0,

  pub fn init(allocator: std.mem.Allocator) Timeline {
    return Timeline {
      .allocator = allocator,
      .scenes = std.ArrayList(*scn.Scene).init(allocator),
    };
  }

  pub fn deinit(self: *Timeline) void {
    self.scenes.deinit();
  }

  pub fn addScene(self: *Timeline, scene: *scn.Scene) void {
    self.scenes.append(scene) catch unreachable;
  }

  pub fn activeScene(self: *Timeline) ?*scn.Scene {
    var sceneEnd: f32 = 0;
    for (self.scenes.items) |scene| {
      sceneEnd += scene.timeline.duration;
      if (self.timeCurrent < sceneEnd)
        return scene;
    }

    return null;
  }

  pub fn setSpeed(self: *Timeline, set: f32) void {
    self.speed = set;
  }

  pub fn determineFrame(self: *Timeline) void {
    if (self.timestampPreviousMS == 0 ) // first time
    {
      self.timeCurrent = 0;
      self.timePrevious = 0;
      self.timestampPreviousMS = std.time.milliTimestamp(); //store for next determine

      std.debug.print("time: {d:1.2}, speed: {d:1.2}\n", .{self.timeCurrent, self.speed});
      return;
    }

    const timestampCurrentMS = std.time.milliTimestamp();
    const timestampDelta = @as(f32, @floatFromInt(timestampCurrentMS - self.timestampPreviousMS)) / 1000.0;

    self.timePrevious = self.timeCurrent;
    self.timeCurrent += timestampDelta * self.speed;
    self.timestampPreviousMS = timestampCurrentMS;

    std.debug.print("time: {d:1.2}, speed: {d:1.2}\n", .{self.timeCurrent, self.speed});
  }
};
