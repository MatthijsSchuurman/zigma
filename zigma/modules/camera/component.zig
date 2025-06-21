const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  active: bool,
  fovy: f32,

  target: rl.Vector3,
};


// Testing
const tst = std.testing;
