const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  type: []const u8,
  shader: rl.Shader,

  pub fn deinit(self: *Component) void{
    rl.UnloadShader(self.shader);
  }
};

const Shader = struct {
  type: []const u8 = "lighting",
};

pub fn init(entity: ecs.Entity, params: Shader) ecs.Entity {
  if (entity.world.components.shader.getPtr(entity.id)) |_|
    return entity;

  const new = Component{
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
    return world.query(Query, &world.components.shader, f, sort);
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

  if (world.components.shader.get(entity.id)) |shader| {
    try tst.expectEqual("lighting", shader.type);
  }

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = init(world.entity("test1"), .{.type = "lighting"});
  _ = init(world.entity("test2"), .{.type = "test"});

  // When
  const result = Query.exec(&world, .{ .type = .{ .eq = "lighting" }}, &.{.type_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
