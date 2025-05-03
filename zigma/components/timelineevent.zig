const std= @import("std");
const ecs = @import("../ecs.zig");

pub const Data = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  duration: f32,
};

pub fn add(entity: *const ecs.Entity, timelineName: []const u8, start: f32, duration: f32) *const ecs.Entity {
  const timeline = entity.world.entity(timelineName); // May not exists yet
  const event = entity.world.entity(""); // May not exists yet

  if (entity.parent_id != 0) { // Previous event called on entity
    event.parent_id = entity.parent_id;
  } else { // First event on entity
    event.parent_id = entity.id;
  }

  entity.world.components.timelineevent.put(
    event.id,
    Data{
      .timeline_id = timeline.id,
      .target_id = event.parent_id,
      .start = start,
      .duration = duration,
    },
  ) catch @panic("Failed to add event to timeline");

  return event;
}
