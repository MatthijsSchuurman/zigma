const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  type: []const u8,
  model: rl.Model,
  material_id: ecs.EntityID,

  pub fn deinit(self: *Component) void{
    rl.UnloadModel(self.model);
  }
};

const Model = struct {
  type: []const u8,
  material: []const u8 = "",
};

pub fn init(entity: ecs.Entity, params: Model) ecs.Entity {
  if (entity.world.components.model.getPtr(entity.id)) |_|
    return entity;

  var material_entity: ecs.Entity = undefined;
  if (params.material.len == 0) {
    material_entity = entity.world.entity("material"); // Use default material
  } else {
    material_entity = entity.world.entity(params.material); // May not exists yet
  }

  const new = .{
    .type = params.type,
    .model = rl.LoadModelFromMesh(loadMesh(params.type)),
    .material_id = material_entity.id,
  };

  if (entity.world.components.material.get(material_entity.id)) |material| {
    for (0..@as(usize, @intCast(new.model.materialCount))) |i| {
      new.model.materials[i] = material.material;
    }
  }

  entity.world.components.model.put(entity.id, new) catch @panic("Failed to store model");

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

  return entity;
}

fn loadMesh(mesh_type: []const u8) rl.Mesh {
  if (std.mem.eql(u8, mesh_type, "cube")) return rl.GenMeshCube(1, 1, 1);
  if (std.mem.eql(u8, mesh_type, "sphere")) return rl.GenMeshSphere(1, 16, 16);
  if (std.mem.eql(u8, mesh_type, "cylinder")) return rl.GenMeshCylinder(1, 1, 16);
  if (std.mem.eql(u8, mesh_type, "torus")) return rl.GenMeshTorus(1, 1, 16, 16);
  if (std.mem.eql(u8, mesh_type, "plane")) return rl.GenMeshPlane(1, 1, 1, 1);

  @panic("LoadMeshFromFile not yet implemented");
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    type: ?ecs.FieldFilter([]const u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.type) |cond|
      if (!ecs.matchField([]const u8, self.type, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    type_asc,
    type_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .type_asc => std.mem.order(u8, a.type, b.type),
        .type_desc => std.mem.order(u8, b.type, a.type),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.model, f, sort);
  }
};


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should set mesh" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

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
  }

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

test "Query should filter" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = init(world.entity("test1"), .{.type = "cube"});
  _ = init(world.entity("test2"), .{.type = "sphere"});

  // When
  const result = Query.exec(&world, .{ .type = .{ .eq = "cube" }}, &.{.type_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
