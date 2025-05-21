const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  active: bool,
  fovy: f32,

  target: rl.Vector3,
};

const Camera = struct {
  fovy: f32 = 45.0,

  target: struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
  } = .{},
};


// Testing
const tst = std.testing;
