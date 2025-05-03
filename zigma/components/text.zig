const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: *const ecs.Entity, text: Data) *const ecs.Entity {
  const data = entity.world.allocator.create(Data) catch @panic("Failed to create text");
  data.* = text;

  entity.world.components.text.put(
    entity.id,
    data,
  ) catch @panic("Failed to set text");

  return entity;
}
