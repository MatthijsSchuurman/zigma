const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  end: f32,

  repeat: u32 = 1,
  pattern: Pattern = .Forward,
  motion: Motion = .Linear,
};

const Pattern = enum {
  Forward,
  Reverse,
  PingPong,
  PongPing,
  Random,
};

const Motion = enum {
  Instant,
  Linear,
  EaseIn,
  EaseOut,
  EaseInOut,
  Smooth,
};

const Event = struct {
  timeline: []const u8 = "",

  start: ?f32 = null,
  end: ?f32 = null,
  duration: f32 = 1.0, // Default duration if only start is provided

  repeat: u32 = 1,
  pattern: Pattern = .Forward,
  motion: Motion = .Linear,
};

pub fn add(entity: ecs.Entity, params: Event) ecs.Entity {
  if (params.start == undefined and params.end == undefined)
    if (entity.parent_id == 0) // No previous event
      @panic("Event start or end needs to be provided or a previous event should exist");

  if (params.repeat < 1)
    @panic("Event repeat should be at least 1");

  var timeline: ecs.Entity = undefined;
  if (params.timeline.len == 0) {
    timeline = entity.world.entity("timeline"); // Use main timeline by default
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

  const new = Component{
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

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    timeline_id: ?ecs.FieldFilter(ecs.EntityID) = null,
    target_id: ?ecs.FieldFilter(?ecs.EntityID) = null,

    start: ?ecs.FieldFilter(f32) = null,
    end: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.timeline_id) |cond|
      if (!ecs.matchField(ecs.EntityID, self.timeline_id, cond))
        return false;

    if (f.target_id) |cond|
      if (!ecs.matchField(?ecs.EntityID, self.target_id, cond))
        return false;

    if (f.start) |cond|
      if (!ecs.matchField(f32, self.start, cond))
        return false;

    if (f.end) |cond|
      if (!ecs.matchField(f32, self.end, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    timeline_id_asc,
    timeline_id_desc,
    target_id_asc,
    target_id_desc,

    start_asc,
    start_desc,
    end_asc,
    end_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .timeline_id_asc => std.math.order(a.timeline_id, b.timeline_id),
        .timeline_id_desc => std.math.order(b.timeline_id, a.timeline_id),
        .target_id_asc => blk: {
          const ta = a.target_id;
          const tb = b.target_id;

          if (ta == null and tb == null) break :blk .eq;
          if (ta == null) break :blk .gt; // nulls last
          if (tb == null) break :blk .lt;

          break :blk std.math.order(ta.?, tb.?);
        },
        .target_id_desc => blk: {
          const ta = a.target_id;
          const tb = b.target_id;

          if (ta == null and tb == null) break :blk .eq;
          if (ta == null) break :blk .lt; // nulls first
          if (tb == null) break :blk .gt;

          break :blk std.math.order(tb.?, ta.?);
        },

        .start_asc => std.math.order(a.start, b.start),
        .start_desc => std.math.order(b.start, a.start),
        .end_asc => std.math.order(a.end, b.end),
        .end_desc => std.math.order(b.end, a.end),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.timelineevent, f, sort);
  }
};


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
    .pattern = Pattern.Forward,
    .motion = Motion.Linear,
  });

  // Then
  try tst.expectEqual(entity.id, result.parent_id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.timelineevent.get(result.id)) |timelineevent|
    try tst.expectEqual(timelineevent, Component{
      .timeline_id = timeline.id,
      .target_id = entity.id,
      .start = 1.0,
      .end = 2.0,
      .repeat = 1,
      .pattern = Pattern.Forward,
      .motion = Motion.Linear,
    })
  else
    return error.TestExpectedTimelineEvent;
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  _ = world.entity("timeline");

  const entity1 = add(world.entity("test1"), Event{
    .start = 1.0,
    .end = 2.0,
    .duration = 1.0,
    .repeat = 1,
    .pattern = Pattern.Forward,
    .motion = Motion.Linear,
  });
  _ = add(world.entity("test2"), Event{
    .start = 3.0,
    .end = 4.0,
    .duration = 1.0,
    .repeat = 1,
    .pattern = Pattern.Forward,
    .motion = Motion.Linear,
  });

  // When
  const result = Query.exec(&world, .{ .start = .{ .eq = 1.0 } }, &.{ .start_asc });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
