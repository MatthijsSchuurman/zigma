const ecs = @import("../ecs.zig");

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  entity.world.positions.put(
    entity.id,
    Position{.x = x, .y = y, .z = z })
      catch @panic("Unable to create component position");

  return entity;
}
pub const Position = struct {
  x: f32,
  y: f32,
  z: f32,
};
