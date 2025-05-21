const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

const LIGHT_DIRECTIONAL = 0; // Redefined from lighting.fs
const LIGHT_POINT = 1; // Redefined from lighting.fs

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
      .Point       => LIGHT_POINT,
      .Directional => LIGHT_DIRECTIONAL,
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
