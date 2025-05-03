const ecs = @import("../ecs.zig");

pub const Data = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub fn set(entity: *const ecs.Entity, r: u8, g: u8, b: u8, a: u8) *const ecs.Entity {
  const data = entity.world.allocator.create(Data) catch @panic("Failed to create color");
  data.* = Data{.r = r, .g = g, .b = b, .a = a };

  entity.world.components.color.put(
    entity.id,
    data,
  ) catch @panic("Failed to set color");

  return entity;
}
