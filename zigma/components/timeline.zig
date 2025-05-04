const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Data = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timestampPreviousMS: i64 = 0,
};

pub fn init(entity: *const ecs.Entity) *const ecs.Entity {
  var data: *Data = undefined;
  const entry = entity.world.components.timeline.getOrPut(entity.id) catch @panic("Unable to put timeline");
  if (!entry.found_existing) {
    data = entity.world.allocator.create(Data) catch @panic("Failed to create timeline");
  } else {
    data = entry.value_ptr.*;
  }

  data.* = Data{};
  entry.value_ptr.* = data;

  return entity;
}

pub fn setSpeed(entity: *const ecs.Entity, speed: f32) *const ecs.Entity {
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    timeline.speed = speed;
    std.debug.print("Timeline {d} speed: {d:1.2}\n", .{entity.id, timeline.speed});
  }

  return entity;
}
