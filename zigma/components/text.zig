const ecs = @import("../ecs.zig");

pub const Data = []const u8;

pub fn set(entity: *const ecs.Entity, text: Data) *const ecs.Entity {
  var data: *Data = undefined;
  const entry = entity.world.components.text.getOrPut(entity.id) catch @panic("Unable to put text");
  if (!entry.found_existing) {
    data = entity.world.allocator.create(Data) catch @panic("Failed to create text");
  } else {
    data = entry.value_ptr.*;
  }

  data.* = text;
  entry.value_ptr.* = data;

  return entity;
}
