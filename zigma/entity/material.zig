const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentMaterial = @import("../components/material.zig");

pub const Material = struct {
  shader: []const u8 = "",
};

pub fn init(entity: ent.Entity, params: Material) ent.Entity {
  if (entity.world.components.material.getPtr(entity.id)) |_|
    return entity;

  var new = ComponentMaterial.Component{
    .material = rl.LoadMaterialDefault(),
  };

  if (params.shader.len > 0) {
    const shader_entity = entity.world.entity(params.shader); // May not exists yet
    new.shader_id = shader_entity.id;

    if (entity.world.components.shader.get(shader_entity.id)) |shader|
      new.material.shader = shader.shader
    else
      std.debug.print("Shader not found: {s}\n", .{params.shader});
  }

  entity.world.components.material.put(entity.id, new) catch @panic("Failed to store material");

  return entity.dirty(&.{.material});
}

pub fn deinit(entity: ent.Entity) void {
  const existing = entity.world.components.material.getPtr(entity.id) orelse return;

  existing.material.shader = rl.Shader{}; // Unlink shader
  rl.UnloadMaterial(existing.material);
}


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should init material" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");

  // When
  const result = init(entity, .{});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.material.get(entity.id)) |material| {
    try tst.expectEqual(0, material.shader_id);
    try tst.expectEqual(3, material.material.shader.id);
    try tst.expectEqual(1, material.material.maps[0].texture.id);
    try tst.expectEqual(0, material.material.maps[1].texture.id);
  }

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.material)
  else
    return error.TestExpectedDirty;
}
