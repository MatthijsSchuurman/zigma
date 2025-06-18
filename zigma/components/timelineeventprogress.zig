const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");

pub const Component = struct {
  progress: f32 = 0,
  target_id: ?ent.EntityID,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    progress: ?ecs.FieldFilter(f32) = null,
    target_id: ?ecs.FieldFilter(?ent.EntityID) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.progress) |cond|
      if (!ecs.matchField(f32, self.progress, cond))
        return false;

    if (f.target_id) |cond|
      if (!ecs.matchField(?ent.EntityID, self.target_id, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    progress_asc,
    progress_desc,
    target_id_asc,
    target_id_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .progress_asc => std.math.order(a.progress, b.progress),
        .progress_desc => std.math.order(b.progress, a.progress),
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
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.timelineeventprogress, f, sort);
  }
};

// Testing
const tst = std.testing;
const EntityTimelineEventProgress = @import("../entity/timelineeventprogress.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  _ = world.entity("timeline");

  const entity1=world.entity("test1");
  EntityTimelineEventProgress.activate(entity1, world.entity("target").id);
  EntityTimelineEventProgress.activate(world.entity("test2"), world.entity("target").id);
  EntityTimelineEventProgress.progress(entity1, 0.6);

  // When
  const result = Query.exec(&world, .{ .progress = .{ .gt = 0.5 } }, &.{ .progress_asc });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
