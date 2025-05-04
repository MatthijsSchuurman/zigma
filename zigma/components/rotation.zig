const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  if (entity.world.components.rotation.get(entity.id)) |rotation| {
    rotation.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const rotation = entity.world.allocator.create(Data) catch @panic("Failed to create rotation");
  rotation.* = .{.x = x, .y = y, .z = z };

  entity.world.components.rotation.put(entity.id, rotation) catch @panic("Failed to store rotation");
  return entity;
}
