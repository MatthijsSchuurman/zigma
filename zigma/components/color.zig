const ecs = @import("../ecs.zig");

pub const Data = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub fn set(entity: ecs.Entity, r: u8, g: u8, b: u8, a: u8) ecs.Entity {
  if (entity.world.components.color.get(entity.id)) |color| {
    color.* = .{.r = r, .g = g, .b = b, .a = a };
    return entity;
  }

  const color = entity.world.allocator.create(Data) catch @panic("Failed to create color");
  color.* = .{.r = r, .g = g, .b = b, .a = a };

  entity.world.components.color.put(entity.id, color) catch @panic("Failed to store color");
  return entity;
}
