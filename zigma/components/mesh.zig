const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const Component = struct {
  name: []const u8,
  mesh: rl.Mesh,
};

pub fn set(entity: ecs.Entity, name: []const u8) ecs.Entity {
  if (entity.world.components.mesh.getPtr(entity.id)) |existing| {
    rl.UnloadMesh(existing.mesh);

    existing.* = .{
      .name = name,
      .mesh = loadMesh(name),
    };
    return entity;
  }

  const new = .{
    .name = name,
    .mesh = loadMesh(name),
  };
  entity.world.components.mesh.put(entity.id, new) catch @panic("Failed to store mesh");

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

  return entity;
}

fn loadMesh(name: []const u8) rl.Mesh {
  if (std.mem.eql(u8, name, "cube")) return rl.GenMeshCube(1, 1, 1);
  if (std.mem.eql(u8, name, "sphere")) return rl.GenMeshSphere(1, 16, 16);
  if (std.mem.eql(u8, name, "cylinder")) return rl.GenMeshCylinder(1, 1, 16);
  if (std.mem.eql(u8, name, "torus")) return rl.GenMeshTorus(1, 1, 16, 16);
  if (std.mem.eql(u8, name, "plane")) return rl.GenMeshPlane(1, 1, 1, 1);

  @panic("LoadMeshFromFile not yet implemented");
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    name: ?ecs.FieldFilter([]const u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.name) |cond|
      if (!ecs.matchField([]const u8, self.name, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    name_asc,
    name_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .name_asc => std.mem.order(u8, a.name, b.name),
        .name_desc => std.mem.order(u8, b.name, a.name),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.mesh, f, sort);
  }
};


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "Component should set mesh" {
  // Given
  zigma.init(.{.title = "test", .width = 320, .height = 200 });
  defer zigma.deinit();

  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, "cube");

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.mesh.get(entity.id)) |mesh| {
    if (!std.mem.eql(u8, mesh.name, "cube"))
      return error.TestExpectedName;
    if (mesh.mesh.vertexCount != 24)
      return error.TestExpectedVertexCount;
  } else
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

test "Query should filter" {
  // Given
  zigma.init(.{.title = "test", .width = 320, .height = 200 });
  defer zigma.deinit();

  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = set(world.entity("test1"), "cube");
  _ = set(world.entity("test2"), "sphere");

  // When
  const result = Query.exec(&world, .{ .name = .{ .eq = "cube" }}, &.{.name_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
