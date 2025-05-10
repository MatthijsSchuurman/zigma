const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub fn set(entity: ecs.Entity, r: u8, g: u8, b: u8, a: u8) ecs.Entity {
  if (entity.world.components.color.getPtr(entity.id)) |existing| {
    existing.* = .{.r = r, .g = g, .b = b, .a = a };
    return entity;
  }

  const new = .{.r = r, .g = g, .b = b, .a = a };

  entity.world.components.color.put(entity.id, new) catch @panic("Failed to store color");
  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    r: ?ecs.FieldFilter(u8) = null,
    g: ?ecs.FieldFilter(u8) = null,
    b: ?ecs.FieldFilter(u8) = null,
    a: ?ecs.FieldFilter(u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.r) |cond|
      if (!ecs.matchField(u8, self.r, cond))
        return false;

    if (f.g) |cond|
      if (!ecs.matchField(u8, self.g, cond))
        return false;

    if (f.b) |cond|
      if (!ecs.matchField(u8, self.b, cond))
        return false;

    if (f.a) |cond|
      if (!ecs.matchField(u8, self.a, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.color, f, &.{});
  }
};


// Testing
const tst = std.testing;

test "Component should set color" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3, 4);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(Component{.r = 1, .g = 2, .b = 3, .a = 4}, color)
  else
    return error.TestExpected;
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = set(world.entity("test1"), 1, 2, 3, 4);
  _ = set(world.entity("test2"), 5, 6, 7, 8);

  // When
  const result = Query.exec(&world, .{ .r = .{ .eq = 1 } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(result.len, 1);
  try tst.expectEqual(result[0], entity1.id);
}
