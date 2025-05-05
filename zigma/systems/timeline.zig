const std = @import("std");
const ecs = @import("../ecs.zig");

const timePrecision: f32 = 0.0001;

pub fn run(world: *ecs.World) void {
  determineTime(world);
  processEvents(world);
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

    std.debug.print("Timeline {d}: {d:1.3}, speed: {d:1.2}\n", .{id, timeline.timeCurrent, timeline.speed});
  }
}

pub fn processEvents(world: *ecs.World) void {
  var it = world.components.timelineevent.iterator();
  while (it.next()) |entry| {
    const id = entry.key_ptr.*;
    const event = entry.value_ptr.*;

    if (world.components.timeline.get(event.timeline_id)) |timeline| {
      const difference = timeline.timePrevious - timeline.timeCurrent;

      if (@abs(difference) < timePrecision) // Singularity
        continue; // Nothing's changed

      const entity = ecs.Entity{.id = id, .world = world};
      const progress = (timeline.timeCurrent - event.start) / (event.end - event.start);

      if (difference > 0.0) { // Normal time
        if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
          ecs.Components.TimelineEventProgress.progress(entity, progress);
        } else { // No longer active
          if (timeline.timePrevious <= event.end) { // Finalize event (leaves it active for 1 more round so it reaches its end state)
            ecs.Components.TimelineEventProgress.progress(entity, 1.0);
          } else { // Event already finalized
            ecs.Components.TimelineEventProgress.deactivate(entity); // Removes it from the TimelineEventProgress list
          }
        }

      } else { // Tenet

      }
    }
  }
}
