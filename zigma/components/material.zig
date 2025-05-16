const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const Component = struct {
  material: rl.Material,
  shader_id: ecs.EntityID,

  metalness: f32,
  roughness: f32,

  alpha_blend: bool,
  double_sided: bool,
};

const Material = struct {
  shader: []const u8 = "",

  metalness: f32 = 0.0,
  roughness: f32 = 1.0,

  alpha_blend: bool = false,
  double_sided: bool = false,
};

pub fn init(entity: ecs.Entity, params: Material) ecs.Entity {
  if (entity.world.components.material.getPtr(entity.id)) |_|
    return entity;

  var shader: ecs.Entity = undefined;
  if (params.shader.len == 0) {
    shader = entity.world.entity("shader"); // Use default shader
  } else {
    shader = entity.world.entity(params.shader); // May not exists yet
  }

  const new = .{
    .material = rl.LoadMaterialDefault(),
    .shader_id = shader.id,

    .metalness = params.metalness,
    .roughness = params.roughness,

    .alpha_blend = params.alpha_blend,
    .double_sided = params.double_sided,
  };
  entity.world.components.material.put(entity.id, new) catch @panic("Failed to store material");

  _ = entity
  .color(255, 255, 255, 255);

  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    shader_id: ?ecs.FieldFilter(ecs.EntityID) = null,

    metalness: ?ecs.FieldFilter(f32) = null,
    roughness: ?ecs.FieldFilter(f32) = null,

    alpha_blend: ?ecs.FieldFilter(bool) = null,
    double_sided: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.shader_id) |cond|
      if (!ecs.matchField(ecs.EntityID, self.shader_id, cond))
        return false;

    if (f.metalness) |cond|
      if (!ecs.matchField(f32, self.metalness, cond))
        return false;
    if (f.roughness) |cond|
      if (!ecs.matchField(f32, self.roughness, cond))
        return false;

    if (f.alpha_blend) |cond|
      if (!ecs.matchField(bool, self.alpha_blend, cond))
        return false;
    if (f.double_sided) |cond|
      if (!ecs.matchField(bool, self.double_sided, cond))
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
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");

  // When
  const result = init(entity, .{});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.material.get(entity.id)) |material| {
    try tst.expectEqual(2, material.shader_id);
    try tst.expectEqual(0.0, material.metalness);
    try tst.expectEqual(1.0, material.roughness);
    try tst.expectEqual(false, material.alpha_blend);
    try tst.expectEqual(false, material.double_sided);
    try tst.expectEqual(1, material.material.shader.id);
    try tst.expectEqual(0, material.material.maps[0].texture.id);
    try tst.expectEqual(0, material.material.maps[1].texture.id);
  }

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

  const entity1 = init(world.entity("test1"), .{.metalness = 1});
  _ = init(world.entity("test2"), .{.metalness = 0});

  // When
  const result = Query.exec(&world, .{ .metalness = .{ .eq = 1 }});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
