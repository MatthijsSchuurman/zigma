const ecs = @import("../ecs.zig");

pub fn set(entity: *const ecs.Entity, r: u8, g: u8, b: u8, a: u8) *const ecs.Entity {
  entity.world.colors.put(
    entity.id,
    Type{.r = r, .g = g, .b = b, .a = a }
    )
      catch @panic("Unable to create component color");

  return entity;
}

pub const Type = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};
