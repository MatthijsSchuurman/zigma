const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentModel = @import("../components/model.zig");

pub const Model = struct {
  type: []const u8,
  material: []const u8 = "",
};

pub fn init(entity: ent.Entity, params: Model) ent.Entity {
  if (entity.world.components.model.getPtr(entity.id)) |_|
    return entity;

  var new = ComponentModel.Component{
    .type = params.type,
    .model = rl.LoadModelFromMesh(loadMesh(params.type)),
  };

  if (params.material.len > 0) {
    const material_entity = entity.world.entity(params.material); // May not exists yet
    new.material_id = material_entity.id;

    if (entity.world.components.material.get(material_entity.id)) |material| {
      for (0..@as(usize, @intCast(new.model.materialCount))) |i| {
        new.model.materials[i] = material.material;
      }
    } else {
      std.debug.print("Material not found: {s}\n", .{params.material});
    }
  }

  entity.world.components.model.put(entity.id, new) catch @panic("Failed to store model");

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

  return entity.dirty(&.{.model});
}

pub fn deinit(entity: ent.Entity) void {
  const existing = entity.world.components.model.getPtr(entity.id) orelse return;

  if (existing.material_id == 0) { // Default material
    if (existing.model.materials) |materials| {
      for (0..@as(usize, @intCast(existing.model.materialCount))) |i| {
        materials[i].shader = rl.Shader{}; // Unlink shader
      }
    }
  } else { // Custom material
    if (existing.model.materials) |materials| {
      for (0..@as(usize, @intCast(existing.model.materialCount))) |i| {
        materials[i] = rl.Material{}; // Unlink marterial, cleaned up by the material component
      }
    }
  }

  if (existing.transforms) |transforms|
    transforms.deinit();

  rl.UnloadModel(existing.model);
}

fn loadMesh(mesh_type: []const u8) rl.Mesh {
  if (std.mem.eql(u8, mesh_type, "cube")) return rl.GenMeshCube(1, 1, 1);
  if (std.mem.eql(u8, mesh_type, "sphere")) return rl.GenMeshSphere(1, 16, 16);
  if (std.mem.eql(u8, mesh_type, "cylinder")) return rl.GenMeshCylinder(1, 1, 16);
  if (std.mem.eql(u8, mesh_type, "torus")) return rl.GenMeshTorus(1, 1, 16, 16);
  if (std.mem.eql(u8, mesh_type, "plane")) return rl.GenMeshPlane(1, 1, 1, 1);

  @panic("LoadMeshFromFile not yet implemented");
}

pub fn hide(entity: ent.Entity, hidden: bool) ent.Entity {
  if (entity.world.components.model.getPtr(entity.id)) |existing|
    existing.hidden = hidden;

  return entity;
}


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should init model" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");

  // When
  const result = init(entity, .{.type = "cube"});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.model.get(entity.id)) |model| {
    try tst.expectEqual("cube", model.type);
    try tst.expectEqual(1, model.model.meshCount);
    try tst.expectEqual(1, model.model.materialCount);
    try tst.expectEqual(24, model.model.meshes[0].vertexCount);
    try tst.expectEqual(0, model.material_id);
    try tst.expectEqual(3, model.model.materials[0].shader.id);
    try tst.expectEqual(1, model.model.materials[0].maps[0].texture.id);
    try tst.expectEqual(0, model.model.materials[0].maps[1].texture.id);
    try tst.expectEqual(null, model.transforms);
    try tst.expectEqual(false, model.hidden);
  }
  else
    return error.TestExpectedModel;

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

test "Component should hide model" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").model(.{.type = "torus"});

  // When
  var result = hide(entity, true);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.model.get(entity.id)) |model| {
    try tst.expectEqual("torus", model.type);
    try tst.expectEqual(true, model.hidden);
  }
  else
    return error.TestExpectedModel;

  // When
  result = hide(entity, false);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.model.get(entity.id)) |model| {
    try tst.expectEqual("torus", model.type);
    try tst.expectEqual(false, model.hidden);
  }
  else
    return error.TestExpectedModel;

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.model)
  else
    return error.TestExpectedDirty;
}
