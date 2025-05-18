const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  material: rl.Material,
  shader_id: ecs.EntityID = 0,
};

const Material = struct {
  shader: []const u8 = "",
};

pub fn init(entity: ecs.Entity, params: Material) ecs.Entity {
  if (entity.world.components.material.getPtr(entity.id)) |_|
    return entity;

  var new = Component{
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

  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    shader_id: ?ecs.FieldFilter(ecs.EntityID) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.shader_id) |cond|
      if (!ecs.matchField(ecs.EntityID, self.shader_id, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.material, f, &.{});
  }
};


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

  if (world.components.material.get(entity.id)) |material| {
    try tst.expectEqual(0, material.shader_id);
    try tst.expectEqual(3, material.material.shader.id);
    try tst.expectEqual(1, material.material.maps[0].texture.id);
    try tst.expectEqual(0, material.material.maps[1].texture.id);
  }
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const shader1 = world.entity("test shader 1").shader(.{});
  _ = world.entity("test shader 2").shader(.{});

  const entity1 = init(world.entity("test1"), .{.shader = "test shader 1"});
  _ = init(world.entity("test2"), .{.shader = "test shader 2"});

  // When
  const result = Query.exec(&world, .{ .shader_id = .{ .eq = shader1.id }});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
