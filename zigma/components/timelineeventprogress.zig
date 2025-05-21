const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  progress: f32 = 0,
  target_id: ?ecs.EntityID,
};


// Testing
const tst = std.testing;
