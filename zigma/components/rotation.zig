const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.rotation.getPtr(entity.id)) |rotation| {
    rotation.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const rotation = .{.x = x, .y = y, .z = z };

  entity.world.components.rotation.put(entity.id, rotation) catch @panic("Failed to store rotation");
  return entity;
}
