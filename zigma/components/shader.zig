const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  lighting: rl.Shader,
  lit: bool,
  blend: bool,
  depth: bool,

  pub fn deinit(self: *Component) void{
    rl.UnloadShader(self.lighting);
  }
};

const Shader = struct {
  lit: bool = true,
  blend: bool = false,
  depth: bool = true,
};

pub fn init(entity: ecs.Entity, params: Shader) ecs.Entity {
  if (entity.world.components.shader.getPtr(entity.id)) |_|
    return entity;

  const new = .{
    .lighting = rl.LoadShader("zigma/shaders/lighting.vs", "zigma/shaders/lighting.fs"),
    .lit = params.lit,
    .blend = params.blend,
    .depth = params.depth,
  };
  entity.world.components.shader.put(entity.id, new) catch @panic("Failed to store shader");

  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    lit: ?ecs.FieldFilter(bool) = null,
    blend: ?ecs.FieldFilter(bool) = null,
    depth: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.lit) |cond|
      if (!ecs.matchField(bool, self.lit, cond))
        return false;
    if (f.blend) |cond|
      if (!ecs.matchField(bool, self.blend, cond))
        return false;
    if (f.depth) |cond|
      if (!ecs.matchField(bool, self.depth, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.shader, f, &.{});
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

  if (world.components.shader.get(entity.id)) |shader| {
    try tst.expectEqual(true, shader.lit);
    try tst.expectEqual(false, shader.blend);
    try tst.expectEqual(true, shader.depth);
  }
}

test "Query should filter" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = init(world.entity("test1"), .{.lit = false});
  _ = init(world.entity("test2"), .{.lit = true});

  // When
  const result = Query.exec(&world, .{ .lit = .{ .eq = false }});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
