const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");

const ComponentTimelineEvent = @import("../components/timelineevent.zig");

pub const Event = struct {
  timeline: []const u8 = "",

  start: ?f32 = null,
  end: ?f32 = null,
  duration: f32 = 1.0, // Default duration if only start is provided

  repeat: u32 = 1,
  pattern: ComponentTimelineEvent.Pattern = .Forward,
  motion: ComponentTimelineEvent.Motion = .Linear,
};

pub fn add(entity: ent.Entity, params: Event) ent.Entity {
  if (params.start == undefined and params.end == undefined)
    if (entity.parent_id == 0) // No previous event
      @panic("Event start or end needs to be provided or a previous event should exist");

  if (params.repeat < 1)
    @panic("Event repeat should be at least 1");

  var timeline: ent.Entity = undefined;
  if (params.timeline.len == 0) {
    timeline = entity.world.entity("timeline"); // Use default timeline
  } else {
    timeline = entity.world.entity(params.timeline); // May not exists yet
  }

  var event = entity;
  event.id = entity.world.entityNext();
  if (entity.parent_id == 0) // Set original entry id as parent for event entries only the first time (subsequent will receive it from this event entry)
    event.parent_id = entity.id;

  var realStart: f32 = undefined;
  var realEnd: f32 = undefined;
  if (params.start) |start| {
    realStart = start;

    if (params.end) |end| {
      realEnd = end;
    } else {
      realEnd = start + params.duration;
    }
  } else if (params.end) |end| {
    realEnd = end;

    if (params.start) |start| {
      realStart = start;
    } else {
      realStart = end - params.duration;
    }
  } else if (entity.world.components.timelineevent.get(entity.id)) |previousEvent| { // Get end from previous event
    realStart = previousEvent.end;
    realEnd = previousEvent.end + params.duration;
  }

  if (realEnd < realStart) { // Ensure start is always before end, timeline system requires this
    const tmp = realStart;
    realEnd = realStart;
    realStart = tmp;
  }

  if (realStart < 0.0)
    @panic("Negative time not yet implemented");

  const new = ComponentTimelineEvent.Component{
    .timeline_id = timeline.id,
    .target_id = event.parent_id,

    .start = realStart,
    .end = realEnd,

    .repeat = params.repeat,
    .pattern = params.pattern,
    .motion = params.motion,
  };

  entity.world.components.timelineevent.put(event.id, new) catch @panic("Failed to store timeline event");
  return event;
}


// Testing
const tst = std.testing;

test "Component should add timeline event" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const timeline = world.entity("timeline");
  const entity = world.entity("test");

  // When
  const result = add(entity, Event{
    .start = 1.0,
    .end = 2.0,
    .duration = 1.0,
    .repeat = 1,
    .pattern = ComponentTimelineEvent.Pattern.Forward,
    .motion = ComponentTimelineEvent.Motion.Linear,
  });

  // Then
  try tst.expectEqual(entity.id, result.parent_id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.timelineevent.get(result.id)) |timelineevent|
    try tst.expectEqual(timelineevent, ComponentTimelineEvent.Component{
      .timeline_id = timeline.id,
      .target_id = entity.id,
      .start = 1.0,
      .end = 2.0,
      .repeat = 1,
      .pattern = ComponentTimelineEvent.Pattern.Forward,
      .motion = ComponentTimelineEvent.Motion.Linear,
    })
  else
    return error.TestExpectedTimelineEvent;
}
