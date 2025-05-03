const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: *const ecs.Entity, text: Data) *const ecs.Entity {
  entity.world.components.Text.put(
    entity.id,
    text,
  ) catch @panic("Text set failed");

  return entity;
}
