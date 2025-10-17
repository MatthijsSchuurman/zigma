const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub const Spawn = struct {
  source_model: []const u8 = "",
};


pub fn init(entity: ecs.Entity, params: Spawn) ecs.Entity {
  if (entity.world.components.spawn.getPtr(entity.id)) |_|
    return entity;

  if (params.source_model.len == 0)
    @panic("Spawn requires a source model");

  const model = entity.world.components.model.getPtr(entity.id) orelse @panic("Spawn must be a model entity");

  const source_entity = entity.world.entity(params.source_model); // May not exists yet
  const source_model = entity.world.components.model.get(source_entity.id) orelse @panic("Spawn requires source model entity to exist");

  var new = Module.Components.Spawn.Component{
    .source_model_id = source_entity.id,
  };

  // Get unique coordinates
  var unique = std.AutoArrayHashMap(usize, rl.Vector3).init(entity.world.allocator);
  defer unique.deinit();

  const mesh = source_model.model.meshes[0];
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
    new.vertex_indexes.append(entity.world.allocator, entry.key_ptr.*) catch @panic("Failed to store spawn vertex index");

  entity.world.components.spawn.put(entity.id, new) catch @panic("Failed to store spawn");

  // Prepare model transformations array
  model.transforms = .empty;
  for (0..new.vertex_indexes.items.len) |_|
    model.transforms.?.append(entity.world.allocator, rl.Matrix{}) catch @panic("Failed to prepare model transforms");

  _ = entity
  .rotation(0, 0, 0)
  .scale(0.1, 0.1, 0.1)
  .color(255, 255, 255, 255);

  return entity;
}

pub fn deinit(entity: ecs.Entity) void {
  const existing = entity.world.components.spawn.getPtr(entity.id) orelse return;

  // World cleans this up for now
  // var it = existing.child_ids.iterator();
  // while (it.next()) |entry|
  //   entity.world.entityDelete(entry.key_ptr.*);

  existing.vertex_indexes.deinit(entity.world.allocator);
}


// Testing
const tst = std.testing;
const zigma = @import("../../ma.zig");

test "Component should init model spawn" {
  // Given
  const ModuleTransform = @import("../transform/module.zig").Module;
  const ModuleColor = @import("../color/module.zig").Module;

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = world.entity("cube").model(.{.type = "cube"});
  const entity = world.entity("test").model(.{.type = "cube"});

  // When
  const result = init(entity, .{.source_model = "cube"});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.spawn.get(entity.id)) |spawn| {
    try tst.expectEqual(1, spawn.source_model_id);
    try tst.expectEqual(8, spawn.vertex_indexes.items.len);
  }
  else
    return error.TestExpectedSpawn;

  if (world.components.spawn.get(entity.id)) |spawn|
    try tst.expectEqual(1, spawn.source_model_id)
  else
    return error.TestExpectedSpawn;

  if (world.components.model.get(entity.id)) |model| {
    try tst.expect(model.transforms != null);
    try tst.expectEqual(8, model.transforms.?.items.len);
  }
  else
    return error.TestExpectedModel;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ModuleTransform.Components.Rotation.Component{.x = 0, .y = 0, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ModuleTransform.Components.Scale.Component{.x = 0.1, .y = 0.1, .z = 0.1}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ModuleColor.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}
