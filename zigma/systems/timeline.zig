const std = @import("std");
const ecs = @import("../ecs.zig");
const EntityTimelineEventProgress = @import("../entity/timelineeventprogress.zig");

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
    //   const event_entry = self.world.components.timelineevent.getPtr(id) orelse continue;
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
      var timeline = entry.value_ptr;

      var timeDelta: f32 = 0.0;
      const timestampCurrentMS = std.time.milliTimestamp();

      if (timeline.timestampPreviousMS == 0 ) { // first time
        timeline.timeCurrent = 0;
      } else {
        const timestampDelta = @as(f32, @floatFromInt(timestampCurrentMS - timeline.timestampPreviousMS)) / 1000.0;
        timeDelta += timestampDelta * timeline.speed;
      }

      if (timeline.timeOffset != 0) { // jump by offset
        timeDelta += timeline.timeOffset;
        timeline.timeOffset = 0; // reset offset
      }

      timeline.timePrevious = timeline.timeCurrent;
      timeline.timeCurrent += timeDelta;
      timeline.timeDelta = timeDelta;
      timeline.timestampPreviousMS = timestampCurrentMS;
    }
  }

  pub fn processEvents(self: *System) void {
    var it = self.world.components.timelineevent.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;

      if (self.world.components.timeline.getPtr(event.timeline_id)) |timeline| {
        if (@abs(timeline.speed) < timePrecision) // Singularity
          continue; // Nothing's changed

        const entity = self.world.entityWrap(id);
        if (timeline.timeDelta >= 0.0) { // Normal time
          if (timeline.timeCurrent < event.start) // Event not started yet
            continue;

          if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
            if (self.world.components.timelineeventprogress.getPtr(id) == null) // Not yet active
              EntityTimelineEventProgress.activate(entity, event.target_id);

            var progress = progressCalculation(timeline.timeCurrent, event);
            progress = motionCalculation(progress, event);

            EntityTimelineEventProgress.progress(entity, progress);
          } else { // No longer active
            if (timeline.timePrevious <= event.end) { // Finalize event (leaves it active for 1 more round so it reaches its end state)
              if (self.world.components.timelineeventprogress.getPtr(id) == null) // Not yet active
                EntityTimelineEventProgress.activate(entity, event.target_id);

              var progress = progressCalculation(event.end, event); // Force end of event
              progress = motionCalculation(progress, event);

              EntityTimelineEventProgress.progress(entity, progress);
            } else if (self.world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
              EntityTimelineEventProgress.deactivate(entity); // Removes it from the TimelineEventProgress list
            }
          }
        } else { // Tenet
          if (event.end < timeline.timeCurrent) // Event not started yet
            continue;

          if (event.start <= timeline.timeCurrent and timeline.timeCurrent <= event.end) { // Active event
            if (self.world.components.timelineeventprogress.getPtr(id) == null) // Not yet active
              EntityTimelineEventProgress.activate(entity, event.target_id);

            var progress = progressCalculation(timeline.timeCurrent, event);
            progress = motionCalculation(progress, event);

            EntityTimelineEventProgress.progress(entity, progress);
          } else { // No longer active
            if (event.start <= timeline.timePrevious) { // Finalize event (leaves it active for 1 more round so it reaches its start state)
              if (self.world.components.timelineeventprogress.getPtr(id) == null) // Not yet active
                EntityTimelineEventProgress.activate(entity, event.target_id);

              var progress = progressCalculation(event.start, event); // Force start of event
              progress = motionCalculation(progress, event);

              EntityTimelineEventProgress.progress(entity, progress);
            } else if (self.world.components.timelineeventprogress.getPtr(id)) |_| { // Event already finalized previously
              EntityTimelineEventProgress.deactivate(entity); // Removes it from the TimelineEventProgress list
            }
          }
        }
      }
    }
  }

  fn progressCalculation(timelineCurrent :f32, event: ecs.Components.TimelineEvent.Component) f32 {
    const total_time = event.end - event.start;
    const total_elapsed = timelineCurrent - event.start;
    const repeat: f32 = @floatFromInt(@max(1, event.repeat));
    const iteration_duration = total_time / repeat;

    const progress_timeline = total_elapsed / iteration_duration;
    const iteration_index= @floor(progress_timeline);
    const iteration_time = progress_timeline - iteration_index;

    var progress = if (iteration_time == 0 and total_elapsed > 0) 1.0 else iteration_time;

    progress = switch (event.pattern) {
      .Forward => progress,
      .Reverse => 1 - progress,
      .PingPong => 1.0 - @abs(progress * 2.0 - 1.0),
      .PongPing => @abs(progress * 2.0 - 1.0),
      .Random => {
        var prng = std.Random.DefaultPrng.init(@intCast(std.time.nanoTimestamp()));
        return prng.random().float(f32);
      }
    };

    return progress;
  }

  fn motionCalculation(t: f32, event: ecs.Components.TimelineEvent.Component) f32 {
    const progress = switch (event.motion) {
      .Instant => if (t >= 1.0) @as(f32, 1.0) else @as(f32, 0.0),
      .Linear => t,
      .EaseIn => t * t,
      .EaseOut => t * (2.0 - t),
      .EaseInOut => if (t < 0.5)
        2.0 * t * t
      else
        -1.0 + (4.0 - 2.0 * t) * t,
      .Smooth => t * t * (3.0 - 2.0 * t),
    };

    return progress;
  }
};


// Testing
const tst = std.testing;

test "System should determine time" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("timeline").timeline();

  var system = System.init(&world);

  // When
  system.determineTime();

  // Then
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    try tst.expect(std.time.milliTimestamp() >= timeline.timestampPreviousMS);
    const timestampCurrentMS = timeline.timestampPreviousMS;

    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = 1.0,
      .timeCurrent = 0.0,
      .timePrevious = 0.0,
      .timeDelta = 0.0,
      .timeOffset = 0.0,
      .timestampPreviousMS = timestampCurrentMS,
    }, timeline);
  } else {
    return error.TestExpectedTimeline;
  }


  // Given
  std.time.sleep(1_000_000);

  // When
  system.determineTime();

  // Then
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    try tst.expect(std.time.milliTimestamp() >= timeline.timestampPreviousMS);
    const timestampCurrentMS = timeline.timestampPreviousMS;

    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = 1.0,
      .timeCurrent = 0.001,
      .timePrevious = 0.0,
      .timeDelta = 0.001,
      .timeOffset = 0.0,
      .timestampPreviousMS = timestampCurrentMS,
    }, timeline);
  } else {
    return error.TestExpectedTimeline;
  }
}

test "System should determine offset" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("timeline").timeline();

  var system = System.init(&world);

  // When
  _ = world.entity("timeline").timeline_offset(0.5);
  system.determineTime();

  // Then
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = 1.0,
      .timeCurrent = 0.5,
      .timePrevious = 0.0,
      .timeDelta = 0.5,
      .timeOffset = 0.0,
      .timestampPreviousMS = timeline.timestampPreviousMS,
    }, timeline);
  } else {
    return error.TestExpectedTimeline;
  }
}



test "System should determine Tenet time" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("timeline").timeline()
    .timeline_speed(-1.0);

  var system = System.init(&world);

  // When
  system.determineTime();
  std.time.sleep(1_000_000);
  system.determineTime();

  // Then
  if (entity.world.components.timeline.get(entity.id)) |timeline| {
    try tst.expect(std.time.milliTimestamp() >= timeline.timestampPreviousMS);
    const timestampCurrentMS = timeline.timestampPreviousMS;
    try tst.expectEqual(ecs.Components.Timeline.Component{
      .speed = -1.0,
      .timeCurrent = -0.001,
      .timePrevious = 0.0,
      .timeDelta = -0.001,
      .timeOffset = 0.0,
      .timestampPreviousMS = timestampCurrentMS,
    }, timeline);
  } else {
    return error.TestExpectedTimeline;
  }
}


test "System should process events" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("timeline").timeline()
  .timeline_offset(0.5);

  var system = System.init(&world);
  system.determineTime();

  // When
  const event = world.entity("test").event(.{.start = 0.0, .duration = 1.0});
  system.processEvents();

  // Then
  if (entity.world.components.timelineeventprogress.get(event.id)) |timelineeventprogress| {
    try tst.expectEqual(ecs.Components.TimelineEventProgress.Component{
      .progress = 0.5,
      .target_id = event.parent_id,
    }, timelineeventprogress);
  } else {
    return error.TestExpectedTimeline;
  }
}


test "System should process calculation" {
  // Given
  var event = ecs.Components.TimelineEvent.Component{
    .timeline_id = 0,
    .start = 0.0,
    .end = 1.0,
    .repeat = 1,
    .pattern = ecs.Components.TimelineEvent.Pattern.Forward,
    .motion = ecs.Components.TimelineEvent.Motion.Linear,
    .target_id = 0,
  };

  var i: f32 = 0;
  while (i <= 1.0) : (i += 0.1) {
    // When
    const result = System.progressCalculation(i, event);

    // Then
    try tst.expectEqual(i, result);
  }


  // Given
  event.pattern = ecs.Components.TimelineEvent.Pattern.Reverse;

  i = 0;
  while (i <= 1.0) : (i += 0.1) {
    // When
    const result = System.progressCalculation(i, event);

    // Then
    try tst.expectEqual(1 - i, result);
  }
}

test "System should motion calculation" {
  // Given
  var event = ecs.Components.TimelineEvent.Component{
    .timeline_id = 0,
    .start = 0.0,
    .end = 1.0,
    .repeat = 1,
    .pattern = ecs.Components.TimelineEvent.Pattern.Forward,
    .motion = ecs.Components.TimelineEvent.Motion.Linear,
    .target_id = 0,
  };

  var i: f32 = 0;
  while (i <= 1.0) : (i += 0.1) {
    // When
    const result = System.motionCalculation(i, event);

    // Then
    try tst.expectEqual(i, result);
  }


  // Given
  event.motion = ecs.Components.TimelineEvent.Motion.EaseIn;

  i = 0;
  while (i <= 1.0) : (i += 0.1) {
    // When
    const result = System.motionCalculation(i, event);

    // Then
    try tst.expectEqual(i * i, result);
  }
}
