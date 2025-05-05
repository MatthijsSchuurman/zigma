const ecs = @import("../ecs.zig");

pub const Data = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  duration: f32,
};

pub fn add(entity: ecs.Entity, timelineName: []const u8, start: f32, duration: f32) ecs.Entity {
  const timeline = entity.world.entity(timelineName); // May not exists yet

  var event = entity;
  event.id = entity.world.entityNext();
  event.parent_id = entity.id;

  const timelineEvent = Data{
    .timeline_id = timeline.id,
    .target_id = entity.id,
    .start = start,
    .duration = duration,
  };

  entity.world.components.timelineevent.put(event.id, timelineEvent) catch @panic("Failed to store timeline event");
  return event;
}
