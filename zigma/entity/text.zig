const std = @import("std");
const ent = @import("../entity.zig");

const ComponentText = @import("../components/text.zig");

pub fn set(entity: ent.Entity, text: []const u8) ent.Entity {
  if (entity.world.components.text.getPtr(entity.id)) |existing| {
    existing.* = ComponentText.Component{.text = text};
    return entity;
  }

  const new = ComponentText.Component{.text = text};
  entity.world.components.text.put(entity.id, new) catch @panic("Failed to store text");

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

  return entity;
}


// Testing
const tst = std.testing;
const ecs = @import("../ecs.zig");

test "Component should set text" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, "test");

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.text.get(entity.id)) |text|
    try tst.expectEqual(text.Component{.text = "test"}, text)
  else
    return error.TestExpectedText;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = 0, .y = 0, .z = 0}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0, .y = 0, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ecs.Components.Scale.Component{.x = 1, .y = 1, .z = 1}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}
