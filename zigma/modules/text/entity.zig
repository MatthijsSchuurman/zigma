const std = @import("std");
const ecs = @import("../../ecs.zig");

const Module = @import("module.zig").Module;

pub fn set(entity: ecs.Entity, text: []const u8) ecs.Entity {
  if (entity.world.components.text.getPtr(entity.id)) |existing| {
    existing.text = text;
    return entity.dirty(&.{.text});
  }

  const new = Module.Components.Text.Component{.text = text};
  entity.world.components.text.put(entity.id, new) catch @panic("Failed to store text");

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

  return entity.dirty(&.{.text});
}


// Testing
const tst = std.testing;

test "Component should set text" {
  // Given
  const ModuleTransform = @import("../transform/module.zig").Module;
  const ModuleColor = @import("../color/module.zig").Module;

  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, "test");

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.text.get(entity.id)) |text|
    try tst.expectEqual(Module.Components.Text.Component{.text = "test"}, text)
  else
    return error.TestExpectedText;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ModuleTransform.Components.Position.Component{.x = 0, .y = 0, .z = 0}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ModuleTransform.Components.Rotation.Component{.x = 0, .y = 0, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ModuleTransform.Components.Scale.Component{.x = 1, .y = 1, .z = 1}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ModuleColor.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.text)
  else
    return error.TestExpectedDirty;
}
