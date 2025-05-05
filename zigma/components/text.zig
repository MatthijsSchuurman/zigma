const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: ecs.Entity, text: Data) ecs.Entity {
  if (entity.world.components.text.getPtr(entity.id)) |existingText| {
    existingText.* = text;
    return entity;
  }

  entity.world.components.text.put(entity.id, text) catch @panic("Failed to store text");
  return entity;
}
