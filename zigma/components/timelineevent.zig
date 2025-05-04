const ecs = @import("../ecs.zig");

pub const Data = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  duration: f32,
};

pub fn add(entity: *const ecs.Entity, timelineName: []const u8, start: f32, duration: f32) *const ecs.Entity {
  const timeline = entity.world.entity(timelineName); // May not exists yet
  const event = entity.world.entity(""); // Unnamed entity

  if (entity.parent_id != 0) { // Previous event called on entity
    event.parent_id = entity.parent_id;
  } else { // First event on entity
    event.parent_id = entity.id;
  }

  if (entity.world.components.timelineevent.get(entity.id)) |timelineEvent| {
    timelineEvent.* = .{
      .timeline_id = timeline.id,
      .target_id = event.parent_id,
      .start = start,
      .duration = duration,
    };
    return entity;
  }

  const timelineEvent = entity.world.allocator.create(Data) catch @panic("Failed to create timeline event");
  timelineEvent.* = Data{
    .timeline_id = timeline.id,
    .target_id = event.parent_id,
    .start = start,
    .duration = duration,
  };

  entity.world.components.timelineevent.put(entity.id, timelineEvent) catch @panic("Failed to store timeline event");
  return event;
}
