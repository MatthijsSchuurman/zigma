const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.rotation.getPtr(entity.id)) |existing| {
    existing.* = Module.Components.Rotation.Component{.x = x, .y = y, .z = z};
    return entity.dirty(&.{.rotation});
  }

  const new = Module.Components.Rotation.Component{.x = x, .y = y, .z = z };
  entity.world.components.rotation.put(entity.id, new) catch @panic("Failed to store rotation");

  return entity.dirty(&.{.rotation});
}


// Testing
const tst = std.testing;

test "Component should set rotation" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(Module.Components.Rotation.Component{.x = 1, .y = 2, .z = 3}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.rotation)
  else
    return error.TestExpectedDirty;
}
