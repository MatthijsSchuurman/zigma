const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentHide= @import("../components/hide.zig");

pub fn set(entity: ent.Entity, hidden: bool) ent.Entity {
  if (entity.world.components.hide.getPtr(entity.id)) |existing| {
    existing.*.hidden = hidden;
    return entity;
  }

  const new = ComponentHide.Component{.hidden = hidden };
  entity.world.components.hide.put(entity.id, new) catch @panic("Failed to store hide");

  return entity;
}

pub fn hide(entity: ent.Entity) ent.Entity {
  return set(entity, true);
}
pub fn unhide(entity: ent.Entity) ent.Entity {
  return set(entity, false);
}


// Testing
const tst = std.testing;

test "Component should set hide/unhide" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  var result = hide(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.hide.get(entity.id)) |exists|
    try tst.expectEqual(true, exists.hidden)
  else
    return error.TestExpectedHide;

  // When
  result = unhide(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.hide.get(entity.id)) |exists|
    try tst.expectEqual(false, exists.hidden)
  else
    return error.TestExpectedHide;

}
