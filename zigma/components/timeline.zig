const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Data = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timestampPreviousMS: i64 = 0,
};

pub fn init(entity: *const ecs.Entity) *const ecs.Entity {
  const data = entity.world.allocator.create(Data) catch @panic("Failed to create timeline");
  data.* = Data{};

  entity.world.components.timeline.put(
    entity.id,
    data,
  ) catch @panic("Failed to init timeline");

  return entity;
}

pub fn setSpeed(entity: *const ecs.Entity, speed: f32) *const ecs.Entity {
  std.debug.print("setSpeed {d} speed: {d:1.2}\n", .{entity.id, speed});
  if (entity.world.components.timeline.get(entity.id)) |alala|
  std.debug.print("ALALA {d} speed: {d:1.2}\n", .{alala.speed, alala.timestampPreviousMS});

  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    timeline.speed = speed;
    std.debug.print("Timeline {d} speed: {d:1.2}\n", .{entity.id, timeline.speed});
  }

  return entity;
}
