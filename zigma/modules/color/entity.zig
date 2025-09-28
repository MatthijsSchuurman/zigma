const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub fn set(entity: ent.Entity, r: u8, g: u8, b: u8, a: u8) ent.Entity {
  if (entity.world.components.color.getPtr(entity.id)) |existing| {
    existing.* = Module.Components.Color.Component{.r = r, .g = g, .b = b, .a = a };
    return entity.dirty(&.{.color});
  }

  const new = Module.Components.Color.Component{.r = r, .g = g, .b = b, .a = a };
  entity.world.components.color.put(entity.id, new) catch @panic("Failed to store color");

  return entity.dirty(&.{.color});
}


// Testing
const tst = std.testing;

test "Component should set color" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3, 4);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(Module.Components.Color.Component{.r = 1, .g = 2, .b = 3, .a = 4}, color)
  else
    return error.TestExpectedColor;

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.color)
  else
    return error.TestExpectedDirty;
}
