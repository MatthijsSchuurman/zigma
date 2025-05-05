const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.position.getPtr(entity.id)) |position| {
    position.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const position = .{.x = x, .y = y, .z = z };

  entity.world.components.position.put(entity.id, position) catch @panic("Failed to store position");
  return entity;
}
