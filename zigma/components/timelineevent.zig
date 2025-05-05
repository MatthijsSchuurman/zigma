const ecs = @import("../ecs.zig");

pub const Data = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  end: f32,
};

pub fn add(entity: ecs.Entity, timelineName: []const u8, start: f32, duration: f32) ecs.Entity {
  const timeline = entity.world.entity(timelineName); // May not exists yet

  var event = entity;
  event.id = entity.world.entityNext();
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
    .target_id = entity.id,
    .start = realStart,
    .end = realEnd,
  };

  entity.world.components.timelineevent.put(event.id, timelineEvent) catch @panic("Failed to store timeline event");
  return event;
}
