const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");

pub const Component = struct {
  progress: f32 = 0,
  target_id: ?ent.EntityID,
};


// Testing
const tst = std.testing;
