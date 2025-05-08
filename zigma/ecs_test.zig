const std = @import("std");
const tst = @import("std").testing;
const ecs = @import("ecs.zig");

test "ECS World should init" {
  // Given
  const allocator = std.testing.allocator;

  // When
  var world = ecs.World.init(allocator);

  // Then
  try tst.expect(world.entity_id == 1);

  // Clean
  world.deinit();
}
