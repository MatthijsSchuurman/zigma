const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = rl.Vector3;

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.position.getPtr(entity.id)) |existing| {
    existing.* = Component{.x = x, .y = y, .z = z};
    return entity;
  }

  const new = Component{.x = x, .y = y, .z = z };
  entity.world.components.position.put(entity.id, new) catch @panic("Failed to store position");

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
    return world.query(Query, &world.components.position, f, &.{});
  }
};


// Testing
const tst = std.testing;

test "Component should set position" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(Component{.x = 1, .y = 2, .z = 3}, position)
  else
    return error.TestExpectedPosition;
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
