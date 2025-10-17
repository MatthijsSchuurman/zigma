const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub const Shader = struct {
  type: []const u8 = "lighting",
};

pub fn init(entity: ecs.Entity, params: Shader) ecs.Entity {
  if (entity.world.components.shader.getPtr(entity.id)) |_|
    return entity;

  const new = Module.Components.Shader.Component{
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

pub fn deinit(entity: ecs.Entity) void {
  const existing = entity.world.components.shader.getPtr(entity.id) orelse return;

  rl.UnloadShader(existing.shader);
}


// Testing
const tst = std.testing;
const zigma = @import("../../ma.zig");

test "Component should init shader" {
  // Given
  const ModuleColor = @import("../color/module.zig").Module;

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
    try tst.expectEqual(ModuleColor.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}
