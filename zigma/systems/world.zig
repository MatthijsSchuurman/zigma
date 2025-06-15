const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

const EntityMusic = @import("../entity/music.zig");

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) bool {
    var it = self.world.components.world.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const sub = entry.value_ptr.*;

      const active_events = ecs.Components.TimelineEventProgress.Query.exec(
        self.world,
       .{.target_id = .{ .eq = id}},
        &.{},
      );
      defer self.world.allocator.free(active_events);

      if (active_events.len > 0) { // World active
        return sub.world.render(); // Only render sub world
      }
    }

    return false;
  }
};


// Testing
const tst = std.testing;
const SystemTimeline = @import("timeline.zig");

test "System should render sub world" {
  // Given
  var universe = ecs.World.init(tst.allocator);
  defer universe.deinit();
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&universe);
  var system_timeline = System.init(&universe);

  _ = universe.entity("timeline").timeline();
  _ = world.entity("timeline").timeline();

  const entity = universe.entity("world").subWorld(&world)
  .event(.{.start = 0, .end= 60});

  // When
  _ = universe.entity("timeline").timeline_offset(0.5);
  _ = system_timeline.update();
  const result = system.update();

  // Then
  try tst.expectEqual(true, result);
  if (world.components.timeline.get(entity.id)) |timeline| {
    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = 1.0,
      .timeCurrent = 2.0,
      .timePrevious = 0.0,
      .timeDelta = 3.0,
      .timestampPreviousMS = 5.0,
    }, timeline);
  } else
    return error.TestExpectedTimeline;
}
