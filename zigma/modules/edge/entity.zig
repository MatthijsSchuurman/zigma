const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const ComponentEdge = @import("component.zig");

pub const Edge = struct {
  width: f32 = 1.0,
  color: ?rl.Color = null,
};

pub fn set(entity: ent.Entity, params: Edge) ent.Entity {
  if (entity.world.components.edge.getPtr(entity.id)) |existing| {
    existing.width = params.width;
    if (params.color) |color|
      existing.color = color;

    return entity;
  }

  const new = ComponentEdge.Component{
    .width = params.width,
    .color = if (params.color) |color| color else rl.Color{.r = 255, .g = 255, .b = 255, .a = 255},
  };

  entity.world.components.edge.put(entity.id, new) catch @panic("Failed to store edge");

  return entity;
}


// Testing
const tst = std.testing;
const zigma = @import("../../ma.zig");

test "Component should set edge" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").model(.{.type = "cube"});

  // When
  const result = set(entity, .{.width = 2});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.edge.get(entity.id)) |edge|
    try tst.expectEqual(ComponentEdge.Component{.width = 2.0, .color = rl.Color{.r = 255, .g = 255, .b = 255, .a = 255}}, edge)
  else
    return error.TestExpectedEdge;
}
