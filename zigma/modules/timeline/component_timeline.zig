const std = @import("std");
const ecs = @import("../../ecs.zig");

pub const Component = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timeOffset: f32 = 0,
  timeDelta: f32 = 0,
  timestampPreviousMS: i64 = 0,
};


// Testing
const tst = std.testing;
