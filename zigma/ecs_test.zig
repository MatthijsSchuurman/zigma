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

test "ECS World should query timeline events" {
  // Given
  var world = ecs.World.init(std.testing.allocator);

  _ = world.entity("timeline").timeline_init();
  _ = world.entity("test").event(.{ .start = 0, .end = 1 });

  // When
  const result = world.query(ecs.Components.TimelineEvent.Query, &world.components.timelineevent, .{ .timeline_id = .{ .eq = 1 } }, &.{.end_desc});

  // Then
  try tst.expectEqual(result.len, 1);

  // Clean
  world.allocator.free(result);
  world.deinit();
}

test "ECS should convert to lower case" {
  // Given
  const str = "TEST";

  // When
  const result = ecs.toLower(str);

  // Then
  try tst.expectEqualStrings(result, "test");
  try tst.expectEqual(result[result.len], 0);
}

test "ECS should match various comparison types" {
    // Given
  const TestCase = struct {
    desc: []const u8,
    actual: i32,
    cond: ecs.FieldFilter(i32),
    expected: bool,
  };

  const cases = [_]TestCase{
    .{ .desc = "eq pass", .actual = 42, .cond = .{ .eq = 42 }, .expected = true },
    .{ .desc = "eq fail", .actual = 41, .cond = .{ .eq = 42 }, .expected = false },
    .{ .desc = "lt pass", .actual = 10, .cond = .{ .lt = 20 }, .expected = true },
    .{ .desc = "gt fail", .actual = 10, .cond = .{ .gt = 20 }, .expected = false },
  };

  for (cases) |c| {
    try tst.expectEqual(ecs.matchField(i32, c.actual, c.cond), c.expected);
  }
}
