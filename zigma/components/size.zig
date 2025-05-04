const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  if (entity.world.components.size.get(entity.id)) |size| {
    size.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const size = entity.world.allocator.create(Data) catch @panic("Failed to create size");
  size.* = .{.x = x, .y = y, .z = z };

  entity.world.components.size.put(entity.id, size) catch @panic("Failed to store size");
  return entity;
}
