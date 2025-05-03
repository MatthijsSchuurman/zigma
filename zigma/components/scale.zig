const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: *const ecs.Entity, x: f32, y: f32, z: f32) *const ecs.Entity {
  var data: *Data = undefined;
  const entry = entity.world.components.scale.getOrPut(entity.id) catch @panic("Unable to put scale");
  if (!entry.found_existing) {
    data = entity.world.allocator.create(Data) catch @panic("Failed to create scale");
  } else {
    data = entry.value_ptr.*;
  }

  data.* = Data{.x = x, .y = y, .z = z };
  entry.value_ptr.* = data;

  return entity;
}
