const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  if (entity.world.components.position.get(entity.id)) |position| {
    position.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const position = entity.world.allocator.create(Data) catch @panic("Failed to create position");
  position.* = .{.x = x, .y = y, .z = z };

  entity.world.components.position.put(entity.id, position) catch @panic("Failed to store position");
  return entity;
}
