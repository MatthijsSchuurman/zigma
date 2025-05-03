const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  const data = entity.world.allocator.create(Data) catch @panic("Failed to create scale");
  data.* = Data{.x = x, .y = y, .z = z };

  entity.world.components.scale.put(
    entity.id,
    data,
  ) catch @panic("Failed to set scale");

  return entity;
}
