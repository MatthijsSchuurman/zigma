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
    const world_timeline = self.world.components.timeline.get(self.world.entity("timeline").id) orelse return false; // No timeline, prolly testing

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
        // Ensure sub world timeline system correctly adjust timeline
        const subworld_timeline = sub.world.components.timeline.getPtr(sub.world.entity("timeline").id) orelse @panic("World system update no timeline");
        subworld_timeline.timestampPreviousMS = world_timeline.timestampPreviousMS - @as(i64, @intFromFloat(world_timeline.timeDelta*1000));

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
  world.initSystems();
  defer world.deinit();

  var universe_system_timeline = SystemTimeline.System.init(&universe);
  var universe_system = System.init(&universe);

  const universe_timeline_entity = universe.entity("timeline").timeline();
  const world_timeline_entity = world.entity("timeline").timeline();

  _ = universe.entity("world").subWorld(&world)
  .event(.{.start = 0, .end= 60});

  const timestampPreviousMS = std.time.milliTimestamp();
  const universe_timeline = universe.components.timeline.getPtr(universe_timeline_entity.id) orelse unreachable;
  universe_timeline.timestampPreviousMS = timestampPreviousMS-100;

  _ = universe_timeline_entity.timeline_speed(2);
  _ = world_timeline_entity.timeline_speed(1.5);

  // When
  _ = universe_system_timeline.update();
  const result = universe_system.update();

  rl.BeginDrawing(); //Nasty but it does ensure cleanup... no way around this as sub.world.render() has to be called for this test
  rl.ClearBackground(rl.BLACK);
  rl.EndDrawing();

  // Then
  try tst.expectEqual(true, result);
  if (world.components.timeline.get(world_timeline_entity.id)) |timeline| {
    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = 1.5,
      .timeCurrent = 0.3,
      .timePrevious = 0.0,
      .timeDelta = 0.3,
      .timestampPreviousMS = timestampPreviousMS,
    }, timeline);
  } else
    return error.TestExpectedTimeline;
}
