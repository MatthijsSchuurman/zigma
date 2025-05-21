const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentPosition = @import("../components/position.zig");

pub fn set(entity: ent.Entity, x: f32, y: f32, z: f32) ent.Entity {
  if (entity.world.components.position.getPtr(entity.id)) |existing| {
    existing.* = ComponentPosition.Component{.x = x, .y = y, .z = z};
    return entity;
  }

  const new = ComponentPosition.Component{.x = x, .y = y, .z = z };
  entity.world.components.position.put(entity.id, new) catch @panic("Failed to store position");

  return entity;
}


// Testing
const tst = std.testing;

test "Component should set position" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ComponentPosition.Component{.x = 1, .y = 2, .z = 3}, position)
  else
    return error.TestExpectedPosition;
}
