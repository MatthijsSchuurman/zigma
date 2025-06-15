const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentWorld= @import("../components/world.zig");

pub fn init(entity: ent.Entity, world: *ecs.World) ent.Entity {
  if (entity.world.components.world.getPtr(entity.id)) |existing| {
    existing.*.world = world;
    return entity;
  }

  const new = ComponentWorld.Component{.world = world };
  entity.world.components.world.put(entity.id, new) catch @panic("Failed to store world");

  return entity;
}


// Testing
const tst = std.testing;

test "Component should init world" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);
  var world2 = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world2);

  const entity = world.entity("test");

  // When
  const result = init(entity, &world2);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.world.get(entity.id)) |exists|
    try tst.expectEqual(world2, exists.world.*)
  else
    return error.TestExpectedWorld;
}
