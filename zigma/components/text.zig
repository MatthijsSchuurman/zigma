const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: *const ecs.Entity, text: Data) *const ecs.Entity {
  entity.world.components.text.put(
    entity.id,
    text,
  ) catch @panic("Failed to set text");

  return entity;
}
