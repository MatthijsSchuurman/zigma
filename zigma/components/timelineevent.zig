const ecs = @import("../ecs.zig");
const std = @import("std");

pub const Data = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  end: f32,

  pub const Filter = struct {
    timeline_id: ?ecs.EntityID = null,
    target_id: ?ecs.EntityID = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    return
      (f.timeline_id == null or self.timeline_id == f.timeline_id) and
      (f.target_id == null or self.target_id == f.target_id);
  }
};

pub fn query(world: *ecs.World, filter: Data.Filter) []ecs.EntityID {
  return world.query(Data, &world.components.timelineevent, filter, Data.filter);
}

pub fn add(entity: ecs.Entity, timelineName: []const u8, start: f32, duration: f32) ecs.Entity {
  const timeline = entity.world.entity(timelineName); // May not exists yet

  var event = entity;
  event.id = entity.world.entityNext();
  if (entity.parent_id == 0) // Set original entry id as parent for event entries only the first time (subsequent will receive it from this event entry)
    event.parent_id = entity.id;

  var realStart: f32 = undefined;
  var realEnd: f32 = undefined;
  if (duration >= 0.0) { // Going forward in time
    realStart = start;
    realEnd = start + duration;
  } else { // Ensure start is always before end, timeline system requires this
    realStart = start + duration;
    realEnd = start;
  }

  if (realStart < 0.0) @panic("Negative time not yet implemented");

  const timelineEvent = Data{
    .timeline_id = timeline.id,
    .target_id = event.parent_id,
    .start = realStart,
    .end = realEnd,
  };

  entity.world.components.timelineevent.put(event.id, timelineEvent) catch @panic("Failed to store timeline event");
  return event;
}
