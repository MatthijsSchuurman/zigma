const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timeOffset: f32 = 0,
  timeDelta: f32 = 0,
  timestampPreviousMS: i64 = 0,
};

pub fn init(entity: ecs.Entity) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |_|
    return entity;

  const new = .{};

  entity.world.components.timeline.put(entity.id, new) catch @panic("Failed to store timeline");
  return entity;
}

pub fn setSpeed(entity: ecs.Entity, speed: f32) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |timeline|
    timeline.speed = speed;

  return entity;
}

pub fn setOffset(entity: ecs.Entity, offset: f32) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |timeline|
    timeline.timeOffset= offset;

  return entity;
}
