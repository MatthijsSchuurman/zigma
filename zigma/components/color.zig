const ecs = @import("../ecs.zig");

pub const Data = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub fn set(entity: *const ecs.Entity, r: u8, g: u8, b: u8, a: u8) *const ecs.Entity {
  entity.world.components.color.put(
    entity.id,
    Data{.r = r, .g = g, .b = b, .a = a }
  ) catch @panic("Failed to set color");

  return entity;
}
