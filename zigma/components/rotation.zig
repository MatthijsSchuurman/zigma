const ecs = @import("../ecs.zig");

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  entity.world.rotations.put(
    entity.id,
    Type{.x = x, .y = y, .z = z }
    )
      catch @panic("Unable to create component rotation");

  return entity;
}

pub const Type = struct {
  x: f32,
  y: f32,
  z: f32,
};
