const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Data = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timestampPreviousMS: i64 = 0,
};

pub fn init(entity: ecs.Entity) ecs.Entity {
  if (entity.world.components.timeline.get(entity.id)) |_|
    return entity;

  const timeline = entity.world.allocator.create(Data) catch @panic("Failed to create timeline");
  timeline.* = .{};

  entity.world.components.timeline.put(entity.id, timeline) catch @panic("Failed to store timeline");
  return entity;
}

pub fn setSpeed(entity: ecs.Entity, speed: f32) ecs.Entity {
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    timeline.speed = speed;
    std.debug.print("Timeline {d} speed: {d:1.2}\n", .{entity.id, timeline.speed});
  }

  return entity;
}
