const ecs = @import("../ecs.zig");
const std = @import("std");

pub const Component = struct {
  timeline_id: ecs.EntityID,
  target_id: ?ecs.EntityID,

  start: f32 = 0,
  end: f32,

  pub const Filter = struct {
    timeline_id: ?ecs.FieldFilter(ecs.EntityID) = null,
    target_id: ?ecs.FieldFilter(?ecs.EntityID) = null,

    start: ?ecs.FieldFilter(f32) = null,
    end: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Component, f: Filter) bool {
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

  pub fn compare(a: Component, b: Component, sort: []const Sort) std.math.Order {
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
};

pub fn query(world: *ecs.World, filter: Component.Filter, sort: []const Component.Sort) []ecs.EntityID {
  return world.query(Component, &world.components.timelineevent, filter, sort);
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

  const new = Component{
    .timeline_id = timeline.id,
    .target_id = event.parent_id,
    .start = realStart,
    .end = realEnd,
  };

  entity.world.components.timelineevent.put(event.id, new) catch @panic("Failed to store timeline event");
  return event;
}
