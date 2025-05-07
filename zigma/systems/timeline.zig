const std = @import("std");
const ecs = @import("../ecs.zig");

const timePrecision: f32 = 0.000001;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) void {
    self.determineTime();
    self.processEvents();

    // var it = self.world.components.timelineeventprogress.iterator();
    // while (it.next()) |entry| {
    //   const id = entry.key_ptr.*;
    //   const event = entry.value_ptr.*;
    //
    //   std.debug.print("Timeline Event {d}: {d:1.6}\n", .{id, event.progress});
    //
    //   //get related events
    //   const event_entry = self.world.components.timelineevent.get(id) orelse continue;
    //
    //   const related_ids = ecs.Components.TimelineEvent.Query.exec(self.world,
    //     .{.timeline_id = .{ .eq = event_entry.timeline_id}, .target_id = .{ .eq = event_entry.target_id}},
    //     &.{.end_desc},
    //    );
    //   defer self.world.allocator.free(related_ids);
    //
    //   for (related_ids) |related_id| {
    //     if (related_id == id)
    //       continue; // skip self
    //
    //     std.debug.print("Timeline Event {d} is related to Timeline Event {d}\n", .{id, related_id});
    //   }
    // }
  }

  pub fn determineTime(self: *System) void {
    var it = self.world.components.timeline.iterator();
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

  pub fn processEvents(self: *System) void {
    var it = self.world.components.timelineevent.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;

      if (self.world.components.timeline.get(event.timeline_id)) |timeline| {
        if (@abs(timeline.speed) < timePrecision) // Singularity
          continue; // Nothing's changed

        if (timeline.speed >= 0.0) { // Normal time
          if (timeline.timeCurrent < event.start) // Event not started yet
            continue;

          if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
            if (timeline.timePrevious < event.start or (timeline.timeCurrent == 0 and timeline.timePrevious == 0)) // Not yet active
              ecs.Components.TimelineEventProgress.activate(.{.id = id, .world = self.world}, event.target_id);

            const progress = progressCalculation(timeline.timeCurrent, event);
            ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = self.world}, progress);
          } else { // No longer active
            if (timeline.timePrevious <= event.end) { // Finalize event (leaves it active for 1 more round so it reaches its end state)
              const progress = progressCalculation(timeline.timeCurrent, event);
              ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = self.world}, progress);
            } else if (self.world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
              ecs.Components.TimelineEventProgress.deactivate(.{.id = id, .world = self.world}); // Removes it from the TimelineEventProgress list
            }
          }
        } else { // Tenet
          if (event.end < timeline.timeCurrent) // Event not started yet
            continue;

          if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
            if (event.end < timeline.timePrevious or (timeline.timeCurrent == 0 and timeline.timePrevious == 0)) // Not yet active
              ecs.Components.TimelineEventProgress.activate(.{.id = id, .world = self.world}, event.target_id);

            const progress = progressCalculation(timeline.timeCurrent, event);
            ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = self.world}, progress);
          } else { // No longer active
            if (event.start <= timeline.timePrevious) { // Finalize event (leaves it active for 1 more round so it reaches its start state)
              const progress = progressCalculation(timeline.timeCurrent, event);
              ecs.Components.TimelineEventProgress.progress(.{.id = id, .world = self.world}, progress);
            } else if (self.world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
              ecs.Components.TimelineEventProgress.deactivate(.{.id = id, .world = self.world}); // Removes it from the TimelineEventProgress list
            }
          }
        }
      }
    }
  }

  fn progressCalculation(timelineCurrent :f32, event: ecs.Components.TimelineEvent.Component) f32 {
    const total_time = event.end - event.start;
    const repeat: f32 = @floatFromInt(@max(1, event.repeat));
    const iteration_time = total_time / repeat;

    const current_time = timelineCurrent - event.start;
    const progress = @mod(current_time, iteration_time) / iteration_time;

    return switch (event.pattern) {
      .Forward => progress,
      .Reverse => 1 - progress,
      .PingPong => if (progress < 0.5)
        progress * 2
      else
        (1 - progress) * 2,
      .PongPing => if (progress < 0.5)
        1 - (progress * 2)
      else
        (progress - 0.5) * 2,
      .Random => {
        var prng = std.rand.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
        return prng.random().float(f32);
      }
    };
  }
};
