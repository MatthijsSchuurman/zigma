const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.scale.getPtr(entity.id)) |existing| {
    existing.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const new = .{.x = x, .y = y, .z = z };

  entity.world.components.scale.put(entity.id, new) catch @panic("Failed to store scale");
  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    x: ?ecs.FieldFilter(f32) = null,
    y: ?ecs.FieldFilter(f32) = null,
    z: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.x) |cond|
      if (!ecs.matchField(f32, self.x, cond))
        return false;

    if (f.y) |cond|
      if (!ecs.matchField(f32, self.y, cond))
        return false;

    if (f.z) |cond|
      if (!ecs.matchField(f32, self.z, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.scale, f, &.{});
  }
};


// Testing
const tst = std.testing;

test "Component should set scale" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(Component{.x = 1, .y = 2, .z = 3}, scale)
  else
    return error.TestExpectedScale;
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = set(world.entity("test1"), 1, 2, 3);
  _ = set(world.entity("test2"), 4, 5, 6);

  // When
  const result = Query.exec(&world, .{ .x = .{ .eq = 1 } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
