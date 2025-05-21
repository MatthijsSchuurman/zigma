const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentShader = @import("../components/shader.zig");

const Shader = struct {
  type: []const u8 = "lighting",
};

pub fn init(entity: ent.Entity, params: Shader) ent.Entity {
  if (entity.world.components.shader.getPtr(entity.id)) |_|
    return entity;

  const new = ComponentShader.Component{
    .type = params.type,
    .shader = loadShader(params.type),
  };
  entity.world.components.shader.put(entity.id, new) catch @panic("Failed to store shader");

  _ = entity
  .color(255, 255, 255, 255);

  return entity;
}

fn loadShader(shader_type: []const u8) rl.Shader {
  if (!std.mem.eql(u8, shader_type, "lighting") and !std.mem.eql(u8, shader_type, "test"))
    @panic("LoadShader not yet implemented");

  return rl.LoadShader("zigma/shaders/lighting.vs", "zigma/shaders/lighting.fs");
}


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should set mesh" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");

  // When
  const result = init(entity, .{});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.shader.get(entity.id)) |shader| {
    try tst.expectEqual("lighting", shader.type);
  }

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}
