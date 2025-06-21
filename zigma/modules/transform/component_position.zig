const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const Component = rl.Vector3;

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

  pub fn exec(world: *ecs.World, f: Filter) []ent.EntityID {
    return world.query(Query, &world.components.position, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntityPosition = @import("entity_position.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = EntityPosition.set(world.entity("test1"), 1, 2, 3);
  _ = EntityPosition.set(world.entity("test2"), 4, 5, 6);

  // When
  const result = Query.exec(&world, .{ .x = .{ .eq = 1 } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
