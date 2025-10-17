const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub fn init(entity: ecs.Entity) ecs.Entity {
  if (entity.world.components.fps.getPtr(entity.id)) |_|
    return entity;

  const new = Module.Components.FPS.Component{};
  entity.world.components.fps.put(entity.id, new) catch @panic("Failed to store fps");

  return entity;
}


// Testing
const tst = std.testing;

test "Component should init fps" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = init(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.fps.get(entity.id)) |exists|
    try tst.expectEqual(Module.Components.FPS.Component{}, exists)
  else
    return error.TestExpectedFPS;
}
