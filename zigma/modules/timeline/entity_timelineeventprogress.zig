const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

const Module = @import("module.zig").Module;

pub fn activate(entity: ent.Entity, target_id: ?ent.EntityID) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |_| { // Already active
    return;
  }

  const new = Module.Components.TimelineEventProgress.Component{.target_id = target_id};
  entity.world.components.timelineeventprogress.put(entity.id, new) catch @panic("Failed to store timeline event progress");
}

pub fn progress(entity: ent.Entity, currentProgress: f32) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |existing| { // Already active
    existing.progress = currentProgress;
    return;
  }
}

pub fn deactivate(entity: ent.Entity) void {
  _ = entity.world.components.timelineeventprogress.remove(entity.id);
}


// Testing
const tst = std.testing;

test "Component should activate timeline event progress" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  activate(entity, null);

  // Then
  if (world.components.timelineeventprogress.get(entity.id)) |timelineeventprogress|
    try tst.expectEqual(Module.Components.TimelineEventProgress.Component{.progress = 0, .target_id = null}, timelineeventprogress)
  else
    return error.TestExpectedTimelineEventProgress;
}

test "Component should set progress" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  activate(entity, null);

  // When
  progress(entity, 0.5);

  // Then
  if (world.components.timelineeventprogress.get(entity.id)) |timelineeventprogress|
    try tst.expectEqual(Module.Components.TimelineEventProgress.Component{.progress = 0.5, .target_id = null}, timelineeventprogress)
  else
    return error.TestExpectedTimelineEventProgress;
}

test "Component should deactivate timeline event progress" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  activate(entity, null);

  // When
  deactivate(entity);

  // Then
  if (world.components.timelineeventprogress.get(entity.id)) |_|
    return error.TestExpectedTimelineEventProgress;
}
