const std = @import("std");
const ecs = @import("../ecs.zig");

pub fn run(world: *ecs.World) void {
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

    std.debug.print("Timeline {d}: {d:1.2}\n", .{id, timeline.timeCurrent});
  }
}

