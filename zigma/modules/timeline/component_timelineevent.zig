const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

pub const Component = struct {
  timeline_id: ent.EntityID,
  target_id: ?ent.EntityID,

  start: f32 = 0,
  end: f32,

  repeat: u32 = 1,
  pattern: Pattern = .Forward,
  motion: Motion = .Linear,
};

pub const Pattern = enum {
  Forward,
  Reverse,
  PingPong,
  PongPing,
  Random,
};

pub const Motion = enum {
  Instant,
  Linear,
  EaseIn,
  EaseOut,
  EaseInOut,
  Smooth,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    timeline_id: ?ecs.FieldFilter(ent.EntityID) = null,
    target_id: ?ecs.FieldFilter(?ent.EntityID) = null,

    start: ?ecs.FieldFilter(f32) = null,
    end: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.timeline_id) |cond|
      if (!ecs.matchField(ent.EntityID, self.timeline_id, cond))
        return false;

    if (f.target_id) |cond|
      if (!ecs.matchField(?ent.EntityID, self.target_id, cond))
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

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.timelineevent, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityTimelineEvent = @import("entity_timelineevent.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  _ = world.entity("timeline");

  const entity1 = EntityTimelineEvent.add(world.entity("test1"), EntityTimelineEvent.Event{
    .start = 1.0,
    .end = 2.0,
    .duration = 1.0,
    .repeat = 1,
    .pattern = Pattern.Forward,
    .motion = Motion.Linear,
  });
  _ = EntityTimelineEvent.add(world.entity("test2"), EntityTimelineEvent.Event{
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
