const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  entity.world.components.Rotation.put(
    entity.id,
    Data{.x = x, .y = y, .z = z }
  ) catch @panic("Rotation set failed");

  return entity;
}
