const ecs = @import("../ecs.zig");

pub const Data = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub fn set(entity: *const ecs.Entity, r: u8, g: u8, b: u8, a: u8) *const ecs.Entity {
  var data: *Data = undefined;
  const entry = entity.world.components.color.getOrPut(entity.id) catch @panic("Unable to put color");
  if (!entry.found_existing) {
    data = entity.world.allocator.create(Data) catch @panic("Failed to create color");
  } else {
    data = entry.value_ptr.*;
  }

  data.* = Data{.r = r, .g = g, .b = b, .a = a };
  entry.value_ptr.* = data;

  return entity;
}
