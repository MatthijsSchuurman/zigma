const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentScale= @import("../components/scale.zig");

pub fn set(entity: ent.Entity, x: f32, y: f32, z: f32) ent.Entity {
  if (entity.world.components.scale.getPtr(entity.id)) |existing| {
    existing.* = ComponentScale.Component{.x = x, .y = y, .z = z};
    return entity.dirty(&.{.scale});
  }

  const new = ComponentScale.Component{.x = x, .y = y, .z = z };
  entity.world.components.scale.put(entity.id, new) catch @panic("Failed to store scale");

  return entity.dirty(&.{.scale});
}


// Testing
const tst = std.testing;

test "Component should set scale" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ComponentScale.Component{.x = 1, .y = 2, .z = 3}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.scale)
  else
    return error.TestExpectedDirty;
}
