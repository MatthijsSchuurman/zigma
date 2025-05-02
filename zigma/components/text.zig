const ecs = @import("../ecs.zig");

pub fn set(entity: *const ecs.Entity, text: Type) *const ecs.Entity {
  entity.world.texts.put(
    entity.id,
    text
  ) catch @panic("Unable to create component text");

  return entity;
}

pub const Type = []const u8;
