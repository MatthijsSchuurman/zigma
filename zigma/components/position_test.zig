const std = @import("std");
const ecs = @import("../ecs.zig");
const cmp = @import("position.zig");

const tst = std.testing;

test "Component Position should set value" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  const entity = world.entity("test");

  // When
  const result = cmp.position(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(result.id, entity.id);
}
