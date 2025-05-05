const std = @import("std");
const ecs = @import("../ecs.zig");

const timePrecision: f32 = 0.000001;

pub fn run(world: *ecs.World) void {
  determineTime(world);
  processEvents(world);

  var it = world.components.timelineeventprogress.iterator();
  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    const event = entry.value_ptr.*;

    std.debug.print("Timeline Event {d}: {d:1.6}\n", .{id, event.progress});

    //get related events
    const event_entry = world.components.timelineevent.get(id) orelse continue;

    const related_ids = ecs.Components.TimelineEvent.query(world,
      .{.timeline_id = event_entry.timeline_id, .target_id = event_entry.target_id},
      &.{.end_desc},
     );
    defer world.allocator.free(related_ids);

    for (related_ids) |related_id| {
      if (related_id == id)
        continue; // skip self

      std.debug.print("Timeline Event {d} is related to Timeline Event {d}\n", .{id, related_id});
    }
  }
}

pub fn determineTime(world: *ecs.World) void {
  var it = world.components.timeline.iterator();
  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    var timeline = entry.value_ptr;

    if (timeline.timestampPreviousMS == 0 ) { // first time
      timeline.timeCurrent = 0;
      timeline.timePrevious = 0;
      timeline.timestampPreviousMS = std.time.milliTimestamp(); //store for next determine
    } else {
      const timestampCurrentMS = std.time.milliTimestamp();
      const timestampDelta = @as(f32, @floatFromInt(timestampCurrentMS - timeline.timestampPreviousMS)) / 1000.0;

      timeline.timePrevious = timeline.timeCurrent;
      timeline.timeCurrent += timestampDelta * timeline.speed;
      timeline.timestampPreviousMS = timestampCurrentMS;
    }

    std.debug.print("Timeline {d}: {d:1.6}, speed: {d:1.2}\n", .{id, timeline.timeCurrent, timeline.speed});
  }
}

pub fn processEvents(world: *ecs.World) void {
  var it = world.components.timelineevent.iterator();
  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    const event = entry.value_ptr.*;

    if (world.components.timeline.get(event.timeline_id)) |timeline| {
      if (@abs(timeline.speed) < timePrecision) // Singularity
        continue; // Nothing's changed

      if (timeline.speed >= 0.0) { // Normal time
        if (timeline.timeCurrent < event.start) // Event not started yet
          continue;

        if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
          const progress = (timeline.timeCurrent - event.start) / (event.end - event.start);

          ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = world}, progress);
        } else { // No longer active
          if (timeline.timePrevious <= event.end) { // Finalize event (leaves it active for 1 more round so it reaches its end state)
            ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = world}, 1.0);
          } else if (world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
            ecs.Components.TimelineEventProgress.deactivate(.{.id = id, .world = world}); // Removes it from the TimelineEventProgress list
          }
        }
      } else { // Tenet
        if (event.end < timeline.timeCurrent) // Event not started yet
          continue;

        if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
          const progress = (timeline.timeCurrent - event.start) / (event.end - event.start);

          ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = world}, progress);
        } else { // No longer active
          if (event.start <= timeline.timePrevious) { // Finalize event (leaves it active for 1 more round so it reaches its start state)
            ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = world}, 0.0);
          } else if (world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
            ecs.Components.TimelineEventProgress.deactivate(.{.id = id, .world = world}); // Removes it from the TimelineEventProgress list
          }
        }
      }
    }
  }
}
