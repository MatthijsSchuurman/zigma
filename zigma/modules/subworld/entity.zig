const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub fn init(entity: ent.Entity, world: *ecs.World) ent.Entity {
  if (entity.world.components.subworld.getPtr(entity.id)) |existing| {
    existing.*.world = world;
    return entity;
  }

  const new = Module.Components.SubWorld.Component{.world = world };
  entity.world.components.subworld.put(entity.id, new) catch @panic("Failed to store subworld");

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

  if (world.components.subworld.get(entity.id)) |exists|
    try tst.expectEqual(world2, exists.world.*)
  else
    return error.TestExpectedWorld;
}
