const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  active: bool,
  type: LightType = .Point,

  target: rl.Vector3,
};

pub const LightType = enum(u8) {
  Point,
  Directional,

  pub fn raylibType(self: LightType) i32 {
    return switch (self) {
      .Point       => rl.LIGHT_POINT,
      .Directional => rl.LIGHT_DIRECTIONAL,
    };
  }
};

const Light = struct {
  active: bool = true,
  type: LightType = .Point,

  target: struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
  } = .{},
};


// Testing
const tst = std.testing;
