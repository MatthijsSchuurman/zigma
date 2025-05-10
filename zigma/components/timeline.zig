const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  speed: f32 = 1.0,
  timeCurrent: f32 = 0,
  timePrevious: f32 = 0,
  timeOffset: f32 = 0,
  timeDelta: f32 = 0,
  timestampPreviousMS: i64 = 0,
};

pub fn init(entity: ecs.Entity) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |_|
    return entity;

  const new = .{};

  entity.world.components.timeline.put(entity.id, new) catch @panic("Failed to store timeline");
  return entity;
}

pub fn setSpeed(entity: ecs.Entity, speed: f32) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |timeline|
    timeline.speed = speed;

  return entity;
}

pub fn setOffset(entity: ecs.Entity, offset: f32) ecs.Entity {
  if (entity.world.components.timeline.getPtr(entity.id)) |timeline|
    timeline.timeOffset= offset;

  return entity;
}


// Testing
const tst = std.testing;

test "Component should init timeline" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = init(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.timeline.get(entity.id)) |timeline|
    try tst.expectEqual(Component{.speed = 1.0, .timeCurrent = 0, .timePrevious = 0, .timeOffset = 0, .timeDelta = 0, .timestampPreviousMS = 0}, timeline)
  else
    return error.TestExpected;
}

test "Component should set speed" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  _ = init(entity);

  // When
  const result = setSpeed(entity, 2.0);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (result.world.components.timeline.get(result.id)) |timeline|
    try tst.expectEqual(2.0, timeline.speed)
  else
    return error.TestExpected;
}

test "Component should set offset" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  _ = init(entity);

  // When
  const result = setOffset(entity, 2.0);

  // Then
  try tst.expectEqual(result.id, entity.id);
  try tst.expectEqual(result.world, entity.world);

  if (result.world.components.timeline.get(result.id)) |timeline|
    try tst.expectEqual(timeline.timeOffset, 2.0)
  else
    return error.TestExpected;
}
