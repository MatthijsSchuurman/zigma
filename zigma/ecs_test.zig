const std = @import("std");
const ecs = @import("ecs.zig");

const tst = std.testing;

test "ECS World should init" {
  // Given
  const allocator = std.testing.allocator;

  // When
  var world = ecs.World.init(allocator);

  // Then
  try tst.expectEqual(world.entity_id, 1);
  try tst.expectEqual(world.entities.count(), 0);
  try tst.expectEqual(world.components.timeline.count(), 0);

  // Clean
  world.deinit();
}

test "ECS World should init systems" {
  // Given
  const allocator = std.testing.allocator;
  var world = ecs.World.init(allocator);

  // When
  world.initSystems();

  // Then
  try tst.expectEqual(@TypeOf(world.systems.timeline), ecs.Systems.Timeline.System);

  // Clean
  world.deinit();
}

test "ECS World should deinit" {
  // Given
  var world = ecs.World.init(std.testing.allocator);

  // When
  world.deinit();

  // Then
  try tst.expectEqual(world.entity_id, 1);
}

test "ECS World should get next entity" {
  // Given
  var world = ecs.World.init(std.testing.allocator);

  // When
  const id = world.entityNext();
  const id2 = world.entityNext();

  // Then
  try tst.expectEqual(id, 1);
  try tst.expectEqual(id2, 2);

  // Clean
  world.deinit();
}

test "ECS World should add entity" {
  // Given
  var world = ecs.World.init(std.testing.allocator);

  // When
  const entity = world.entity("test");
  const entity2 = world.entity("test");

  // Then
  try tst.expectEqual(world.entities.count(), 1);
  try tst.expectEqual(entity.id, 1);
  try tst.expectEqual(entity2.id, 1);
  try tst.expectEqual(entity.parent_id, 0);
  try tst.expectEqual(entity2.parent_id, 0);
  try tst.expectEqual(entity.world, &world);
  try tst.expectEqual(entity2.world, &world);

  // Clean
  world.deinit();
}

test "ECS World should render" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  world.initSystems();

  // When
  const result = world.render();

  // Then
  try tst.expectEqual(result, true);

  // Clean
  world.deinit();
}
