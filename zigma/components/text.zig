const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: *const ecs.Entity, newText: Data) *const ecs.Entity {
  if (entity.world.components.text.get(entity.id)) |text| {
    text.* = newText;
    return entity;
  }

  const text = entity.world.allocator.create(Data) catch @panic("Failed to create text");
  text.* = newText;

  entity.world.components.text.put(entity.id, text) catch @panic("Failed to store text");
  return entity;
}
