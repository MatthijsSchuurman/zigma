const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentSpawn = @import("../components/spawn.zig");

pub const Spawn = struct {
  model: []const u8 = "",
};

pub fn init(entity: ent.Entity, params: Spawn) ent.Entity {
  if (entity.world.components.spawn.getPtr(entity.id)) |_|
    return entity;

  if (params.model.len == 0)
    @panic("Spawn requires a model");

  const model2 = entity.world.components.model.getPtr(entity.id) orelse @panic("Spawn must be a model entity");

  const model_entity = entity.world.entity(params.model); // May not exists yet
  const model = entity.world.components.model.get(model_entity.id) orelse @panic("Spawn requires model entity to exist");

  var new = ComponentSpawn.Component{
    .model_id = model_entity.id,
    .vertex_indexes = std.ArrayList(usize).init(entity.world.allocator),
  };

  // Get unique coordinates
  var unique = std.AutoArrayHashMap(usize, rl.Vector3).init(entity.world.allocator);
  defer unique.deinit();

  const mesh = model.model.meshes[0];
  vertex: for (0..@intCast(mesh.vertexCount)) |vertex_index| {
    const base = vertex_index * 3;
    const position = rl.Vector3{
      .x = mesh.vertices[base + 0],
      .y = mesh.vertices[base + 1],
      .z = mesh.vertices[base + 2],
    };

    var it = unique.iterator();
    while (it.next()) |entry|
      if (rl.Vector3Equals(entry.value_ptr.*, position) != 0)
        continue :vertex; // Skip if position already exists

    _ = unique.put(vertex_index, position) catch @panic("Failed to store unique vertex position");
  }

  // Store unique vertex indexes
  var it = unique.iterator();
  while (it.next()) |entry|
    new.vertex_indexes.append(entry.key_ptr.*) catch @panic("Failed to store spawn vertex index");

  entity.world.components.spawn.put(entity.id, new) catch @panic("Failed to store spawn");

  // Prepare model transformations array
  model2.transforms = std.ArrayList(rl.Matrix).init(entity.world.allocator);
  for (0..new.vertex_indexes.items.len) |_|
    model2.transforms.?.append(rl.Matrix{}) catch @panic("Failed to prepare model transforms");

  _ = entity
  .rotation(0, 0, 0)
  .scale(0.1, 0.1, 0.1)
  .color(255, 255, 255, 255);

  return entity;
}

pub fn deinit(entity: ent.Entity) void {
  const existing = entity.world.components.spawn.getPtr(entity.id) orelse return;

  // World cleans this up for now
  // var it = existing.child_ids.iterator();
  // while (it.next()) |entry|
  //   entity.world.entityDelete(entry.key_ptr.*);

  existing.vertex_indexes.deinit();
}

pub fn hide(entity: ent.Entity) ent.Entity {
  if (entity.world.components.spawn.getPtr(entity.id)) |existing|
    existing.hidden = true;

  return entity;
}

pub fn unhide(entity: ent.Entity) ent.Entity {
  if (entity.world.components.spawn.getPtr(entity.id)) |existing|
    existing.hidden = false;

  return entity;
}

pub fn transform(entity: ent.Entity, position: rl.Vector3, rotation: rl.Vector3, scale: rl.Vector3) ent.Entity {
  const spawn = entity.world.components.spawn.getPtr(entity.id) orelse return entity;
  spawn.spawn.transform = makeTransform(position, rotation, scale);
  return entity;
}

fn makeTransform(position: rl.Vector3, rotation: rl.Vector3, scale: rl.Vector3) rl.Matrix {
  const T = rl.MatrixTranslate(position.x, position.y, position.z);
  const R = rl.MatrixRotateXYZ(rotation);
  const S = rl.MatrixScale(scale.x, scale.y, scale.z);
  return rl.MatrixMultiply(T, rl.MatrixMultiply(R, S));
}


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should init model spawn" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = world.entity("cube").model(.{.type = "cube"});
  const entity = world.entity("test").model(.{.type = "cube"});

  // When
  const result = init(entity, .{.model = "cube"});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.spawn.get(entity.id)) |spawn| {
    try tst.expectEqual(1, spawn.model_id);
    try tst.expectEqual(8, spawn.vertex_indexes.items.len);
  }
  else
    return error.TestExpectedSpawn;

  if (world.components.spawn.get(entity.id)) |spawn|
    try tst.expectEqual(1, spawn.model_id)
  else
    return error.TestExpectedSpawn;

  if (world.components.model.get(entity.id)) |model|
    try tst.expect(model.transforms != null)
  else
    return error.TestExpectedModel;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0, .y = 0, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ecs.Components.Scale.Component{.x = 0.1, .y = 0.1, .z = 0.1}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}

test "Component should hide spawn" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  _ = world.entity("cube").model(.{.type = "cube"});
  const entity = world.entity("test").model(.{.type = "torus"}).spawn(.{.model = "cube"});

  // When
  var result = hide(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.spawn.get(entity.id)) |spawn|
    try tst.expectEqual(true, spawn.hidden)
  else
    return error.TestExpectedSpawn;

  // When
  result = unhide(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.spawn.get(entity.id)) |spawn|
    try tst.expectEqual(false, spawn.hidden)
  else
    return error.TestExpectedSpawn;
}
